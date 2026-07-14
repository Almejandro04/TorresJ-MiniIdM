# Pruebas de fallos controladas

La topologia tiene dos VM: idm1 aloja ldap1, kdc1, Apache, HAProxy, Prometheus
y la CA; idm2 aloja ldap2, kdc2 y el cliente. Todos los scripts son
**dry-run por defecto**; ejecutar primero sin `--apply`. Solo `--apply` permite
detener, matar, reiniciar, insertar reglas o reemplazar archivos. No usarlos en
produccion.

Los resultados se crean al ejecutar las pruebas en `results/faults/`; no hay
resultados inventados ni archivos de secretos en Git.

## Riesgos y recuperacion manual

- `kill -9`, la particion de red y el certificado temporal pueden interrumpir
  clientes en curso; no los ejecute durante mantenimiento LDAP o Kerberos.
- Si un servicio no vuelve, inicie solo el servicio afectado con
  `sudo systemctl start NOMBRE_SERVICIO` y valide antes de continuar.
- Si queda un backup de certificado, copie el archivo mostrado por el script a
  `TARGET_FILE` con `sudo cp --preserve=mode,ownership BACKUP TARGET_FILE`,
  ejecute el configtest correspondiente y reinicie `apache2` o `haproxy`.

## Orden recomendado

1. TLS overhead LDAP.
2. Throughput HAProxy.
3. Replicacion LDAP.
4. Failover LDAP.
5. Failover KDC.
6. Kill de servicio.
7. Particion de red.
8. Certificado invalido.

## Failover LDAP — idm1

```bash
sudo bash fault-tests/test-ldap-failover.sh
sudo FAILOVER_TIMEOUT_SECONDS=20 bash fault-tests/test-ldap-failover.sh --apply
```

Requiere `slapd`, HAProxy, `ldapsearch` y la CA. Verifica que slapd quede
inactivo, mide la respuesta de `ldaps://ldap.fis.epn.edu.ec:1636`, e inicia
slapd mediante `trap`. El limite es 25 segundos para que la interrupcion no
supere 30. Tras restaurar, comprueba estado, TCP 636 y una consulta directa a
ldap1. Si falla: `sudo systemctl start slapd`.

Variables: `LDAP_URI`, `LDAP1_URI`, `LDAP_BASE_DN`, `LDAP_FILTER`, `CA_CERT`,
`FAILOVER_TIMEOUT_SECONDS`. CSV:

```text
timestamp,failover_ms,restore_ms,ldap_direct_after,result
```

La confirmacion de backend concreto es opcional porque HAProxy no expone ese
dato de forma segura sin instrumentacion adicional.

## Failover KDC — idm2 o cliente

```bash
KRB_TEST_KEYTAB=/ruta/protegida/test.keytab \
KRB_TEST_PRINCIPAL=usuario-prueba@FIS.EPN.EC \
bash fault-tests/test-kdc-failover.sh --manual
```

El keytab de prueba es obligatorio, debe existir y no ser world-readable.
**Nunca se versiona**, imprime ni se copia al repositorio. La medicion usa
`kinit -k -t`, elimina tickets antes de cada intento y verifica `klist -s`.
Un trace temporal `KRB5_TRACE` identifica, si es posible, el KDC que respondio
y se borra con el `trap`.

Para ejecutar de verdad:

```bash
KRB_TEST_KEYTAB=/ruta/protegida/test.keytab \
KRB_TEST_PRINCIPAL=usuario-prueba@FIS.EPN.EC \
bash fault-tests/test-kdc-failover.sh --apply --manual
```

El modo manual exige confirmar `DETENIDO` tras parar el primario y
`RESTAURADO` despues de iniciarlo; verifica luego TCP 88. Con SSH configurado
sin prompt y `sudo -n`:

```bash
KRB_TEST_KEYTAB=/ruta/protegida/test.keytab \
KRB_TEST_PRINCIPAL=usuario-prueba@FIS.EPN.EC \
  bash fault-tests/test-kdc-failover.sh --apply --ssh-primary admin@idm1.fis.epn.ec
```

El modo SSH verifica BatchMode y sudo antes de detener algo y el `trap` restaura
el KDC. Variables: `KRB_TEST_KEYTAB`, `KRB_TEST_PRINCIPAL`,
`KINIT_TIMEOUT_SECONDS`, `PRIMARY_KDC_HOST` y `PRIMARY_KDC_PORT`. CSV:

```text
timestamp,mode,principal,baseline_ms,failover_ms,kdc_used,result
```

Si la restauracion manual falla, en idm1 ejecute:

```bash
sudo systemctl start krb5-kdc
```

## Kill de servicio — nodo propietario

```bash
sudo bash fault-tests/test-service-kill.sh haproxy
sudo RECOVERY_TIMEOUT_SECONDS=20 bash fault-tests/test-service-kill.sh haproxy --apply
```

Solo acepta `slapd`, `apache2`, `haproxy` y `krb5-kdc`. Guarda el PID previo,
espera transición y exige un `MainPID` nuevo más una comprobación funcional;
nunca acepta `active` con el PID antiguo. Si `Restart=no`, registra
`no_auto_restart` y el `trap` ejecuta `systemctl start`. Variables funcionales:
`SLAPD_HOST`, `SLAPD_PORT`, `APACHE_HOST`, `APACHE_PORT`, `HAPROXY_HOST`,
`HAPROXY_PORT`, `HAPROXY_LDAP_URI`, `HAPROXY_LDAP_BASE_DN`, `HAPROXY_CA_CERT`,
`KDC_HOST`, `KDC_PORT`, `FUNCTIONAL_TIMEOUT_SECONDS` y
`RECOVERY_TIMEOUT_SECONDS`. Recuperacion manual: `sudo systemctl start SERVICIO`.

CSV:

```text
timestamp,service,old_pid,new_pid,recovery_ms,result
```

## Particion de red LDAP — idm1 o idm2

```bash
sudo bash fault-tests/test-network-partition.sh
sudo PARTITION_SECONDS=10 TOTAL_TIMEOUT_SECONDS=30 \
  bash fault-tests/test-network-partition.sh --apply
```

Solo bloquea TCP 389 o 636 entre `192.168.56.10` y `192.168.56.11`, nunca vacia
las reglas de `iptables` ni elimina reglas ajenas. Verifica TCP y LDAP antes, que el acceso
directo falle durante el bloqueo, y TCP/LDAP tras retirarlo. En idm1 puede
comprobar HAProxy con `HAPROXY_DURING_CHECK=true`; es una observacion adicional.
Las reglas se etiquetan y se guardan exactamente en
`network-partition-rules.txt`; el `trap` elimina solo las que alcanzaron a
insertarse. Si una restauracion falla, usar `iptables -S` para localizar la
etiqueta `miniidm-ldap-partition-...` y eliminar esas reglas con `iptables -D`.

Variables: `LDAP_PORT`, `PARTITION_SECONDS`, `TOTAL_TIMEOUT_SECONDS`,
`REMOTE_IP`, `REMOTE_LDAP_URI`, `LDAP_BASE_DN`, `LDAP_FILTER`, `CA_CERT`,
`HAPROXY_URI`, `HAPROXY_DURING_CHECK`. CSV:

```text
timestamp,node,remote_ip,port,duration_seconds,blocked,recovered,ldap_before,ldap_during,ldap_after,result
```

## Certificado invalido — idm1

```bash
sudo INVALID_FILE=/ruta/certificado-prueba.pem \
  bash fault-tests/test-invalid-certificate.sh apache2
```

`INVALID_FILE` es obligatorio y no se genera automaticamente. Para Apache debe
ser certificado PEM; el script compara su clave publica con la clave instalada
y documenta un posible rechazo por mismatch. Para HAProxy debe ser un PEM
completo con certificado y clave compatibles, pero que el cliente rechace por
expiracion, CA incorrecta u hostname.

Con `--apply` valida el servicio y TLS actual, conserva backup, permisos y
ownership, ejecuta configtest sin abortar, reinicia temporalmente si procede y
comprueba el rechazo TLS desde cliente. Finalmente restaura, valida config,
reinicia y confirma TLS valido antes de borrar el backup. Si falla, conserva el
respaldo y muestra la ruta para recuperacion manual.

```bash
sudo INVALID_FILE=/ruta/certificado-prueba.pem \
  bash fault-tests/test-invalid-certificate.sh apache2 --apply
```

Variables: `TLS_CA_CERT`, `TARGET_FILE`, `INSTALLED_KEY`, `APACHE_URL`,
`HAPROXY_TLS_HOST`, `HAPROXY_TLS_PORT`. CSV:

```text
timestamp,service,target_file,invalid_file,config_result,tls_invalid_result,restore_result,result
```
