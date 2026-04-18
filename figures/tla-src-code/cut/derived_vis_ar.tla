CommittedTxns == {t \in DOMAIN tx_status: tx_status[t] = "Committed"}

Derived_AR ==
  {<<t1, t2>> \in CommittedTxns \X CommittedTxns:
    tx_commit_time[t1] < tx_commit_time[t2]
  }

Derived_VIS ==
  {<<t1, t2>> \in CommittedTxns \X CommittedTxns:
    \/ /\ t2 /= InitTx
       /\ Workload[t2].level \in { "RA", "CC", "PC", "PSI", "SI" }
       /\ tx_commit_time[t1] <= tx_snapshot[t2]
    \/ /\ (t2 = InitTx \/ Workload[t2].level = "SER")
       /\ <<t1, t2>> \in Derived_AR
  }
