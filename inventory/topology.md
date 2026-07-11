# Topologia del laboratorio MiniIdM

## Objetivo

Documentar la distribucion logica de los servicios del proyecto.

La topologia exacta puede implementarse con dos, tres o cuatro maquinas virtuales. La decision final se tomara segun recursos disponibles y facilidad de pruebas.

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

## Opcion A: cuatro nodos logicos

| Nodo | IP sugerida | Rol |
|---|---|---|
| idm1 | 192.168.56.10 | CA, LDAP Master, KDC Primario |
| idm2 | 192.168.56.11 | LDAP Replica, KDC Secundario |
| edge | 192.168.56.12 | Balanceador, Web, Monitoreo |
| client | 192.168.56.13 | Cliente de pruebas |

## Opcion B: dos maquinas virtuales

| Nodo | IP sugerida | Rol |
|---|---|---|
| idm1 | 192.168.56.10 | CA, LDAP Master, KDC Primario, Balanceador, Web |
| idm2 | 192.168.56.11 | LDAP Replica, KDC Secundario, Cliente de pruebas |

## Ventajas de la opcion A

- Separacion mas clara de responsabilidades.
- Mejor demostracion de alta disponibilidad.
- Permite probar fallos de servicios sin mezclar tantos roles.
- Mas facil de explicar en el informe.

## Ventajas de la opcion B

- Menor consumo de RAM y CPU.
- Menos maquinas para administrar.
- Mas rapida para una implementacion individual.
- Suficiente para una version academica funcional.

## Decision inicial

La implementacion empezara sin fijar una cantidad definitiva de maquinas.

Primero se prepararan scripts, configuraciones y pruebas. Luego se desplegara en maquinas virtuales.

La opcion recomendada para iniciar es:

```text
idm1: CA, LDAP Master, KDC Primario
idm2: LDAP Replica, KDC Secundario
```

Luego se evaluara si conviene separar `edge` y `client` en maquinas adicionales.

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