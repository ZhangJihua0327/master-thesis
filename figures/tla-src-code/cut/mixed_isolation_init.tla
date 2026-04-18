Init ==
  LET Sessions == {Workload[t].session: t \in TxnIds}
  IN /\ client_dep = [s \in Sessions |-> 0]
     /\ client_last_commit = [s \in Sessions |-> 0]
     /\ router_ct = 0
     /\ shard_ct = 0
     /\ tx_status =
          [t \in AllTxns |-> IF t = InitTx THEN "Committed" ELSE "Inactive"]
     /\ tx_snapshot = [t \in AllTxns |-> 0]
     /\ tx_checkset = [t \in AllTxns |-> {}]
     /\ tx_buffer = [t \in AllTxns |-> [k \in Keys |-> <<>>]]
     /\ tx_commit_time = [t \in AllTxns |-> 0]
     /\ store =
          [k \in Keys |-> { [ val |-> InitVal, cts |-> 0, writer |-> InitTx ] }]
     /\ pc = [t \in TxnIds |-> 1]
     /\ op_seq = [t \in TxnIds |-> <<>>]
