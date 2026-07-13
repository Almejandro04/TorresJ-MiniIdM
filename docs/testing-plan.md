# Testing plan

| Test | Command | Expected result |
|---|---|---|
| LDAP search | `make ldap-search` | User entries are returned |
| LDAPS | `bash tests/ldap/test-ldaps.sh` | CA validation succeeds |
| LDAP replication | `bash tests/ldap/test-replication-delay.sh` | New user appears on ldap2 |
| Kerberos login | `make kerberos-kinit` | TGT appears in klist |
| Service ticket | `bash tests/kerberos/test-service-ticket.sh` | Service ticket appears in klist |
| KDC failover | `make kerberos-failover` | Authentication succeeds through kdc2 |
| LDAP failover | `make ha-failover` | Read succeeds with ldap1 stopped |
| Expired certificate | `bash tests/tls/test-expired-cert.sh` | OpenSSL rejects certificate |
| Network partition | `bash tests/fault-injection/network-partition.sh` | Service failure is measured |
| Process crash | `bash tests/fault-injection/crash-server.sh` | Recovery time is recorded |
