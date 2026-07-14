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
                   +--> LDAPS :1636 --> ldap.fis.epn.edu.ec
                                      |
                                      +--> ldap1 and ldap2
```

`ldap1` is the write master and `ldap2` is the read replica. HAProxy runs on
idm1 and exposes the LDAP virtual name on port 1636 because slapd already uses
636 there; both LDAP backends retain TLS on 636. `kdc1` is the primary KDC and
`kdc2` receives the propagated Kerberos database. The final implementation has
two physical nodes: idm1 hosts ldap1/kdc1 and the shared web, HAProxy and
monitoring roles; idm2 hosts ldap2/kdc2 and the test client.

The root CA signs certificates for LDAP, KDC, web and the LDAP frontend. LDAP stores identity data; Kerberos authenticates users and services.
