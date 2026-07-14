# Topologia del laboratorio MiniIdM

## Objetivo

Documentar la distribucion logica de los servicios del proyecto.

La implementacion final usa dos maquinas virtuales. Los roles LDAP, KDC, web,
balanceo y monitoreo son logicos y se distribuyen entre esos dos nodos.

## Componentes requeridos

El proyecto debe incluir:

- LDAP master.
- LDAP replica.
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
| idm1 | 192.168.56.10 | CA, LDAP Master (ldap1), KDC Primario (kdc1), Balanceador, Web, Prometheus |
| idm2 | 192.168.56.11 | LDAP Replica, KDC Secundario, Cliente de pruebas |

No existe un nodo `edge`: HAProxy comparte idm1 con slapd y por eso expone
LDAPS en 1636, mientras los backends ldap1 y ldap2 mantienen 636.

## Flujo de comunicacion esperado

```text
Cliente
  |
  | kinit / ticket Kerberos
  v
KDC Primario o Secundario

Cliente
  |
  | ldapsearch / LDAPS
  v
Balanceador LDAP
  |
  |------> ldap1
  |
  |------> ldap2

Cliente
  |
  | HTTPS + Kerberos
  v
Servicio Web
```

## Pruebas principales

| Prueba | Descripcion |
|---|---|
| LDAP search | Consultar usuarios en LDAP |
| LDAPS | Verificar TLS con openssl s_client |
| Replicacion LDAP | Crear usuario en ldap1 y verificar en ldap2 |
| KDC failover | Detener KDC primario y autenticar con secundario |
| LDAP failover | Detener slapd en ldap1 y consultar por balanceador |
| Certificado expirado | Reemplazar certificado valido por uno expirado |
| Particion de red | Usar iptables para simular fallo de comunicacion |
| Tiempo de recuperacion | Medir cuanto tarda el servicio en recuperarse |

## Metricas esperadas

| Experimento | Metrica |
|---|---|
| Replicacion LDAP | Retardo de propagacion |
| Failover del KDC | Latencia de autenticacion |
| Overhead de TLS | Latencia de solicitudes |
| Balanceo de carga | Throughput |
| Fallos de nodos | Tiempo de recuperacion |
