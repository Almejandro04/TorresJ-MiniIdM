# Architecture

```text
                 +-------------------+
                 | client.fis.epn.ec |
                 +-------------------+
                   |      |      |
                   |      |      +--> HTTPS and Kerberos --> web.fis.epn.ec
                   |      |
                   |      +--> Kerberos --> kdc1 or kdc2
                   |
                   +--> LDAPS --> ldap.fis.epn.edu.ec
                                      |
                                      +--> ldap1 and ldap2
```

`ldap1` is the write master and `ldap2` is the read replica. HAProxy exposes the LDAP virtual name. `kdc1` is the primary KDC and `kdc2` receives the propagated Kerberos database.

The root CA signs certificates for LDAP, KDC, web and the LDAP frontend. LDAP stores identity data; Kerberos authenticates users and services.
