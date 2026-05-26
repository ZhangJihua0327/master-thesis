------------------------- MODULE CommitTx -------------------------------
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
              /\ UNCHANGED << client_dep, client_last_commit, shard_ct,
                              tx_snapshot, tx_checkset, tx_buffer,
                              tx_commit_time, pc, store, op_seq >>
         ELSE /\ shard_ct' = shard_ct + 1
              /\ tx_commit_time' = [tx_commit_time EXCEPT ![t] = shard_ct']
              /\ tx_status' = [tx_status EXCEPT ![t] = "Committed"]
              /\ store' =
                   [ k \in Keys |->
                       IF tx_buffer[t][k] /= <<>>
                       THEN store[k] \cup
                              { [ val    |-> tx_buffer[t][k][1],
                                  cts    |-> shard_ct',
                                  writer |-> t ] }
                       ELSE store[k] ]
              /\ client_dep' =
                   IF shard_ct' > client_dep[Workload[t].session]
                   THEN [client_dep EXCEPT ![Workload[t].session] = shard_ct']
                   ELSE client_dep
              /\ client_last_commit' =
                   [client_last_commit EXCEPT
                       ![Workload[t].session] = shard_ct']
              /\ UNCHANGED << tx_snapshot, tx_checkset, tx_buffer, pc, op_seq >>
=============================================================================
