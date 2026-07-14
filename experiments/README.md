# Experimentos de rendimiento

Estos scripts generan mediciones reproducibles para la topologia final de dos VM. No detienen servicios ni modifican configuracion. Los CSV se crean al ejecutarlos en `results/experiments/`; el repositorio solo conserva el directorio vacio.

## Requisitos comunes

- Ejecutar desde una copia del repositorio con DNS o `/etc/hosts` configurado.
- Tener `ldap-utils`, `awk`, `timeout` y acceso a la CA del proyecto.
- No registrar contrasenas en variables, archivos CSV ni terminal compartida.

Si una operacion LDAP administrativa necesita autenticacion, definir `LDAP_BIND_DN`. Por defecto el script pregunta la clave con `-W`. Como alternativa no interactiva se puede indicar una ruta local ya protegida mediante `LDAP_BIND_PASSWORD_FILE`; ese archivo nunca se versiona ni se imprime.

## Replicacion LDAP

Ejecutar desde idm1 o un cliente con permiso de crear entradas temporales:

```bash
LDAP_BIND_DN='cn=admin,dc=fis,dc=epn,dc=ec' TRIALS=3 \
  bash experiments/measure-ldap-replication.sh
```

Usa `ldap1.fis.epn.ec` y `ldap2.fis.epn.ec` por defecto. Por cada prueba crea un `inetOrgPerson` con UID unico, espera hasta encontrarlo en ldap2 y lo borra mediante `trap`, incluso ante error o interrupcion. Puede cambiarse `MASTER_URI`, `REPLICA_URI`, `LDAP_BASE_DN`, `TRIALS` y `REPLICATION_TIMEOUT_SECONDS`.

El resultado `results/experiments/ldap-replication.csv` contiene:

```text
trial,start_timestamp,replication_ms,result
```

`result` es `ok` si ldap2 observa la entrada antes del limite o `timeout` si no la observa. Si el proceso se interrumpe y la eliminacion falla, eliminar manualmente el DN que aparece en la salida con `ldapdelete` usando la misma cuenta administrativa.

## Overhead TLS LDAP

Ejecutar desde idm1, idm2 o el cliente:

```bash
TRIALS=10 bash experiments/measure-ldap-tls-overhead.sh
```

Mide la misma busqueda de `jperez` sobre `ldap://ldap1.fis.epn.ec` y `ldaps://ldap1.fis.epn.ec`, validando LDAPS con `pki/certs/ca-root.crt`. Las variables disponibles son `LDAP_URI`, `LDAPS_URI`, `CA_CERT`, `TRIALS` y `QUERY_TIMEOUT_SECONDS`. El script muestra promedio, minimo y maximo solo de las consultas exitosas y escribe:

```text
protocol,trial,latency_ms,result
```

en `results/experiments/ldap-tls-overhead.csv`.

## Throughput HAProxy

Ejecutar desde idm2 o el cliente:

```bash
REQUESTS=200 CONCURRENCY=10 bash experiments/measure-haproxy-throughput.sh
```

Consulta el frontend `ldaps://ldap.fis.epn.edu.ec:1636`. Los backends siguen en 636, por lo que no se debe cambiar el puerto del frontend en la variable `LDAP_URI`. Se aceptan `REQUESTS`, `CONCURRENCY`, `QUERY_TIMEOUT_SECONDS`, `LDAP_BASE_DN` y `CA_CERT`. La concurrencia se implementa con procesos Bash y `ldapsearch`; no requiere herramientas de carga adicionales.

El archivo `results/experiments/haproxy-throughput.csv` usa:

```text
requests,concurrency,total_seconds,requests_per_second,successes,failures
```

Un resultado con fallos representa consultas que agotaron el timeout o no pudieron validar LDAPS; no es un resultado inventado ni se escribe hasta ejecutar el experimento.
