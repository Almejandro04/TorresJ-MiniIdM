# Servicio web con TLS y Kerberos

El servicio web usa Apache, TLS y `mod_auth_gssapi`. La pagina es estatica para mantener el componente simple.

La topologia final usa dos VM: idm1 aloja Apache junto con CA, ldap1, kdc1,
HAProxy y Prometheus; idm2 aloja ldap2, kdc2 y el cliente. No existe un nodo
perimetral. El nombre `web.fis.epn.ec` apunta a idm1.

## Requisitos

```text
1. Certificado web.fis.epn.ec emitido por la CA
2. Principal HTTP/web.fis.epn.ec@FIS.EPN.EC
3. Keytab exportado como HTTP_web.fis.epn.ec.keytab
```

## Despliegue

```text
sudo bash web/scripts/00-install-web-deps.sh
sudo bash web/scripts/01-start-web.sh
bash web/scripts/02-test-https.sh web.fis.epn.ec
bash web/scripts/03-test-kerberos-web.sh jperez https://web.fis.epn.ec/
```

Apache conserva sus propios archivos bajo `/etc/apache2/miniidm`: la clave TLS
y el keytab son legibles solo por el grupo `www-data`, sin modificar el
directorio TLS compartido por slapd. No se guardan claves ni keytabs en Git.

`dns_canonicalize_hostname = false` evita que clientes Kerberos transformen
`HTTP/web.fis.epn.ec` en el principal de otro alias, por ejemplo
`HTTP/ldap1.fis.epn.ec`. Apache usa explicitamente
`HTTP/web.fis.epn.ec@FIS.EPN.EC` como principal aceptador.
