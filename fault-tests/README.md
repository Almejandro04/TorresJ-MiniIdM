# Pruebas de fallos controladas

La topologia final tiene dos VM: idm1 aloja ldap1, kdc1, Apache, HAProxy,
Prometheus y la CA; idm2 aloja ldap2, kdc2 y el cliente. Todos los scripts son
**dry-run por defecto**. Solo `--apply` permite detener, matar, reiniciar o
insertar reglas. No ejecutarlos en produccion.

Los CSV se crean solamente al ejecutar las pruebas en `results/faults/`; el
repositorio conserva el directorio vacio.

## Failover LDAP

Ejecutar exclusivamente como root en idm1:

```bash
sudo bash fault-tests/test-ldap-failover.sh
sudo FAILOVER_TIMEOUT_SECONDS=20 bash fault-tests/test-ldap-failover.sh --apply
```

Valida `slapd` y HAProxy, detiene slapd y consulta
`ldaps://ldap.fis.epn.edu.ec:1636` hasta recibir respuesta de ldap2. El limite
por defecto es 25 segundos (maximo 25, para restaurar slapd antes de 30) y un
`trap` inicia slapd ante salida normal, error o interrupcion. Recuperacion manual:

```bash
sudo systemctl start slapd
sudo systemctl status slapd haproxy
```

`ldap-failover.csv` contiene `timestamp,failover_ms,result`.

## Failover KDC

Ejecutar desde idm2 o el cliente. El script no supone SSH sin clave ni guarda
contrasenas de Kerberos; `kinit` solicita la clave de forma interactiva.

```bash
KRB_USER=jperez bash fault-tests/test-kdc-failover.sh --manual
KRB_USER=jperez bash fault-tests/test-kdc-failover.sh --apply --manual
```

En modo manual mide una linea base, pide detener `krb5-kdc` en idm1 desde otra
sesion y espera la confirmacion `CONTINUAR`. Restaurar manualmente con:

```bash
sudo systemctl start krb5-kdc       # en idm1
```

Solo con SSH configurado sin prompt y `sudo -n` autorizado se puede usar el
modo que se hace responsable de la restauracion:

```bash
KRB_USER=jperez bash fault-tests/test-kdc-failover.sh \
  --apply --ssh-primary admin@idm1.fis.epn.ec
```

El `trap` inicia el KDC remoto si el propio script lo detuvo.
`kdc-failover.csv` usa
`timestamp,mode,principal,baseline_ms,failover_ms,result`.
`KINIT_TIMEOUT_SECONDS` limita cada autenticacion a 30 segundos por defecto.

## Kill de servicios

Ejecutar como root en el nodo que hospeda el servicio:

```bash
sudo bash fault-tests/test-service-kill.sh haproxy
sudo RECOVERY_TIMEOUT_SECONDS=20 bash fault-tests/test-service-kill.sh haproxy --apply
```

Solo acepta `slapd`, `apache2`, `haproxy` o `krb5-kdc`. Con `--apply` usa
`kill -9` sobre el `MainPID` de systemd y espera hasta 30 segundos por la
recuperacion. Si no se recupera, el `trap` intenta iniciarlo. Recuperacion
manual: `sudo systemctl start NOMBRE_SERVICIO`.
`service-kill.csv` contiene `timestamp,service,recovery_ms,result`.

`kill -9` puede interrumpir operaciones en curso; no ejecutarlo durante
administracion LDAP o Kerberos.

## Particion de red LDAP

Ejecutar como root solo en idm1 o idm2:

```bash
sudo bash fault-tests/test-network-partition.sh
sudo PARTITION_SECONDS=10 bash fault-tests/test-network-partition.sh --apply
```

El dry-run muestra las reglas. Con `--apply`, inserta dos reglas `DROP` TCP
para LDAP entre `192.168.56.10` y `192.168.56.11`, por defecto en 636
(acepta exclusivamente 389 o 636). No usa `iptables -F`, etiqueta las reglas y
el `trap` borra exactamente esas reglas. La duracion maxima es 20 segundos y
se comprueba conectividad antes y despues.

Las reglas se guardan en `results/faults/network-partition-rules.txt`. Si una
restauracion automatica falla, ubicar la etiqueta
`miniidm-ldap-partition-...` con `iptables -S` y ejecutar solo las dos reglas
equivalentes con `iptables -D`.

## Certificado invalido

El modo inicial no modifica archivos:

```bash
sudo bash fault-tests/test-invalid-certificate.sh apache2
```

Para ejecutar una prueba controlada, proporcionar un archivo ya creado para
pruebas. Para Apache puede ser un certificado expirado de prueba compatible
con su clave; para HAProxy debe ser un PEM de prueba completo con su clave.
No generar ni usar certificados reales del servicio.

```bash
sudo INVALID_FILE=/ruta/expired-test.crt \
  bash fault-tests/test-invalid-certificate.sh apache2 --apply
```

El script respalda el archivo, valida `apache2ctl configtest` o `haproxy -c`
antes de reiniciar y el `trap` restaura, valida e inicia el servicio de nuevo.
Si hiciera falta recuperacion manual, copiar el respaldo sobre el objetivo y
ejecutar el mismo comando de validacion seguido de `systemctl restart`.
`invalid-certificate.csv` contiene
`timestamp,service,target_file,invalid_file,result`.
