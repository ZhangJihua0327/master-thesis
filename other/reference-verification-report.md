# 参考文献真实性核验报告

核验对象：`zhangjihua-master-thesis.bib`

核验时间：2026-05-26

## 一、核验结论

本次共检查参考文献 65 条。总体来看，大部分英文系统、数据库、形式化方法相关文献均可通过 DOI、DBLP、ACM、VLDB、IEEE、Springer、Dagstuhl 或期刊官网核验，属于真实可检索文献。

但当前 `.bib` 中仍存在若干问题：部分条目的 DOI 与题名/作者不匹配，部分条目 DOI 写错，部分条目重复收录，另有少数条目题名或作者信息疑似录入错误，需要进一步确认或替换。

说明：Google Scholar 不适合作为自动化逐条核验接口。本报告以“是否能在可靠学术索引或出版方页面中检索到”为判断依据，包括 Crossref、DBLP、ACM Digital Library、VLDB、Springer、Dagstuhl、软件学报官网等来源。

## 二、必须修改的问题

### 1. `sql-for-Ai`

当前条目写为：

- 题名：`SQL for AI: A New Database Paradigm in the Agentic AI Era`
- 作者：`Li, Feifei and Ding, Yuanyuan and Chen, Yanfeng and Zhu, Jianhua and Zhang, Yu`
- DOI：`10.11991/cccf.202511013`

核验结果：该 DOI 实际对应的文章是《迎接人工智能挑战：构建下一代数据库系统》，英文题名为 `Meeting the Artificial Intelligence Challenge: Building the Next-Generation DBMS`，作者为陈志标、欧伟杰、孟凡彬、李伟超、王思涵。

建议：不要继续使用当前 `sql-for-Ai` 条目。要么删除该条，要么按真实 DOI 对应文章重建条目。

核验来源：

- https://cccf.hrbeu.edu.cn/article/doi/10.11991/cccf.202511013
- https://cccf.hrbeu.edu.cn/en/article/doi/10.11991/cccf.202511013

### 2. `Perkins2011`

当前条目写为：

- 作者：`Perkins, Eric and Wong, Prudence W. H. and Gupta, Indranil`
- 题名：`Performance Analysis of Distributed Transactions in Partitioned Database Systems`
- 会议：`2011 IEEE International Symposium on Modeling, Analysis and Simulation of Computer and Telecommunication Systems`
- 页码：`250--259`

核验结果：按题名、作者、会议、页码组合进行检索，未找到可靠的出版方页面、DBLP、Crossref 或 IEEE 记录。该条疑似题名、作者、会议或页码录入错误。

建议：暂时不要使用该条作为正式参考文献。若确实需要引用分区数据库分布式事务性能分析，应重新从论文 PDF、IEEE 页面或课程资料中确认完整文献信息。

### 3. `kamsky2019adapting`

当前 DOI 写为：

- `10.14778/3352262.3352278`

核验结果：论文真实存在，但 DOI 写错。正确 DOI 为：

- `10.14778/3352063.3352140`

正确文献信息：

- Asya Kamsky. `Adapting TPC-C Benchmark to Measure Performance of Multi-Document Transactions in MongoDB`. PVLDB, 12(12): 2254-2262, 2019.

核验来源：

- https://www.vldb.org/pvldb/vol12/p2254-kamsky.pdf
- https://dblp.org/rec/journals/pvldb/Kamsky19

### 4. `diab2013oltpbench`

当前条目写为：

- 作者：`Diab, Ahmed and Pavlo, Andrew and Curino, Carlo and Zhang, Sheng`
- 题名：`OLTPBench: An extensible testbed for benchmarking relational databases`

核验结果：论文真实存在，但作者信息不正确，且缺少 DOI。正确作者应为：

- Djellel Eddine Difallah
- Andrew Pavlo
- Carlo Curino
- Philippe Cudré-Mauroux

正确 DOI 为：

- `10.14778/2732240.2732246`

核验来源：

- https://dblp.org/rec/journals/pvldb/DifallahPCC13
- https://www.vldb.org/2014/program/http%3A/www.vldb.org/pvldb/vol7/p277-difallah.pdf

## 三、建议合并或删除的重复条目

### 1. `Schultz2015` 与 `Schultz2025`

两者均为：

- `Design and Modular Verification of Distributed Transactions in MongoDB`
- DOI：`10.14778/3750601.3750626`
- 年份：2025

建议：保留 `Schultz2025`，删除 `Schultz2015`，避免同一篇文献在参考文献表中重复出现。

核验来源：

- https://dblp.org/rec/journals/pvldb/SchultzD25
- https://www.vldb.org/pvldb/vol18/p5045-schultz.pdf

### 2. `spanner` 与 `corbett2013spanner`

两者均为 ACM TOCS 版本：

- `Spanner: Google’s Globally Distributed Database`
- DOI：`10.1145/2491245`

建议：保留一个即可。若正文中引用较多，优先保留当前使用较稳定的 key，删除另一个重复条目。

### 3. `Huang2020` 与 `TiDB`

两者均指向：

- `TiDB: a Raft-based HTAP database`

建议：保留带 DOI 的 `TiDB`，删除无 DOI 的 `Huang2020`。

### 4. `tso1` 与 `peng2010large`

两者均指向：

- `Large-scale incremental processing using distributed transactions and notifications`

建议：保留一个即可。建议保留信息更完整、带 URL 的 `peng2010large`。

### 5. `newcombe2014use` 与 `newcombe2015amazon`

两者内容高度相关：

- `Use of Formal Methods at Amazon Web Services`
- `How Amazon web services uses formal methods`

建议：正式论文中优先引用 Communications of the ACM 2015 版本，即 `newcombe2015amazon`，因为其有 DOI：`10.1145/2699417`。

核验来源：

- https://dblp.org/rec/journals/cacm/NewcombeRZMBD15
- https://www.amazon.science/publications/how-amazon-web-services-uses-formal-methods

## 四、真实但 cite key 年份容易误导的条目

以下条目真实存在，但 key 中年份与实际出版年份不一致，建议改名以降低维护风险：

| 当前 key | 实际年份 | 题名 |
| --- | --- | --- |
| `Agrawal2016` | 2011 | `Big Data and Cloud Computing: Current State and Future Opportunities` |
| `Bailis2014` | 2012 | `Probabilistically Bounded Staleness for Practical Partial Quorums` |
| `Pavlo2011` | 2016 | `What's Really New with NewSQL?` |
| `Schultz2015` | 2025 | `Design and Modular Verification of Distributed Transactions in MongoDB` |

说明：这些问题一般不会导致编译错误，也不一定影响参考文献格式，但会误导后续维护和人工审查。

## 五、已核验为真实的代表性文献

以下条目已通过 DOI、DBLP、出版方页面或期刊页面核验，未发现真实性问题：

- `berenson1995critique`：`A critique of ANSI SQL isolation levels`，DOI `10.1145/223784.223785`
- `DeCandia2007`：`Dynamo: Amazon's highly available key-value store`，DOI `10.1145/1294261.1294281`
- `Gilbert2002`：`Brewer's conjecture and the feasibility of consistent, available, partition-tolerant web services`，DOI `10.1145/564585.564601`
- `Haerder1983`：`Principles of transaction-oriented database recovery`，DOI `10.1145/289.291`
- `Lamport1994`：`The temporal logic of actions`，DOI `10.1145/177492.177726`
- `taft2020cockroachdb`：`CockroachDB: The Resilient Geo-Distributed SQL Database`，DOI `10.1145/3318464.3386134`
- `cerone2015framework`：`A Framework for Transactional Consistency Models with Atomic Visibility`，DOI `10.4230/LIPIcs.CONCUR.2015.58`
- `burckhardt2015global`：`Global Sequence Protocol: A Robust Abstraction for Replicated Shared State`，DOI `10.4230/LIPIcs.ECOOP.2015.568`
- `CuiBin2019DataManagement`：`新型数据管理系统研究进展与趋势`，DOI `10.13328/j.cnki.jos.005646`
- `Shui2023Consistency`：`分布式数据库多级一致性统一建模理论研究`，DOI `10.13328/j.cnki.jos.006460`
- `WangJi2019FormalMethods`：`形式化方法概貌`，DOI `10.13328/j.cnki.jos.005652`

## 六、建议的处理顺序

1. 先删除或修正 `sql-for-Ai`，这是当前最严重的“题名/作者/DOI 不匹配”问题。
2. 再确认 `Perkins2011`，若找不到可靠来源，建议删除或替换。
3. 修正 `kamsky2019adapting` 和 `diab2013oltpbench` 的 DOI、作者等字段。
4. 删除重复条目，避免参考文献表重复。
5. 最后统一 cite key 年份，提升 `.bib` 可维护性。

## 七、参考核验来源

- Crossref API：https://api.crossref.org/
- DBLP：https://dblp.org/
- ACM Digital Library：https://dl.acm.org/
- VLDB：https://www.vldb.org/
- Dagstuhl LIPIcs：https://drops.dagstuhl.de/
- 软件学报：https://www.jos.org.cn/
- CCF《计算》：https://cccf.hrbeu.edu.cn/
- Amazon Science：https://www.amazon.science/
