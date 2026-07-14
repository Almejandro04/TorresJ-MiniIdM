# Experimentos de rendimiento

Los experimentos se ejecutan sobre la topologia real: idm1 aloja ldap1 y el
frontend HAProxy; idm2 aloja ldap2 y puede actuar como cliente. No detienen ni
reinician servicios. Los resultados se crean al ejecutarlos en
`results/experiments/` y no se versionan.

## Requisitos

- DNS o `/etc/hosts` debe resolver los nombres `ldap1`, `ldap2` y el frontend.
- Se requieren `ldap-utils`, `timeout`, `awk` y la CA del proyecto.
- No incluir contrasenas en comandos, CSV o Git. La prueba de replicacion usa
  `LDAP_BIND_DN` y solicita la clave con `-W`; opcionalmente acepta la ruta
  protegida `LDAP_BIND_PASSWORD_FILE` sin mostrar su contenido.

## Orden recomendado

1. Overhead TLS LDAP.
2. Throughput HAProxy.
3. Replicacion LDAP.

Las pruebas de fallos deben realizarse despues; su orden completo esta en
[`fault-tests/README.md`](../fault-tests/README.md).

## Overhead TLS LDAP

Ejecutar desde idm1, idm2 o el cliente:

```bash
TRIALS=10 WARMUP_TRIALS=2 bash experiments/measure-ldap-tls-overhead.sh
```

La misma busqueda y base DN se ejecutan contra `ldap://ldap1.fis.epn.ec` y
`ldaps://ldap1.fis.epn.ec`. El warm-up no se registra. Variables: `LDAP_URI`,
`LDAPS_URI`, `LDAP_BASE_DN`, `LDAP_FILTER`, `CA_CERT`, `TRIALS`,
`WARMUP_TRIALS` y `QUERY_TIMEOUT_SECONDS`.

`ldap-tls-overhead.csv`:

```text
timestamp,protocol,trial,latency_ms,result
```

`ldap-tls-summary.csv`:

```text
ldap_avg_ms,ldaps_avg_ms,tls_overhead_ms,tls_overhead_percent
```

El resumen muestra promedio, minimo, maximo y mediana de cada protocolo. No
calcula porcentaje si el promedio LDAP es cero.

## Throughput HAProxy

Ejecutar desde idm2 o el cliente:

```bash
REQUESTS=200 CONCURRENCY=10 bash experiments/measure-haproxy-throughput.sh
```

Usa `ldaps://ldap.fis.epn.edu.ec:1636` y un pool Bash de hasta
`CONCURRENCY` workers; no lanza todas las consultas simultaneamente. Variables:
`LDAP_URI`, `LDAP_BASE_DN`, `LDAP_FILTER`, `CA_CERT`, `REQUESTS`,
`CONCURRENCY` y `QUERY_TIMEOUT_SECONDS`.

El CSV `haproxy-throughput.csv` contiene:

```text
requests,concurrency,total_seconds,requests_per_second,average_latency_ms,successes,failures
```

Cada worker registra internamente `request_number,latency_ms,result` en un
directorio temporal y el script comprueba que exitosas más fallidas sea igual
al numero de solicitudes antes de escribir el resumen.

## Replicacion LDAP

Ejecutar desde idm1 o un cliente con permiso de crear entradas temporales:

```bash
LDAP_BIND_DN='cn=admin,dc=fis,dc=epn,dc=ec' LDAP_USERS_OU='ou=users' TRIALS=3 \
  bash experiments/measure-ldap-replication.sh
```

El DN temporal real es:

```text
uid=<uid-unico>,ou=users,dc=fis,dc=epn,dc=ec
```

Antes de iniciar se comprueba que `LDAP_USERS_OU` exista en ldap1. El polling
contra ldap2 usa `LDAP_QUERY_TIMEOUT_SECONDS`, por lo que no queda bloqueado
indefinidamente. Variables adicionales: `MASTER_URI`, `REPLICA_URI`,
`LDAP_BASE_DN`, `LDAP_USERS_OU`, `TRIALS`, `REPLICATION_TIMEOUT_SECONDS` y
`LDAP_QUERY_TIMEOUT_SECONDS`.

El `trap` elimina la entrada en master. Si no puede hacerlo, registra el DN
exacto en `results/experiments/ldap-replication-cleanup.log`; eliminarlo
manualmente con `ldapdelete` usando la misma cuenta administrativa.

`ldap-replication.csv` contiene:

```text
trial,start_timestamp,replication_ms,result
```
