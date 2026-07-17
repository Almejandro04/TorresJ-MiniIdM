# Topologia del laboratorio MiniIdM

## Objetivo

Este documento describe la distribucion logica de los servicios del proyecto.

La implementacion final usa dos maquinas virtuales. Los roles LDAP, KDC, web,
balanceo y monitoreo son logicos y se distribuyen entre esos dos nodos.

## Componentes requeridos

El proyecto incluye los siguientes componentes:

- LDAP maestro.
- LDAP réplica.
- KDC Kerberos primario.
- KDC Kerberos secundario.
- PKI con CA raiz.
- Balanceador LDAP.
- Servicio web con TLS y Kerberos.
- Cliente de pruebas.
- Componente de monitoreo.
- Pruebas de fallos.

## Dos maquinas virtuales

| Nodo | IP sugerida | Rol |
|---|---|---|
| idm1 | 192.168.56.10 | CA, LDAP maestro (ldap1), KDC primario (kdc1), balanceador, web y Prometheus |
| idm2 | 192.168.56.11 | LDAP réplica, KDC secundario y cliente de pruebas |

No existe un nodo perimetral: HAProxy comparte idm1 con slapd y por eso expone
LDAPS en 1636, mientras ldap1 y ldap2 mantienen 636. HAProxy,
Apache y Prometheus solo se ejecutan en idm1. No existen VIP, Keepalived ni un
tercer nodo; la perdida completa de idm1 no esta cubierta.

## Flujo de comunicacion esperado

```text
Cliente
  |
  | kinit / ticket de Kerberos
  v
KDC primario o secundario

Cliente
  |
  | ldapsearch / LDAPS
  v
Balanceador LDAP
  |
  |------> ldap1 (principal de escritura)
  |
  `------> ldap2 (respaldo de lectura)

Cliente
  |
  | HTTPS + Kerberos
  v
Servicio web
```

## Pruebas principales

| Prueba | Descripcion |
|---|---|
| Búsqueda LDAP | Se consultan usuarios en LDAP |
| LDAPS | Se verifica TLS con `openssl s_client` |
| Replicacion LDAP | Se crea un usuario en ldap1 y se verifica en ldap2 |
| Conmutación por error del KDC | Se detiene el KDC primario y se autentica con el secundario |
| Conmutación por error de LDAP | Se detiene slapd en ldap1 y se consulta por el balanceador |
| Certificado expirado | Se reemplaza el certificado valido por uno expirado |
| Partición de red | Se utiliza `iptables` para simular un fallo de comunicacion |
| Tiempo de recuperación | Se mide el tiempo de recuperacion del servicio |

## Metricas esperadas

| Experimento | Metrica |
|---|---|
| Replicacion LDAP | Retardo de propagacion |
| Conmutación por error del KDC | Latencia de autenticacion |
| Sobrecarga de TLS | Latencia de solicitudes |
| Balanceo de carga | Rendimiento |
| Fallos de nodos | Tiempo de recuperacion |
