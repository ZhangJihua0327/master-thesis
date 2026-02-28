# 用例图

```mermaid
flowchart LR
    direction LR
    
    User["用户 (User)"]
    DBA["数据库管理员 (DBA)"]
    
    subgraph TxnControl["事务控制"]
        direction TB
        UC_Begin["开启事务 (Begin)"]
        UC_Isolation["选择隔离级别"]
        UC_Commit["提交 (Commit)"]
        UC_Abort["中止 (Abort)"]
    end
    
    subgraph DataOps["数据操作"]
        direction TB
        UC_Read["读取 (Read)"]
        UC_Write["写入 (Write)"]
        UC_Delete["删除 (Delete)"]
    end
    
    subgraph Config["配置设置"]
        direction TB
        UC_ConnDuration["连接持续时间"]
        UC_LBStrategy["负载均衡策略"]
        UC_TxnTimeout["最长事务时间"]
        UC_RetryPolicy["重试策略"]
    end
    
    subgraph System["系统支撑"]
        direction TB
        UC_Validate["校验事务状态"]
        UC_Status["查看集群状态"]
    end

    %% 用户连接事务控制、数据操作、系统支撑
    User --> TxnControl
    User --> DataOps
    User --> System

    %% 数据库管理员连接配置设置
    DBA --> Config

    %% 事务内部逻辑
    UC_Isolation -.-> UC_Begin
    UC_Begin ~~~ UC_Commit
    UC_Begin ~~~ UC_Abort
    
    %% 数据操作依赖校验
    UC_Read -.-> UC_Validate
    UC_Write -.-> UC_Validate
    UC_Delete -.-> UC_Validate
    
    %% 提交/中止也依赖校验
    UC_Commit -.-> UC_Validate
    UC_Abort -.-> UC_Validate
    
    %% 配置项与管理员关联
    UC_ConnDuration -.-> DBA
    UC_LBStrategy -.-> DBA
    UC_TxnTimeout -.-> DBA
    UC_RetryPolicy -.-> DBA

    %% 样式定义
    style User fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    style DBA fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style UC_Isolation fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px,stroke-dasharray:5 5
    style UC_Validate fill:#fff3e0,stroke:#e65100,stroke-width:2px,stroke-dasharray:5 5
    style UC_ConnDuration fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style UC_LBStrategy fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style UC_TxnTimeout fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style UC_RetryPolicy fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style TxnControl fill:#f5f5f5,stroke:#9e9e9e,stroke-width:1px
    style DataOps fill:#f5f5f5,stroke:#9e9e9e,stroke-width:1px
    style Config fill:#f5f5f5,stroke:#9e9e9e,stroke-width:1px
    style System fill:#f5f5f5,stroke:#9e9e9e,stroke-width:1px
```

# 总体架构图

```mermaid
flowchart TB
    %% 角色层
    subgraph Roles["角色层"]
        User["用户"]
        DBA["数据库管理员"]
    end

    %% 客户端层
    subgraph ClientLayer["客户端层"]
        Console["Console 客户端"]
        LB["负载均衡模块"]
        MetaCache["元数据缓存"]
        ConnPool["连接池管理"]
    end

    %% 配置层
    subgraph ConfigLayer["配置层"]
        Config["配置服务器"]
        MetaDB[("元数据数据库")]
    end

    %% 路由层
    subgraph RouterLayer["路由层"]
        Router1["Router 节点 1"]
        Router2["Router 节点 2"]
    end

    %% 分片层
    subgraph ShardLayer["分片层"]
        Shard1["Shard 节点 1"]
        Shard2["Shard 节点 2"]
        Shard3["Shard 节点 3"]
        Shard4["Shard 节点 4"]
    end

    %% 角色到客户端连接
    User --> Console
    DBA --> Console

    %% 客户端内部模块
    Console --- LB
    Console --- MetaCache
    Console --- ConnPool

    %% 客户端到 Config Server (长连接)
    ConnPool ==>|长连接 | Config
    Config --- MetaDB

    %% 客户端到 Router (负载均衡)
    LB --> Router1
    LB --> Router2

    %% Router 到 Shard (长连接 - 全连接表示任意路由可访问任意分片)
    Router1 ==>|长连接 | Shard1
    Router1 ==>|长连接 | Shard2
    Router1 ==>|长连接 | Shard3
    Router1 ==>|长连接 | Shard4
    Router2 ==>|长连接 | Shard1
    Router2 ==>|长连接 | Shard2
    Router2 ==>|长连接 | Shard3
    Router2 ==>|长连接 | Shard4

    %% 样式定义
    style Roles fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    style ClientLayer fill:#e8f5e9,stroke:#2e7d32,stroke-width:2px
    style ConfigLayer fill:#fff3e0,stroke:#e65100,stroke-width:2px
    style RouterLayer fill:#f3e5f5,stroke:#7b1fa2,stroke-width:2px
    style ShardLayer fill:#fce4ec,stroke:#c2185b,stroke-width:2px
    
    style User fill:#ffffff,stroke:#333,stroke-width:1px
    style DBA fill:#ffffff,stroke:#333,stroke-width:1px
    style Console fill:#ffffff,stroke:#333,stroke-width:1px
    style Config fill:#ffffff,stroke:#333,stroke-width:1px
    style Router1 fill:#ffffff,stroke:#333,stroke-width:1px
    style Router2 fill:#ffffff,stroke:#333,stroke-width:1px
    style Shard1 fill:#ffffff,stroke:#333,stroke-width:1px
    style Shard2 fill:#ffffff,stroke:#333,stroke-width:1px
    style Shard3 fill:#ffffff,stroke:#333,stroke-width:1px
    style Shard4 fill:#ffffff,stroke:#333,stroke-width:1px
```



# 1. 组件交互图：事务初始化时的状态分离与通信架构

对应 TODO 1，展示 Router 和 Shard 在 `TxStart` 阶段的职责划分。

```mermaid
sequenceDiagram
    participant Client
    participant Router as 全局协调者 (Router)
    participant Shard as 数据分片 (Shard)
    
    Client->>Router: 发起全局事务
    activate Router
    Router->>Router: 生成全局事务 TxID <br/> 获取全局快照时间戳 (snapshotTime)
    Router->>Shard: TxStart(TxID, isoLevel, snapshotTime)
    activate Shard
    Shard->>Shard: 根据隔离级别计算并同步本地HLC
    Note over Shard: 不立刻创建 TxBuffer<br>采用懒加载(Lazy Load)以节省内存
    Shard-->>Router: 返回本地时钟状态
    deactivate Shard
    Router-->>Client: 事务初始化成功
    deactivate Router
```

#  流程图：TxRead 的多分支判断逻辑

```mermaid
flowchart TD
    Start[发起 TxRead 请求] --> LazyInit[获取或懒加载 TxBuffer]
    LazyInit --> CheckBuffer{检查本地 Write 集合}
    
    CheckBuffer -- 命中 --> CheckDelete{是否已被本事务标记 Deleted?}
    CheckDelete -- 是 --> RetEmpty[返回空字符串及版本 0]
    CheckDelete -- 否 --> RetLocal[返回本地缓冲区的暂存值]
    
    CheckBuffer -- 未命中 --> CheckSER{隔离级别是否为 SER?}
    CheckSER -- 是 --> AcquireLock[请求并获取读共享锁]
    AcquireLock --> StoreGet[调用 MVCCStore.Get 读取历史版本]
    CheckSER -- 否 --> StoreGet
    
    StoreGet --> CheckPending{是否遇到目标键的 Pending 状态?}
    CheckPending -- "是 (且 PrepareTime <= SnapshotTime)" --> BlockWait[抛出 ErrPendingRead 异常]
    CheckPending -- 否 --> RetStore[返回最接近快照时间的安全历史版本]
```

# 时间线时序图：2PC Visibility Hole 与 异常拦截防线

```mermaid
sequenceDiagram
    participant Tx1 as 事务 A (写入方)
    participant Shard as Shard (MVCC Store)
    participant Tx2 as 事务 B (读取方)
    
    Note over Tx1, Shard: 事务 A 进入 2PC Prepare 阶段
    Tx1->>Shard: Prepare()
    Shard->>Shard: 分配 prepareTime (假设 T=10)
    Shard->>Shard: MVCC 写入带 Pending 标记的临时版数据
    Shard-->>Tx1: 预备成功 (返回 VOTE_COMMIT)
    
    Note over Tx2, Shard: Visibility Hole 场景：并发访问
    Tx2->>Shard: TxRead(snapshotTime=11)
    Note over Shard: 快照时间 11 >= prepareTime 10<br/>发现目标受阻于 Pending 标记
    Shard-->>Tx2: 拦截读取并抛出 ErrPendingRead 
    Note right of Tx2: 阻止 TxB 读取到早于 T=10 的旧版本<br/>调用方因此阻塞或重试，防范线性一致性被破坏
    
    Note over Tx1, Shard: 事务 A 进入 2PC Commit 阶段
    Tx1->>Shard: Commit(commitTime=12)
    Shard->>Shard: 执行 ConfirmPending() 去除 Pending 标记
    Shard-->>Tx1: 提交完成 (数据正式可见)
```

# 交互时序图：标准 2PC 与 QuickCommit 性能对比

```mermaid
sequenceDiagram
    participant Client
    participant Router as 全局协调者 (Router)
    participant Shard1 as 参与数据分片 (Shard)
    
    Note over Client, Shard1: 场景 A: 跨分片事务 (标准两阶段提交)
    Client->>Router: 提交跨片事务
    Router->>Shard1: 阶段 1: RPC Prepare(TxID)
    Shard1->>Shard1: 校验、写锁获取、写入 Pending 状态
    Shard1-->>Router: 返回 VOTE_COMMIT
    Router->>Shard1: 阶段 2: RPC Commit(TxID, commitTime)
    Shard1->>Shard1: ConfirmPending 固化数据、清理锁和缓存
    Shard1-->>Router: OK
    Note left of Router: 至少需要 2 轮以上的 RPC 协商延迟
    
    Note over Client, Shard1: =========================================
    
    Note over Client, Shard1: 场景 B: 单分片事务 (QuickCommit 提交加速)
    Client->>Router: 提交单片事务
    Router->>Shard1: RPC QuickCommit(TxID, isoLevel)
    Note over Shard1: Shard 内部直接完成闭环:<br>1. CAS 乐观/悲观版本校验冲突<br>2. 越过 Pending 直接写 MVCC<br>3. 原地释放锁和本地缓存记录
    Shard1-->>Router: OK (返回本地决议时间)
    Note left of Router: 无需 2PC 协商，仅 1 次 RPC 即完成提交，极大降低延迟
```

