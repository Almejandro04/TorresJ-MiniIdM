# Kerberos

## Objetivo y topologia

Esta carpeta configura MIT Kerberos para el realm `FIS.EPN.EC`. El KDC primario es `idm1.fis.epn.ec` (alias de servicio `kdc1.fis.epn.ec`) y el secundario es `idm2.fis.epn.ec` (alias de servicio `kdc2.fis.epn.ec`). LDAP almacena identidad; Kerberos autentica.

Los aliases siguen siendo los nombres anunciados a clientes en `krb5.conf`, pero la canonicalizacion de `kprop` usa los FQDN reales. Por ello existen los dos principals host de cada VM:

```text
host/kdc1.fis.epn.ec@FIS.EPN.EC
host/idm1.fis.epn.ec@FIS.EPN.EC
host/kdc2.fis.epn.ec@FIS.EPN.EC
host/idm2.fis.epn.ec@FIS.EPN.EC
```

Para los principals de servicio, `dns_canonicalize_hostname = false` y
`rdns = false` evitan que un cliente transforme
`HTTP/web.fis.epn.ec@FIS.EPN.EC` en un nombre de otro alias, como
`HTTP/ldap1.fis.epn.ec@FIS.EPN.EC`. Esto no cambia el realm ni los KDC
configurados.

## Principals

Usuarios:

```text
jperez@FIS.EPN.EC
malvan@FIS.EPN.EC
dnoboa@FIS.EPN.EC
```

Servicios:

```text
ldap/ldap1.fis.epn.ec@FIS.EPN.EC
ldap/ldap2.fis.epn.ec@FIS.EPN.EC
http/web.fis.epn.ec@FIS.EPN.EC
HTTP/web.fis.epn.ec@FIS.EPN.EC
```

El principal `http/web.fis.epn.ec` mantiene la equivalencia solicitada con `http/webserver` del enunciado. `HTTP/web.fis.epn.ec` se agrega para navegadores y Apache GSSAPI, que usan el servicio HTTP en mayusculas.

## Despliegue del primario (idm1)

Ejecutar como root, solamente en `idm1`:

```text
1. bash kerberos/scripts/00-install-kerberos.sh
2. bash kerberos/scripts/01-init-realm.sh
3. bash kerberos/scripts/02-create-user-principals.sh
4. bash kerberos/scripts/03-create-service-principals.sh
5. bash kerberos/scripts/04-export-keytabs.sh
6. bash kerberos/scripts/09-export-host-keytabs.sh
```

`01-init-realm.sh` es exclusivo del primario. Nunca debe ejecutarse en `idm2`: el secundario no crea un realm ni una base nueva.

El ultimo paso genera `principals/keytabs/idm1.keytab` e `principals/keytabs/idm2.keytab`. Cada archivo contiene el alias y el FQDN real de su VM. Copiar `idm1.keytab` a `/etc/krb5.keytab` en idm1 e `idm2.keytab` al mismo destino en idm2, mediante un canal seguro, con propietario `root:root` y modo `0600`.

## Preparacion y primera propagacion del secundario (idm2)

En Ubuntu Server 26.04, `kpropd` se distribuye en el paquete separado `krb5-kpropd`, su binario es `/usr/sbin/kpropd` y la unidad correcta es `krb5-kpropd.service`. No se debe crear una unidad `kpropd.service` manual.

El orden inicial en idm2 es:

```text
1. Instalar MIT Kerberos y krb5-kpropd con 00-install-kerberos.sh.
2. Instalar krb5.conf, kdc.conf y kpropd.acl con 06-configure-secondary-kdc.sh.
3. Instalar /etc/krb5.keytab que contenga host/kdc2 y host/idm2.
4. Copiar el stash de idm1 a /etc/krb5kdc/stash por un canal seguro.
5. Ejecutar de nuevo 06-configure-secondary-kdc.sh para mantener krb5-kdc detenido e iniciar krb5-kpropd.
6. Verificar que kpropd escucha en TCP 754.
7. Recibir la primera propagacion desde idm1.
8. Verificar la base con kadmin.local y habilitar/iniciar krb5-kdc.
9. Probar autenticacion y failover.
```

El script del secundario instala primero los archivos de configuracion. Si todavia faltan la keytab o el stash, termina con un mensaje claro; tras instalarlos se ejecuta de nuevo. Mientras no exista `/var/lib/krb5kdc/principal`, detiene `krb5-kdc` y habilita/inicia `krb5-kpropd`. Tambien valida el principal `host/idm2.fis.epn.ec@FIS.EPN.EC` sin mostrar claves.

El stash se genera **solo** cuando se inicializa el realm en idm1. Copiarlo de manera segura a idm2 como `/etc/krb5kdc/stash`, con propietario `root:root` y permisos `0600`. Nunca se versiona ni se almacena en este repositorio.

Una vez que `kpropd` escuche, desde idm1 ejecutar:

```bash
sudo make kerberos-check-propagation
sudo make kerberos-propagate KDC_SECONDARY=kdc2.fis.epn.ec
```

La propagacion comprueba la base, stash y keytab del primario, comprueba que la keytab contiene `host/idm1.fis.epn.ec@FIS.EPN.EC`, genera el dump protegido `/var/lib/krb5kdc/slave_datatrans` con `kdb5_util dump` y lo envia con `kprop`. No se envia la base binaria `principal` directamente.

En idm2, despues de recibir el primer dump:

```bash
sudo kadmin.local -q 'listprincs'
sudo systemctl enable --now krb5-kdc
```

## Validacion

En idm2, verificar el receptor antes de la primera propagacion:

```bash
command -v kpropd
sudo systemctl status krb5-kpropd
sudo ss -ltn 'sport = :754'
sudo klist -k /etc/krb5.keytab
```

Para probar el failover real, detener `krb5-kdc` en idm1 y, desde idm2, ejecutar:

```bash
sudo systemctl stop krb5-kdc       # en idm1
kdestroy
kinit jperez@FIS.EPN.EC
klist
kvno ldap/ldap2.fis.epn.ec@FIS.EPN.EC
```

La prueba equivalente del repositorio es `make kerberos-failover`; solicita el TGT y el ticket de servicio `ldap/ldap2.fis.epn.ec`.

## Seguridad

No guardar contrasenas, hashes, keytabs, stash ni dumps de bases en Git. Los keytabs generados viven en `principals/keytabs/`, directorio ignorado por Git, y deben transferirse por un canal seguro. Las exportaciones usan `ktadd -norandkey`, por lo que recrear el archivo de salida no rota las claves de los principals existentes.
