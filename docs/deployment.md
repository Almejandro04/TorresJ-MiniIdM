# Despliegue

## Topología

Se utiliza la opción de dos VM descrita en
[`inventory/topology.md`](../inventory/topology.md).

| VM | IP | Roles |
|---|---|---|
| idm1 | 192.168.56.10 | CA ECDSA, ldap1, kdc1, Apache, HAProxy, Prometheus y node exporter |
| idm2 | 192.168.56.11 | ldap2, kdc2, cliente de pruebas y node exporter |

Los roles son lógicos y se distribuyen entre dos nodos físicos: ldap1 y kdc1
resuelven a idm1; ldap2 y kdc2 resuelven a idm2. HAProxy, Apache y Prometheus
solo se ejecutan en idm1. No se utiliza una VM perimetral, VIP, Keepalived ni
un tercer nodo. HAProxy utiliza el puerto externo 1636 porque slapd ya ocupa
el puerto 636 de idm1; los servidores LDAP mantienen TLS en el puerto 636.

LDAP utiliza ldap1 como maestro de escritura y ldap2 como réplica. HAProxy
envía las conexiones a ldap1 normalmente y activa ldap2 únicamente como
respaldo. La conmutación por error de LDAP conserva principalmente las
consultas de lectura; no se utiliza LDAP multimaestro ni alta disponibilidad de
escritura. Kerberos puede obtener tickets desde kdc2 cuando kdc1 falla. La
pérdida completa de idm1 no está cubierta.

## Archivo hosts

Las siguientes entradas se añaden a `/etc/hosts` en ambas VM:

```text
192.168.56.10 idm1.fis.epn.ec idm1 ldap1.fis.epn.ec ldap1 kdc1.fis.epn.ec kdc1 ca.fis.epn.ec ca ldap.fis.epn.edu.ec web.fis.epn.ec
192.168.56.11 idm2.fis.epn.ec idm2 ldap2.fis.epn.ec ldap2 kdc2.fis.epn.ec kdc2
```

## Orden de despliegue

### idm1

En idm1, la preparación inicial se realiza como `root`:

```text
make pki
make pki-demo-certs
bash ldap/scripts/00-install-openldap.sh
make ldap-config-apply
make ldap-certs LDAP_NODE=ldap1
make ldap-enable-ldaps LDAP_NODE=ldap1
make ldap-enable-ldaps-listener
```

El hash LDAP se genera desde una cuenta sin privilegios:

```text
make ldap-hash
```

Los marcadores de contraseña de los LDIF se sustituyen únicamente en la copia
local. Los hashes reales no se guardan en Git. Después, el despliegue continúa
como `root`:

```text
make ldap-load
make ldap-syncprov
bash kerberos/scripts/00-install-kerberos.sh
bash kerberos/scripts/01-init-realm.sh
make kerberos-users
make kerberos-services
make kerberos-keytabs
make kerberos-host-keytabs
sudo bash web/scripts/00-install-web-deps.sh
sudo bash web/scripts/01-start-web.sh
sudo bash ha/scripts/00-install-haproxy.sh
sudo bash ha/scripts/01-configure-ldap-lb.sh
sudo bash monitoring/scripts/00-install-monitoring.sh
sudo bash monitoring/scripts/01-start-prometheus.sh
```

### idm2

En idm2, el despliegue se realiza como `root`:

```text
bash ldap/scripts/00-install-openldap.sh
make ldap-config-apply
make ldap-certs LDAP_NODE=ldap2
make ldap-enable-ldaps LDAP_NODE=ldap2
make ldap-enable-ldaps-listener
make ldap-replication-consumer
bash kerberos/scripts/00-install-kerberos.sh
# Se copia idm2.keytab a /etc/krb5.keytab y el stash de idm1 a /etc/krb5kdc/stash
bash kerberos/scripts/06-configure-secondary-kdc.sh
sudo bash monitoring/scripts/00-install-monitoring.sh
```

El script del consumidor solicita de forma oculta la contraseña de
`svc-replica`, la inserta solamente en un LDIF temporal con permisos
restrictivos y la elimina al finalizar. La plantilla versionada conserva
`REPLACE_WITH_PASSWORD`; no se edita con una contraseña real.

Para Kerberos, `kdc1.fis.epn.ec` y `kdc2.fis.epn.ec` son alias de servicio; los
nombres reales de host son `idm1.fis.epn.ec` e `idm2.fis.epn.ec`. El keytab de
idm1 se copia a `/etc/krb5.keytab` en idm1 y el de idm2 se copia a la misma
ruta en idm2, con propietario `root:root` y modo `0600`. El keytab de idm2
debe incluir `host/kdc2.fis.epn.ec@FIS.EPN.EC` y
`host/idm2.fis.epn.ec@FIS.EPN.EC`.

El archivo `stash` generado por `01-init-realm.sh` en idm1 se copia por un
canal seguro a `/etc/krb5kdc/stash` en idm2, con propietario `root:root` y modo
`0600`. Este archivo no se versiona. `kerberos/scripts/01-init-realm.sh` no se
ejecuta en idm2: el KDC secundario recibe su base mediante `kprop`.

Cuando `krb5-kpropd` escucha en TCP 754 en idm2, en idm1 se realiza la
propagación como `root`:

```text
make kerberos-check-propagation
make kerberos-propagate KDC_SECONDARY=kdc2.fis.epn.ec
```

El script de propagación genera un dump protegido de `kdb5_util` y lo envía con
`kprop`; nunca envía directamente `/var/lib/krb5kdc/principal`. Después de la
primera propagación, la base se verifica en idm2 con `kadmin.local` y allí se
habilita `krb5-kdc` con `systemctl enable --now krb5-kdc`.

## Validación

Desde idm2, la validación se realiza con una cuenta sin privilegios:

```text
make ldap-search LDAP_URI=ldap://ldap1.fis.epn.ec
bash tests/ldap/test-ldaps.sh ldap1.fis.epn.ec
make kerberos-kinit KRB_USER=jperez
make kerberos-check-propagation
make ha-test LDAP_LB_URI=ldaps://ldap.fis.epn.edu.ec:1636
make test-run
```

Se espera que LDAP devuelva las entradas de usuario, que LDAPS valide la CA,
que `klist` muestre un TGT y que la búsqueda mediante HAProxy devuelva
`jperez` a través de `ldap.fis.epn.edu.ec:1636`.

Para validar la conmutación por error de Kerberos, `krb5-kdc` se detiene en
idm1 y desde idm2 se ejecuta `make kerberos-failover KRB_USER=jperez`. La
prueba debe obtener un TGT y un ticket para `ldap/ldap2.fis.epn.ec` a través
del KDC secundario.

Para validar la alta disponibilidad de LDAP se utiliza
`ldaps://ldap.fis.epn.edu.ec:1636`. El puerto externo 636 requiere que HAProxy
se ejecute en un nodo o IP independiente, por lo que no está disponible cuando
comparte idm1 con slapd.

## Resultados

Los resultados finales se encuentran en [`RESULTADOS.md`](../RESULTADOS.md).
Los CSV de ejecuciones locales permanecen ignorados y no se versionan.
