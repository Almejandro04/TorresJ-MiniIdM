# Results template

Store evidence in `results/tables/`.

| Experiment | Input | Metric | Evidence |
|---|---|---|---|
| LDAP replication | Add testreplica in ldap1 | propagation_ms | ldap-replication.csv |
| KDC failover | Stop primary KDC | authentication_ms | kdc-failover.csv |
| TLS overhead | Compare LDAP and LDAPS | latency_ms | tls-overhead.csv |
| HA throughput | LDAP requests through frontend | requests_per_second | lb-throughput.csv |
| Node faults | kill, iptables or certificate | recovery_ms | node-failures.csv |

Record date, node names, command, metric value and result for every run.
