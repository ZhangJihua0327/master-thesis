------------------------- MODULE ExecuteOp -------------------------------
MaxVersion(versions, max_cts) ==
  LET valid == { v \in versions: v.cts <= max_cts }
  IN  CHOOSE v \in valid: \A v2 \in valid: v.cts >= v2.cts

ExecuteOp(t) ==
  /\ tx_status[t] = "Active"
  /\ pc[t] <= Len(Workload[t].ops)
  /\ LET op == Workload[t].ops[pc[t]]
     IN IF op.type = "R"
         THEN LET is_in_buffer == tx_buffer[t][op.key] /= <<>>
                  latest_ver   == MaxVersion(store[op.key], tx_snapshot[t])
                  read_val     == IF is_in_buffer
                                  THEN tx_buffer[t][op.key][1]
                                  ELSE latest_ver.val
           IN /\ op_seq' = [op_seq EXCEPT ![t] =
                  Append(@, [ type |-> "R", key |-> op.key, val |-> read_val ])]
              /\ client_dep' =
                   IF ~is_in_buffer /\
                       latest_ver.cts > client_dep[Workload[t].session]
                   THEN [client_dep EXCEPT
                           ![Workload[t].session] = latest_ver.cts]
                   ELSE client_dep
              /\ tx_checkset' =
                   IF Workload[t].level = "SER"
                   THEN [tx_checkset EXCEPT ![t] = tx_checkset[t] \cup { op.key }]
                   ELSE tx_checkset
              /\ pc' = [pc EXCEPT ![t] = pc[t] + 1]
              /\ UNCHANGED << client_last_commit, shard_ct, tx_status,
                              tx_snapshot, tx_buffer, tx_commit_time, store >>
         ELSE \* op.type = "W"
              /\ tx_buffer' = [tx_buffer EXCEPT ![t][op.key] = << op.val >>]
              /\ tx_checkset' =
                   IF Workload[t].level \in { "PSI", "SI", "SER" }
                   THEN [tx_checkset EXCEPT ![t] = tx_checkset[t] \cup { op.key }]
                   ELSE tx_checkset
              /\ op_seq' = [op_seq EXCEPT ![t] =
                  Append(@, [ type |-> "W", key |-> op.key, val |-> op.val ])]
              /\ pc' = [pc EXCEPT ![t] = pc[t] + 1]
              /\ UNCHANGED << client_dep, client_last_commit, shard_ct,
                              tx_status, tx_snapshot, tx_commit_time, store >>
=============================================================================
