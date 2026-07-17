# Plantilla de resultados

La evidencia se guarda en `results/tables/`.

| Experimento | Entrada | Métrica | Evidencia |
|---|---|---|---|
| Replicación LDAP | Se agrega `testreplica` en ldap1 | propagation_ms | ldap-replication.csv |
| Conmutación por error del KDC | Se detiene el KDC primario | authentication_ms | kdc-failover.csv |
| Sobrecarga de TLS | Se comparan LDAP y LDAPS | latency_ms | tls-overhead.csv |
| Rendimiento de HAProxy | Se envían solicitudes LDAP mediante el frontal | requests_per_second | lb-throughput.csv |
| Fallos de nodo | Se usa `kill`, `iptables` o un certificado | recovery_ms | node-failures.csv |

En cada ejecución se registran la fecha, los nombres de nodo, el comando, el
valor de la métrica y el resultado.
