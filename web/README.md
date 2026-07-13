# Web TLS Kerberos

El servicio web usa Apache, TLS y `mod_auth_gssapi`. La pagina es estatica para mantener el componente simple.

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

Las claves privadas y keytabs se copian al sistema con permisos de grupo para `www-data`. No se guardan en Git.
