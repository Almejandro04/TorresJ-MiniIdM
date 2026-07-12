# LDAP

## Objetivo

Esta carpeta contiene los archivos base para configurar el servicio de directorio LDAP del proyecto MiniIdM.

LDAP almacenara informacion centralizada de usuarios, grupos y cuentas de servicio.

## Base DN

```text
dc=fis,dc=epn,dc=ec
```

## Componentes

| Componente | Descripcion |
|---|---|
| LDAP master | Servidor principal de escritura |
| LDAP replica | Servidor secundario para replicacion y lectura |
| LDAPS | LDAP protegido con TLS |
| DIT | Arbol de informacion del directorio |
| LDIF | Archivos usados para cargar entradas LDAP |

## Estructura del DIT

```text
dc=fis,dc=epn,dc=ec
├── ou=users
├── ou=groups
└── ou=services
```

## Usuarios de prueba

| Usuario | UID | Grupo |
|---|---|---|
| Juan Perez | jperez | estudiantes |
| Maria Alvan | malvan | profesores |
| Diego Noboa | dnoboa | empleados |

## Archivos LDIF

| Archivo | Uso |
|---|---|
| ldif/00-base-dn.ldif | Crea la base del directorio |
| ldif/01-organizational-units.ldif | Crea unidades organizacionales |
| ldif/02-groups.ldif | Crea grupos LDAP |
| ldif/03-users.ldif | Crea usuarios de prueba |
| ldif/04-service-accounts.ldif | Crea cuentas de servicio |
| ldif/05-test-user.ldif | Usuario adicional para probar replicacion |

## Configuracion

| Archivo | Uso |
|---|---|
| config/ldap1/tls.ldif | Configuracion TLS para LDAP master |
| config/ldap2/tls.ldif | Configuracion TLS para LDAP replica |
| config/ldap1/replication-provider.ldif | Plantilla de proveedor de replicacion |
| config/ldap2/replication-consumer.ldif | Plantilla de consumidor de replicacion |
| config/ldap1/slapd.conf.example | Referencia de configuracion para ldap1 |
| config/ldap2/slapd.conf.example | Referencia de configuracion para ldap2 |

## Scripts

| Script | Uso |
|---|---|
| scripts/00-install-openldap.sh | Instala paquetes base de OpenLDAP |
| scripts/01-load-base-dit.sh | Carga el DIT base |
| scripts/02-enable-ldaps.sh | Habilita TLS en LDAP |
| scripts/03-test-ldap-search.sh | Prueba consultas LDAP |
| scripts/04-test-replication.sh | Prueba replicacion LDAP |
| scripts/05-backup-ldap.sh | Genera respaldo LDIF del directorio |

## Notas

Los scripts estan preparados para ejecutarse en Linux.

La implementacion real se completara cuando se definan las maquinas virtuales y las credenciales administrativas.