# Plan de nombres DNS

## Objetivo

Definir los nombres logicos que usara la infraestructura MiniIdM.

Kerberos, LDAP, TLS y alta disponibilidad dependen de nombres consistentes. Por eso, los nombres de host deben definirse antes de generar certificados, crear principals y configurar servicios.

## Dominio base

```text
fis.epn.ec
```

## Realm Kerberos

```text
FIS.EPN.EC
```

## Base DN LDAP

```text
dc=fis,dc=epn,dc=ec
```

## Nombres principales

| Nombre | Uso |
|---|---|
| ca.fis.epn.ec | Autoridad certificadora raiz |
| idm1.fis.epn.ec | Nodo principal de identidad |
| idm2.fis.epn.ec | Nodo secundario de identidad |
| ldap1.fis.epn.ec | Servidor LDAP master |
| ldap2.fis.epn.ec | Servidor LDAP replica |
| kdc1.fis.epn.ec | KDC Kerberos primario |
| kdc2.fis.epn.ec | KDC Kerberos secundario |
| ldap.fis.epn.edu.ec | Nombre virtual del balanceador LDAP |
| web.fis.epn.ec | Servicio web protegido |

## Alias locales

| Alias | Nombre completo |
|---|---|
| idm1 | idm1.fis.epn.ec |
| idm2 | idm2.fis.epn.ec |
| ldap1 | ldap1.fis.epn.ec |
| ldap2 | ldap2.fis.epn.ec |
| kdc1 | kdc1.fis.epn.ec |
| kdc2 | kdc2.fis.epn.ec |
| ca | ca.fis.epn.ec |
| web | web.fis.epn.ec |

## Consideraciones tecnicas

- Los certificados TLS deben incluir los nombres correctos.
- Los principals Kerberos deben usar nombres consistentes.
- El archivo `/etc/hosts` debe ser igual en todos los nodos.
- La implementacion final usa dos VM: ldap1/kdc1 apuntan a idm1 y ldap2/kdc2 a idm2.
- El nombre virtual `ldap.fis.epn.edu.ec` apunta a HAProxy en idm1; no existe un nodo edge.
- El realm Kerberos se escribe en mayusculas: `FIS.EPN.EC`.
- La base LDAP se escribe como DN: `dc=fis,dc=epn,dc=ec`.

## Relacion con certificados

Los certificados de servidor deberian considerar estos nombres:

| Servicio | Nombres recomendados |
|---|---|
| LDAP master | ldap1.fis.epn.ec, ldap1 |
| LDAP replica | ldap2.fis.epn.ec, ldap2 |
| Balanceador LDAP | ldap.fis.epn.edu.ec |
| KDC primario | kdc1.fis.epn.ec, kdc1 |
| KDC secundario | kdc2.fis.epn.ec, kdc2 |
| Web | web.fis.epn.ec, web |

## Relacion con Kerberos

Principals esperados:

```text
jperez@FIS.EPN.EC
malvan@FIS.EPN.EC
dnoboa@FIS.EPN.EC
ldap/ldap1.fis.epn.ec@FIS.EPN.EC
ldap/ldap2.fis.epn.ec@FIS.EPN.EC
http/web.fis.epn.ec@FIS.EPN.EC
```
