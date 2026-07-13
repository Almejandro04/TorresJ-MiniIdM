# Deployment

## Names

```text
Realm: FIS.EPN.EC
LDAP base DN: dc=fis,dc=epn,dc=ec
LDAP frontend: ldap.fis.epn.edu.ec
```

## Order

```text
1. Configure DNS or /etc/hosts on every VM.
2. Create the PKI and service certificates.
3. Deploy LDAP base on ldap1 and ldap2.
4. Deploy Kerberos on kdc1 and kdc2.
5. Validate LDAP Kerberos user mapping.
6. Deploy Apache TLS Kerberos on web.
7. Deploy HAProxy on edge.
8. Deploy Prometheus and node exporter.
9. Run functional tests and fault tests.
```

Use `make help` to view the available commands. Commands that install packages or edit `/etc` must run in the appropriate VM with root privileges.
