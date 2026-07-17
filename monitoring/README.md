# Monitoreo

El proyecto usa Prometheus y node exporter. La implementacion final usa dos VM
fisicas: idm1 (`192.168.56.10`) aloja CA ECDSA, ldap1, kdc1, HAProxy, Apache,
Prometheus y node exporter; idm2 (`192.168.56.11`) aloja ldap2, kdc2, el
cliente y node exporter. Los nombres logicos ldap1/kdc1 apuntan a idm1 y
ldap2/kdc2 a idm2.

Prometheus se ejecuta solo en idm1. No existen VIP, Keepalived, un tercer
nodo, un segundo HAProxy ni un segundo Apache; la perdida completa de idm1 no
esta cubierta. La alta disponibilidad se limita a LDAP y Kerberos.

Prometheus recolecta CPU y memoria desde node exporter en ambas IP fisicas, no
una vez por cada rol logico.

El script `02-check-services.sh` genera metricas basicas del estado de los
servicios, de la consulta LDAP y del puerto KDC en el directorio de archivos de
texto de node exporter.

## Despliegue

En todos los nodos:

```text
sudo bash monitoring/scripts/00-install-monitoring.sh
```

En idm1:

```text
sudo bash monitoring/scripts/01-start-prometheus.sh
```

En el nodo que ejecuta las comprobaciones:

```text
sudo bash monitoring/scripts/02-check-services.sh
```

El ultimo comando se programa con cron o un temporizador de systemd si se
requiere recoleccion periodica.

La consulta LDAP usa `LDAP_URI` (por defecto `ldap://ldap1.fis.epn.ec`) y un
reloj monotono de `/proc/uptime`. Puede ajustarse el limite con
`LDAP_TIMEOUT_SECONDS` (por defecto `2`); al expirar, la metrica de exito es
`0` y la latencia se registra como el limite configurado. `KDC_HOST` conserva
el valor por defecto `kdc1.fis.epn.ec` y tambien puede sobrescribirse.

## Metricas

```text
node_cpu_seconds_total
node_memory_MemAvailable_bytes
miniidm_service_up
miniidm_ldap_query_success
miniidm_ldap_query_latency_milliseconds
miniidm_kdc_port_up
```
