# Experimentos de rendimiento

Los experimentos se ejecutan sobre la topologia real: idm1 aloja ldap1 y el
frontal HAProxy; idm2 aloja ldap2 y puede actuar como cliente. No detienen ni
reinician servicios. Los resultados se crean al ejecutarlos en
`results/experiments/` y no se versionan.

## Requisitos

- DNS o `/etc/hosts` resuelve los nombres `ldap1`, `ldap2` y el frontal.
- Se requieren `ldap-utils`, `timeout`, `awk` y la CA del proyecto.
- Las contrasenas no se incluyen en comandos, CSV o Git. La prueba de replicacion usa
  `LDAP_BIND_DN` y solicita la clave con `-W`; opcionalmente acepta la ruta
  protegida `LDAP_BIND_PASSWORD_FILE` sin mostrar su contenido.

## Orden recomendado

1. Sobrecarga TLS LDAP.
2. Rendimiento de HAProxy.
3. Replicacion LDAP.

Las pruebas de fallos se realizan despues; su orden completo esta en
[`fault-tests/README.md`](../fault-tests/README.md).

## Sobrecarga TLS LDAP

La prueba se ejecuta desde idm1, idm2 o el cliente:

```bash
TRIALS=10 WARMUP_TRIALS=2 bash experiments/measure-ldap-tls-overhead.sh
```

La misma busqueda y base DN se ejecutan contra `ldap://ldap1.fis.epn.ec` y
`ldaps://ldap1.fis.epn.ec`. El calentamiento no se registra. Variables: `LDAP_URI`,
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

## Rendimiento de HAProxy

La prueba se ejecuta desde idm2 o el cliente:

```bash
REQUESTS=200 CONCURRENCY=10 bash experiments/measure-haproxy-throughput.sh
```

Se utiliza `ldaps://ldap.fis.epn.edu.ec:1636` y un grupo Bash de hasta
`CONCURRENCY` procesos de trabajo; no se lanzan todas las consultas simultaneamente. Variables:
`LDAP_URI`, `LDAP_BASE_DN`, `LDAP_FILTER`, `CA_CERT`, `REQUESTS`,
`CONCURRENCY` y `QUERY_TIMEOUT_SECONDS`.

El CSV `haproxy-throughput.csv` contiene:

```text
requests,concurrency,total_seconds,requests_per_second,average_latency_ms,successes,failures
```

Cada proceso de trabajo registra internamente `request_number,latency_ms,result` en un
directorio temporal y el script comprueba que exitosas más fallidas sea igual
al numero de solicitudes antes de escribir el resumen.

## Replicacion LDAP

La prueba se ejecuta desde idm1 o un cliente con permiso para crear entradas
temporales:

```bash
LDAP_BIND_DN='cn=admin,dc=fis,dc=epn,dc=ec' LDAP_USERS_OU='ou=users' TRIALS=3 \
  bash experiments/measure-ldap-replication.sh
```

El DN temporal real es:

```text
uid=<uid-unico>,ou=users,dc=fis,dc=epn,dc=ec
```

Antes de iniciar se comprueba que `LDAP_USERS_OU` exista en ldap1. La consulta
contra ldap2 usa `LDAP_QUERY_TIMEOUT_SECONDS`, por lo que no queda bloqueado
indefinidamente. Variables adicionales: `MASTER_URI`, `REPLICA_URI`,
`LDAP_BASE_DN`, `LDAP_USERS_OU`, `TRIALS`, `REPLICATION_TIMEOUT_SECONDS` y
`LDAP_QUERY_TIMEOUT_SECONDS`.

El `trap` elimina la entrada en el maestro. Si no puede hacerlo, registra el DN
exacto en `results/experiments/ldap-replication-cleanup.log`; la entrada se
elimina manualmente con `ldapdelete` y la misma cuenta administrativa.

`ldap-replication.csv` contiene:

```text
trial,start_timestamp,replication_ms,result
```
