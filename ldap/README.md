# LDAP

## Objetivo

Esta carpeta contiene la base LDAP del proyecto MiniIdM.

LDAP almacena usuarios, grupos y cuentas de servicio bajo el DN:

```text
dc=fis,dc=epn,dc=ec
```

## DIT

```text
dc=fis,dc=epn,dc=ec
|-- ou=users
|-- ou=groups
`-- ou=services
```

Los usuarios de prueba son `jperez`, `malvan` y `dnoboa`. Cada entrada incluye UID, grupo, home, shell y correo.

## Orden de despliegue

Ejecutar estos pasos en cada VM LDAP. Los comandos que cambian el sistema requieren root.

```text
1. bash ldap/scripts/00-install-openldap.sh
2. sudo make ldap-config-apply
3. sudo make ldap-certs LDAP_NODE=ldap1
4. sudo make ldap-enable-ldaps LDAP_NODE=ldap1
5. sudo make ldap-enable-ldaps-listener
6. make ldap-hash
7. Reemplazar REPLACE_WITH_HASHED_PASSWORD en los LDIF
8. make ldap-load
9. sudo make ldap-syncprov en ldap1
10. Reemplazar credentials=REPLACE_WITH_PASSWORD en ldap2
11. sudo make ldap-replication-consumer en ldap2
12. make ldap-search LDAP_URI=ldap://localhost
```

Para `ldap2`, usar `LDAP_NODE=ldap2` en los pasos de certificados y TLS.

## Scripts

| Script | Uso |
|---|---|
| scripts/00-install-openldap.sh | Instala slapd y ldap-utils |
| scripts/00-generate-password-hash.sh | Genera un hash SSHA sin guardar la contrasena |
| scripts/01-configure-slapd.sh | Configura el DIT base con cn=config |
| scripts/02-install-ldap-certificates.sh | Copia CA, certificado y clave a /etc/ssl/miniidm |
| scripts/03-enable-ldaps.sh | Aplica la configuracion TLS del nodo |
| scripts/04-load-base-dit.sh | Carga las entradas LDIF base |
| scripts/05-test-ldap-search.sh | Ejecuta una consulta LDAP basica |
| scripts/06-test-replication.sh | Plantilla de consulta para replicacion |
| scripts/07-backup-ldap.sh | Genera un respaldo LDIF |
| scripts/08-enable-syncprov.sh | Habilita syncprov en ldap1 |
| scripts/09-enable-replication-consumer.sh | Habilita syncrepl en ldap2 |
| scripts/10-enable-ldaps-listener.sh | Habilita ldaps:/// en slapd |

## Seguridad

Los LDIF conservan `REPLACE_WITH_HASHED_PASSWORD`. No guardar contrasenas ni hashes reales en Git.

La clave privada se instala con permisos 0640 y grupo `openldap`. La CA privada nunca se copia al servidor LDAP.

## Alcance actual

Aplicar syncprov solo en ldap1. Aplicar el consumidor solo en ldap2 despues de reemplazar la credencial de `svc-replica` fuera de Git.
