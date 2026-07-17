# Plan de nombres DNS

## Objetivo

Este documento define los nombres logicos que utiliza la infraestructura
MiniIdM.

Kerberos, LDAP, TLS y la alta disponibilidad dependen de nombres consistentes.
Por ello, los nombres de host se definen antes de generar certificados, crear
principals y configurar servicios.

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
| ldap1.fis.epn.ec | Servidor LDAP maestro |
| ldap2.fis.epn.ec | Servidor LDAP réplica |
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

- Los certificados TLS incluyen los nombres correctos.
- Los principals Kerberos utilizan nombres consistentes.
- El archivo `/etc/hosts` es igual en todos los nodos.
- La implementacion final usa dos VM: ldap1/kdc1 apuntan a idm1 y ldap2/kdc2 a idm2.
- El nombre virtual `ldap.fis.epn.edu.ec` apunta a HAProxy en idm1; no existe
  un nodo perimetral.
- El realm Kerberos se escribe en mayusculas: `FIS.EPN.EC`.
- La base LDAP se escribe como DN: `dc=fis,dc=epn,dc=ec`.

## Relacion con certificados

Los certificados de servidor consideran estos nombres:

| Servicio | Nombres recomendados |
|---|---|
| LDAP maestro | ldap1.fis.epn.ec, ldap1 |
| LDAP réplica | ldap2.fis.epn.ec, ldap2 |
| Balanceador LDAP | ldap.fis.epn.edu.ec |
| KDC primario | kdc1.fis.epn.ec, kdc1 |
| KDC secundario | kdc2.fis.epn.ec, kdc2 |
| Web | web.fis.epn.ec, web |

## Relacion con Kerberos

Los principals esperados son:

```text
jperez@FIS.EPN.EC
malvan@FIS.EPN.EC
dnoboa@FIS.EPN.EC
ldap/ldap1.fis.epn.ec@FIS.EPN.EC
ldap/ldap2.fis.epn.ec@FIS.EPN.EC
http/web.fis.epn.ec@FIS.EPN.EC
```
