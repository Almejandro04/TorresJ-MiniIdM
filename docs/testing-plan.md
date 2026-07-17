# Plan de pruebas

| Prueba | Comando | Resultado esperado |
|---|---|---|
| Búsqueda LDAP | `make ldap-search` | Se devuelven entradas de usuario |
| LDAPS | `bash tests/ldap/test-ldaps.sh` | Se completa la validación de la CA |
| Replicación LDAP | `bash tests/ldap/test-replication-delay.sh` | El usuario nuevo aparece en ldap2 |
| Inicio de sesión Kerberos | `make kerberos-kinit` | El TGT aparece en `klist` |
| Ticket de servicio | `bash tests/kerberos/test-service-ticket.sh` | El ticket de servicio aparece en `klist` |
| Conmutación por error del KDC | `make kerberos-failover` | La autenticación se completa mediante kdc2 |
| Conmutación por error de LDAP | `make ha-failover` | La lectura se completa con ldap1 detenido |
| Certificado expirado | `bash tests/tls/test-expired-cert.sh` | OpenSSL rechaza el certificado |
| Partición de red | `bash tests/fault-injection/network-partition.sh` | Se mide el fallo del servicio |
| Caída de proceso | `bash tests/fault-injection/crash-server.sh` | Se registra el tiempo de recuperación |
