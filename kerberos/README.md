# Kerberos

## Objetivo

Esta carpeta configura MIT Kerberos para el realm `FIS.EPN.EC`.

Los KDC son `kdc1.fis.epn.ec` y `kdc2.fis.epn.ec`. LDAP almacena identidad; Kerberos autentica.

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
host/kdc1.fis.epn.ec@FIS.EPN.EC
host/kdc2.fis.epn.ec@FIS.EPN.EC
```

El principal `http/web.fis.epn.ec` mantiene la equivalencia solicitada con `http/webserver` del enunciado. `HTTP/web.fis.epn.ec` se agrega para navegadores y Apache GSSAPI, que usan el servicio HTTP en mayusculas.

## Orden de despliegue

En kdc1:

```text
1. bash kerberos/scripts/00-install-kerberos.sh
2. bash kerberos/scripts/01-init-realm.sh
3. bash kerberos/scripts/02-create-user-principals.sh
4. bash kerberos/scripts/03-create-service-principals.sh
5. bash kerberos/scripts/04-export-keytabs.sh
6. bash kerberos/scripts/09-export-host-keytabs.sh
```

En kdc2:

```text
1. bash kerberos/scripts/00-install-kerberos.sh
2. bash kerberos/scripts/06-configure-secondary-kdc.sh
```

Copiar `host_kdc1.fis.epn.ec.keytab` a kdc1 y `host_kdc2.fis.epn.ec.keytab` a kdc2. Instalar cada archivo como `/etc/krb5.keytab` con propietario root y permisos 0600.

Antes de propagar, ejecutar en kdc1:

```text
sudo make kerberos-check-propagation
```

Despues de validar keytabs, ejecutar en kdc1:

```text
bash kerberos/scripts/07-propagate-kdc-db.sh kdc2.fis.epn.ec
```

## Seguridad

No guardar contrasenas ni keytabs en Git. Los keytabs se generan en `principals/keytabs/`, directorio ignorado por Git, y deben copiarse por un canal seguro al servicio correspondiente.
