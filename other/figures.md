sequenceDiagram
    autonumber
    participant Client as 控制台客户端 (Client)
    participant Config as 配置服务器 (Config Server)
    participant Router1 as 路由节点 A (Router)
    participant Router2 as 路由节点 B (Router)
    participant Shard1 as 分片节点 1 (Shard)
    participant Shard2 as 分片节点 2 (Shard)

```mermaid
sequenceDiagram
    autonumber
    participant Client as 控制台客户端 (Client)
    participant Config as 配置服务器 (Config Server)
    participant Router1 as 路由节点 A (Router)
    participant Router2 as 路由节点 B (Router)
    participant Shard1 as 分片节点 1 (Shard)
    participant Shard2 as 分片节点 2 (Shard)

    Note over Client, Config: 阶段 1: 初始化与路由发现 (长连接)
    Client->>Config: 建立长连接 (Register/Heartbeat)
    Config-->>Client: 返回可用 Router 列表 (IP/Port/Status)
    Client->>Client: 执行负载均衡策略 (LB Policy)
    Client->>Router1: 选择并建立会话连接

    Note over Router1, Shard2: 阶段 2: 路由与分片维护 (长连接)
    Router1->>Shard1: 维持长连接 (获取分片配置/心跳)
    Router1->>Shard2: 维持长连接 (获取分片配置/心跳)

    Note over Client, Shard2: 阶段 3: 分布式事务执行 (混合隔离级别验证)
    Client->>Router1: Begin Transaction (Isolation Level: Hybrid)
    activate Router1
    Router1->>Router1: 创建事务上下文 (Txn Context)<br/>生成全局事务 ID
    
    rect rgb(255, 250, 240)
        Note right of Client: 操作 1: 单分片写入 (Key_A -> Shard1)
        Client->>Router1: Write(Key_A, Value)
        Router1->>Router1: 解析 Key 路由规则
        Router1->>Shard1: 转发写请求 (TxnID, IsolationFlags)
        activate Shard1
        Shard1->>Shard1: 隔离级别检查 (Lock/MVCC)
        Shard1->>Shard1: 执行本地写入 (WAL)
        Shard1-->>Router1: 返回执行结果 (Prepared)
        deactivate Shard1
    end

    rect rgb(240, 248, 255)
        Note right of Client: 操作 2: 跨分片写入 (Key_B -> Shard2)
        Client->>Router1: Write(Key_B, Value)
        Router1->>Router1: 更新事务状态 (Multi-Shard)
        Router1->>Shard2: 转发写请求 (TxnID, IsolationFlags)
        activate Shard2
        Shard2->>Shard2: 隔离级别检查 (Lock/MVCC)
        Shard2->>Shard2: 执行本地写入 (WAL)
        Shard2-->>Router1: 返回执行结果 (Prepared)
        deactivate Shard2
    end

    Note over Client, Shard2: 阶段 4: 事务提交 (两阶段提交简化版)
    Client->>Router1: Commit Transaction
    Router1->>Router1: 协调提交状态
    Router1->>Shard1: Commit (TxnID)
    Shard1-->>Router1: Ack Commit
    Router1->>Shard2: Commit (TxnID)
    Shard2-->>Router1: Ack Commit
    
    Router1->>Router1: 清除事务上下文 (Free Memory)
    Router1-->>Client: 返回提交成功
    deactivate Router1

    Note over Client, Config: 阶段 5: 连接保活
    Client->>Config: 心跳 (Keep-Alive)
    Config-->>Client: 更新 Router 状态 (如有变更)
```