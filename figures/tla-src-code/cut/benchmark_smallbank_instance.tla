Workload == <<
    [
        session |-> "client_1",
        level   |-> "PSI",
        ops     |-> <<[type |-> "R", key |-> "checking"],
                       [type |-> "R", key |-> "savings"],
                       [type |-> "W", key |-> "savings", val |-> 1] >>
    ],
    [
        session |-> "client_2",
        level   |-> "SER",
        ops     |-> <<[type |-> "R", key |-> "checking"],
                       [type |-> "R", key |-> "savings"],
                       [type |-> "W", key |-> "checking", val |-> 2] >>
    ]
>>

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

MI == INSTANCE MixedIsolation WITH
    Keys <- Keys,
    Values <- Values,
    InitVal <- InitVal,
    Workload <- Workload
