# PKI

## Objetivo

Esta carpeta contiene los archivos necesarios para construir la infraestructura de llave publica del proyecto MiniIdM.

La PKI se usara para emitir certificados TLS para:

- LDAP master.
- LDAP replica.
- KDC Kerberos primario.
- KDC Kerberos secundario.
- Servicio web.
- Balanceador LDAP.

## Requisitos del proyecto

- Usar OpenSSL.
- Crear una CA raiz.
- Emitir certificados usando ECDSA.
- Usar certificados para LDAP sobre TLS.
- Verificar certificados con `openssl s_client`.

## Estructura

```text
pki/
├── openssl/
├── scripts/
├── ca/
├── certs/
├── private/
└── csr/
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

No se deben subir claves privadas reales al repositorio.

Los archivos dentro de `pki/private/` deben mantenerse fuera de GitHub.