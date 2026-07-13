# TorresJ-MiniIdM

Secure identity infrastructure for the FIS distributed systems project.

## Scope

```text
LDAP base DN: dc=fis,dc=epn,dc=ec
Kerberos realm: FIS.EPN.EC
LDAP frontend: ldap.fis.epn.edu.ec
LDAP nodes: ldap1 and ldap2
KDC nodes: kdc1 and kdc2
Web service: web.fis.epn.ec
```

The project includes OpenLDAP, MIT Kerberos, an ECDSA PKI, Apache TLS Kerberos, HAProxy, Prometheus and fault tests.

## Quick review

```text
make check
make inventory
make help
make ldap
make kerberos
make integration
make web
make ha
make monitoring
make test
```

The Makefile lists the deployment order. System deployment commands must run in the corresponding Linux VM with root privileges.

## Repository layout

```text
docs/        Architecture, deployment and testing documents
inventory/   Node and DNS plan
pki/         OpenSSL CA and certificate scripts
ldap/        LDAP DIT, TLS and deployment scripts
kerberos/    MIT Kerberos configuration and scripts
integration/ LDAP Kerberos user mapping
web/         Apache TLS Kerberos service
ha/          HAProxy LDAP frontend
monitoring/  Prometheus configuration
tests/       Functional and fault tests
results/     CSV evidence and report material
```

## Security

Generated private keys, certificates, CSR files, CA state, keytabs and raw results are ignored by Git. Do not commit passwords, hashes, keytabs or private keys.

If generated keys were committed before this rule, remove them from the Git index and rotate them before publishing the repository.

## Final report

The final individual report must be a two page PDF named `TorresJ-MiniIdM.pdf` and must include the GitHub URL and external assistance disclosure.
