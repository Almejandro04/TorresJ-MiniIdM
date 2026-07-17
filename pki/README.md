# PKI

## Objetivo

Esta carpeta contiene los archivos necesarios para construir la infraestructura
de clave publica del proyecto MiniIdM.

La PKI se utiliza para emitir certificados TLS para:

- LDAP maestro.
- LDAP réplica.
- KDC Kerberos primario.
- KDC Kerberos secundario.
- Servicio web.
- Balanceador LDAP.

## Requisitos del proyecto

- Se utiliza OpenSSL.
- Se crea una CA raiz.
- Se emiten certificados mediante ECDSA.
- Se utilizan certificados para LDAP sobre TLS.
- Los certificados se verifican con `openssl s_client`.

## Estructura

```text
pki/
|-- openssl/
|-- scripts/
|-- ca/
|-- certs/
|-- private/
`-- csr/
```

## Archivos importantes

| Archivo | Uso |
|---|---|
| openssl/ca-root.cnf | Configuracion para la CA raiz |
| openssl/server-cert.cnf | Configuracion para certificados de servidor |
| openssl/expired-cert.cnf | Configuracion para generar certificado expirado |
| scripts/00-init-ca.sh | Inicializa la CA raiz |
| scripts/01-create-server-cert.sh | Crea certificado de servidor |
| scripts/02-create-expired-cert.sh | Crea certificado expirado |
| scripts/03-verify-cert.sh | Verifica certificados generados |

## Notas de seguridad

Las claves privadas reales no se suben al repositorio.

Los archivos dentro de `pki/private/` se mantienen fuera de GitHub.
