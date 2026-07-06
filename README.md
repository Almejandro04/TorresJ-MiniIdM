# miniIdM

Infraestructura de Identidad Segura para la FIS.

Proyecto final individual de Computacion Distribuida.

## Objetivo

Disenar, implementar y evaluar una infraestructura segura de autenticacion y servicios de directorio para la FIS, integrando LDAP, PKI, Kerberos, alta disponibilidad, balanceo, pruebas de fallos, monitoreo y evaluacion experimental.

## Arquitectura Resumida

El proyecto propone una infraestructura de identidad basada en los siguientes componentes:

- OpenLDAP como servicio de directorio principal.
- MIT Kerberos como sistema de autenticacion central.
- PKI con OpenSSL para certificados de LDAP, Kerberos y servicio web.
- LDAP sobre TLS/LDAPS para comunicaciones seguras.
- Replicacion LDAP entre un nodo principal y un nodo replica.
- Alta disponibilidad para Kerberos con KDC primario y secundario.
- Balanceo y failover para LDAP mediante HAProxy o NGINX.
- Servicio web simple protegido con TLS y autenticacion Kerberos.
- Monitoreo con Prometheus o Grafana.
- Pruebas experimentales de latencia, disponibilidad, recuperacion y rendimiento.

## Componentes Principales

### PKI

Contendra la configuracion base de OpenSSL, certificados, solicitudes CSR y scripts relacionados con la autoridad certificadora y certificados de servidor.

### LDAP

Contendra los archivos LDIF, configuraciones de OpenLDAP, configuracion TLS y configuracion de replicacion entre `ldap1` y `ldap2`.

### Kerberos

Contendra la configuracion del realm `FIS.EPN.EC`, principals de usuarios, principals de servicios, keytabs y configuracion de alta disponibilidad del KDC.

### Integracion LDAP-Kerberos

Contendra la relacion entre usuarios LDAP y principals Kerberos, ademas de pruebas de validacion de identidad y autenticacion.

### Web

Contendra una aplicacion web simple, configuracion TLS y configuracion de autenticacion Kerberos.

### Alta Disponibilidad

Contendra la configuracion de balanceo/failover para LDAP y pruebas de tolerancia a fallos.

### Monitoreo

Contendra configuraciones de Prometheus, Grafana, dashboards y scripts de recoleccion de metricas.

### Pruebas y Resultados

Contendra pruebas de LDAP, LDAPS, Kerberos, TLS, balanceo, fallos y archivos para registrar resultados experimentales.

## Datos Base del Proyecto

- Raiz DIT LDAP: `dc=fis,dc=epn,dc=ec`
- Realm Kerberos: `FIS.EPN.EC`
- Frontend LDAP: `ldap.fis.epn.edu.ec`
- Backends LDAP: `ldap1`, `ldap2`
- Usuarios objetivo: `jperez`, `malvan`, `dnoboa`
- Servicios objetivo: `ldap/server1`, `http/webserver`
- Algoritmo PKI esperado: ECDSA

## Orden Recomendado de Implementacion

1. Documentar arquitectura, topologia y plan DNS.
2. Definir inventario de nodos y roles.
3. Implementar PKI base con OpenSSL.
4. Configurar OpenLDAP y cargar la DIT inicial.
5. Habilitar TLS/LDAPS en LDAP.
6. Configurar MIT Kerberos y crear principals.
7. Integrar usuarios LDAP con autenticacion Kerberos.
8. Configurar servicio web protegido con TLS y Kerberos.
9. Implementar replicacion LDAP.
10. Configurar KDC secundario.
11. Implementar balanceo/failover para LDAP.
12. Agregar monitoreo.
13. Ejecutar pruebas de fallos y rendimiento.
14. Registrar resultados y redactar informe final.

## Uso del Makefile

El archivo `Makefile` se usara como punto de entrada para ejecutar tareas del proyecto. Los targets previstos son:

- `help`
- `check`
- `pki`
- `ldap`
- `kerberos`
- `integration`
- `web`
- `ha`
- `monitoring`
- `test`
- `clean`

Por ahora, el Makefile queda reservado para implementacion posterior.

## Estructura del Proyecto

```text
miniIdM/
|-- docs/
|-- inventory/
|-- pki/
|-- ldap/
|-- kerberos/
|-- integration/
|-- web/
|-- ha/
|-- monitoring/
|-- tests/
|-- results/
`-- scripts/
```

## Estado del Proyecto

- [x] Estructura inicial de carpetas creada.
- [x] Archivos base creados.
- [ ] Documentacion tecnica inicial.
- [ ] Configuracion PKI.
- [ ] Configuracion LDAP.
- [ ] Configuracion Kerberos.
- [ ] Integracion LDAP-Kerberos.
- [ ] Servicio web protegido.
- [ ] Alta disponibilidad.
- [ ] Monitoreo.
- [ ] Pruebas de fallos.
- [ ] Evaluacion experimental.
- [ ] Informe final.

## Nota Sobre Seguridad

Este repositorio no debe incluir claves privadas reales, certificados generados, passwords, keytabs reales, archivos `.env` ni respaldos sensibles.

## Nota Sobre Ayuda Externa

La estructura inicial del proyecto fue preparada con apoyo de una herramienta de asistencia tecnica. La implementacion, pruebas, analisis y conclusiones deberan ser revisadas, ejecutadas y documentadas por el autor del proyecto.
