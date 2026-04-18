----------------------- MODULE Benchmark_SmallBank -----------------------
EXTENDS Naturals, Sequences

Keys    == {"checking", "savings"}
Values  == {0, 1, 2}
InitVal == 0

\* We define the Workload as a Sequence (Tuple) of Records.
Workload == << \* T1: TransactSavings (PSI)
    [
        session |-> "client_1", 
        level   |-> "PSI", 
        ops     |-> <<[type |-> "R", key |-> "checking"],
                       [type |-> "R", key |-> "savings"],[type |-> "W", key |-> "savings", val |-> 1] >>
    ], \* T2: WriteCheck (SER)
    [
        session |-> "client_2", 
        level   |-> "SER", 
        ops     |-> <<[type |-> "R", key |-> "checking"], 
                       [type |-> "R", key |-> "savings"],[type |-> "W", key |-> "checking", val |-> 2] >>
    ]
>>

VARIABLES
    client_dep,         
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

Spec == MI!Spec
OperationalSafety == MI!OperationalSafety

=============================================================================