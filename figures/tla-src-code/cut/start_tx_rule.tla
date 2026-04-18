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
        shard_ct
     >>
