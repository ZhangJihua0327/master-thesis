--------------------------- MODULE MixedIsolation ---------------------------
EXTENDS Naturals, Sequences, FiniteSets

CONSTANTS Keys, Values, InitVal, Workload

TxnIds == DOMAIN Workload
InitTx == 0
AllTxns == TxnIds \cup { InitTx }

IsoLevels == { "RA", "CC", "PC", "PSI", "SI", "SER" }

VARIABLES client_dep,
          client_last_commit,
          router_ct,
          shard_ct,
          tx_status,
          tx_snapshot,
          tx_checkset,
          tx_buffer,
          tx_commit_time,
          pc,
          store,
          op_seq

all_vars ==
  << client_dep,
     client_last_commit,
     router_ct,
     shard_ct,
     tx_status,
     tx_snapshot,
     tx_checkset,
     tx_buffer,
     tx_commit_time,
     pc,
     store,
     op_seq
  >>

-----------------------------------------------------------------------------
\* 1. OPERATIONAL PROTOCOL
-----------------------------------------------------------------------------

Init ==
  LET Sessions == {Workload[t].session: t \in TxnIds}
  IN /\ client_dep = [s \in Sessions |-> 0]
     /\ client_last_commit = [s \in Sessions |-> 0]
     /\ router_ct = 0
     /\ shard_ct = 0
     /\ tx_status =
          [t \in AllTxns |-> IF t = InitTx THEN "Committed" ELSE "Inactive"
          ]
     /\ tx_snapshot = [t \in AllTxns |-> 0]
     /\ tx_checkset = [t \in AllTxns |-> {}]
     /\ tx_buffer = [t \in AllTxns |-> [k \in Keys |-> <<>>]]
     /\ tx_commit_time = [t \in AllTxns |-> 0]
     /\ store =
          [k \in Keys |-> { [ val |-> InitVal, cts |-> 0, writer |-> InitTx ] }
          ]
     /\ pc = [t \in TxnIds |-> 1]
     /\ op_seq = [t \in TxnIds |-> <<>>]

StartTx(t) ==
  /\ tx_status[t] = "Inactive"
  /\ LET sess == Workload[t].session
         lvl == Workload[t].level
     IN IF lvl \in { "PC", "SI", "SER" }
         THEN /\ tx_snapshot' = [tx_snapshot EXCEPT ![t] = shard_ct]
              /\ UNCHANGED router_ct
         ELSE IF lvl \in { "CC", "PSI" }
           THEN /\ tx_snapshot' = [tx_snapshot EXCEPT ![t] = client_dep[sess]]
                /\ UNCHANGED router_ct
           ELSE \* RA
                /\ tx_snapshot' =
                     [tx_snapshot EXCEPT ![t] = client_last_commit[sess]]
                /\ UNCHANGED router_ct
  /\ tx_status' = [tx_status EXCEPT ![t] = "Active"]
  /\ UNCHANGED << client_dep,
        client_last_commit,
        shard_ct,
        tx_checkset,
        tx_buffer,
        tx_commit_time,
        pc,
        store,
        op_seq
     >>

MaxVersion(versions, max_cts) ==
  LET valid == {v \in versions: v.cts <= max_cts}
  IN CHOOSE v \in valid: \A v2 \in valid: v.cts >= v2.cts

ExecuteOp(t) ==
  /\ tx_status[t] = "Active"
  /\ pc[t] <= Len(Workload[t].ops)
  /\ LET op == Workload[t].ops[pc[t]]
     IN IF op.type = "R"
         THEN LET is_in_buffer == tx_buffer[t][op.key] /= <<>>
                  latest_ver == MaxVersion(store[op.key], tx_snapshot[t])
                  read_val ==
                    IF is_in_buffer
                    THEN tx_buffer[t][op.key][1]
                    ELSE latest_ver.val
           IN /\ op_seq' =
                   [op_seq EXCEPT
                   ![t] =
                   Append(@, [ type |-> "R", key |-> op.key, val |-> read_val ])]
              /\ client_dep' =
                   IF ~is_in_buffer /\
                       latest_ver.cts > client_dep[Workload[t].session]
                   THEN [client_dep EXCEPT
                     ![Workload[t].session] =
                     latest_ver.cts]
                   ELSE client_dep
              /\ tx_checkset' =
                   IF Workload[t].level = "SER"
                   THEN [tx_checkset EXCEPT
                     ![t] =
                     tx_checkset[t] \cup { op.key }]
                   ELSE tx_checkset
              /\ pc' = [pc EXCEPT ![t] = pc[t] + 1]
              /\ UNCHANGED << client_last_commit,
                    router_ct,
                    shard_ct,
                    tx_status,
                    tx_snapshot,
                    tx_buffer,
                    tx_commit_time,
                    store
                 >>
         ELSE \* op.type = "W"
              /\ tx_buffer' = [tx_buffer EXCEPT ![t][op.key] = << op.val >>]
              /\ tx_checkset' =
                   IF Workload[t].level \in { "PSI", "SI", "SER" }
                   THEN [tx_checkset EXCEPT
                     ![t] =
                     tx_checkset[t] \cup { op.key }]
                   ELSE tx_checkset
              /\ op_seq' =
                   [op_seq EXCEPT
                   ![t] =
                   Append(@, [ type |-> "W", key |-> op.key, val |-> op.val ])]
              /\ pc' = [pc EXCEPT ![t] = pc[t] + 1]
              /\ UNCHANGED << client_dep,
                    client_last_commit,
                    router_ct,
                    shard_ct,
                    tx_status,
                    tx_snapshot,
                    tx_commit_time,
                    store
                 >>

CommitTx(t) ==
  /\ tx_status[t] = "Active"
  /\ pc[t] > Len(Workload[t].ops)
  /\ LET IsConcurrent(t_other) ==
           tx_status[t_other] = "Committed" /\
             tx_commit_time[t_other] > tx_snapshot[t]
         HasConflict ==
           \E t_other \in AllTxns:
             /\ IsConcurrent(t_other)
             /\ \E k \in tx_checkset[t]:
                  \E v \in store[k]:
                    v.writer = t_other /\ v.cts = tx_commit_time[t_other]
     IN IF HasConflict
         THEN /\ tx_status' = [tx_status EXCEPT ![t] = "Aborted"]
              /\ UNCHANGED << client_dep,
                    client_last_commit,
                    router_ct,
                    shard_ct,
                    tx_snapshot,
                    tx_checkset,
                    tx_buffer,
                    tx_commit_time,
                    pc,
                    store,
                    op_seq
                 >>
         ELSE /\ shard_ct' = shard_ct + 1
              /\ tx_commit_time' = [tx_commit_time EXCEPT ![t] = shard_ct']
              /\ tx_status' = [tx_status EXCEPT ![t] = "Committed"]
              /\ store' =
                   [k \in Keys |->
                     IF tx_buffer[t][k] /= <<>>
                     THEN store[k] \cup
                         { [ val |-> tx_buffer[t][k][1],
                             cts |-> shard_ct',
                             writer |-> t
                           ]
                         }
                     ELSE store[k]
                   ]
              /\ client_dep' =
                   IF shard_ct' > client_dep[Workload[t].session]
                   THEN [client_dep EXCEPT ![Workload[t].session] = shard_ct']
                   ELSE client_dep
              /\ client_last_commit' =
                   [client_last_commit EXCEPT
                   ![Workload[t].session] =
                   shard_ct']
              /\ UNCHANGED << router_ct,
                    tx_snapshot,
                    tx_checkset,
                    tx_buffer,
                    pc,
                    op_seq
                 >>

Next ==
  ( \E t \in TxnIds: StartTx(t) \/ ExecuteOp(t) \/ CommitTx(t) ) \/
    ( \A t \in TxnIds:
        tx_status[t] \in { "Committed", "Aborted" } /\ UNCHANGED all_vars
    )

-----------------------------------------------------------------------------
\* 2. AXIOMATIC FRAMEWORK & MAPPING
-----------------------------------------------------------------------------
CommittedTxns == {t \in AllTxns: tx_status[t] = "Committed"}

Derived_AR ==
  {<<t1 ,t2>> \in CommittedTxns \X CommittedTxns:
    tx_commit_time[t1] < tx_commit_time[t2]
  }

Derived_VIS ==
  {<<t1 ,t2>> \in CommittedTxns \X CommittedTxns:
    \/ /\ t2 /= InitTx
       /\ Workload[t2].level \in { "RA", "CC", "PC", "PSI", "SI" }
       /\ tx_commit_time[t1] <= tx_snapshot[t2]
    \/ /\ ( t2 = InitTx \/ Workload[t2].level = "SER" )
       /\ << t1, t2 >> \in Derived_AR
  }

OpsOf(t) == DOMAIN op_seq[t]

WriteSet(t) ==
  IF t = InitTx
  THEN Keys
  ELSE {op_seq[t][i].key: i \in {j \in OpsOf(t): op_seq[t][j].type = "W"}}

WriteConflict(t1, t2) == WriteSet(t1) \intersect WriteSet(t2) /= {}

LastWriteIndex(t, x) ==
  IF t = InitTx
  THEN 1
  ELSE LET xw ==
             {i \in OpsOf(t): op_seq[t][i].key = x /\ op_seq[t][i].type = "W"}
    IN IF xw = {} THEN 0 ELSE CHOOSE max_i \in xw: \A i \in xw: max_i >= i

FirstOpIndex(t, x) ==
  IF t = InitTx
  THEN 1
  ELSE LET xo == {i \in OpsOf(t): op_seq[t][i].key = x}
    IN IF xo = {} THEN 0 ELSE CHOOSE min_i \in xo: \A i \in xo: min_i <= i

T_writes(t, x, v) ==
  IF t = InitTx
  THEN v = InitVal
  ELSE LastWriteIndex(t, x) > 0 /\ op_seq[t][LastWriteIndex(t, x)].val = v

T_reads_ext(t, x, v) ==
  t /= InitTx /\ FirstOpIndex(t, x) > 0 /\
      op_seq[t][FirstOpIndex(t, x)].type = "R" /\
    op_seq[t][FirstOpIndex(t, x)].val = v

MaxAR(S, AR_rel) ==
  CHOOSE max_t \in S: \A t \in S \ { max_t }: << t, max_t >> \in AR_rel

IntAxiom(t) ==
  \A i \in OpsOf(t):
    op_seq[t][i].type = "R" =>
      LET prev_ops ==
            {j \in 1 .. ( i - 1 ): op_seq[t][j].key = op_seq[t][i].key}
      IN prev_ops /= {} =>
            LET max_j == CHOOSE j \in prev_ops: \A k \in prev_ops: j >= k
            IN op_seq[t][i].val = op_seq[t][max_j].val

ExtAxiom(t, VIS, AR) ==
  \A x \in Keys,
    v \in Values:
    T_reads_ext(t, x, v) =>
      LET vis_writes ==
            {tp \in CommittedTxns:
              << tp, t >> \in VIS /\ LastWriteIndex(tp, x) > 0
            }
      IN T_writes(MaxAR(vis_writes, AR), x, v)

TransVisAxiom(t, VIS) ==
  \A tp, s \in CommittedTxns:
    ( << tp, s >> \in VIS /\ << s, t >> \in VIS ) => << tp, t >> \in VIS
PrefixAxiom(t, VIS, AR) ==
  \A tp, s \in CommittedTxns:
    ( << tp, s >> \in AR /\ << s, t >> \in VIS ) => << tp, t >> \in VIS
NoConflictAxiom(t, VIS, AR) ==
  \A tp \in CommittedTxns:
    ( WriteConflict(tp, t) /\ << tp, t >> \in AR ) => << tp, t >> \in VIS
TotalVisAxiom(t, VIS, AR) ==
  \A tp \in CommittedTxns: << tp, t >> \in AR => << tp, t >> \in VIS

IsConsistentExecution ==
  \A t \in CommittedTxns \ { InitTx }:
    LET lvl == Workload[t].level
        V == Derived_VIS
        A == Derived_AR
    IN /\ lvl \in IsoLevels => ( IntAxiom(t) /\ ExtAxiom(t, V, A) )
       /\ lvl \in { "CC", "PC", "PSI", "SI", "SER" } => TransVisAxiom(t, V)
       /\ lvl \in { "PC", "SI", "SER" } => PrefixAxiom(t, V, A)
       /\ lvl \in { "PSI", "SI", "SER" } => NoConflictAxiom(t, V, A)
       /\ lvl \in { "SER" } => TotalVisAxiom(t, V, A)

OperationalSafety == IsConsistentExecution
Spec == Init /\ [][Next]_all_vars
=============================================================================