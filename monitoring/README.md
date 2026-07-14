# Monitoreo

El proyecto usa Prometheus y node exporter. La implementacion final usa dos VM
fisicas: idm1 (`192.168.56.10`) aloja CA, ldap1, kdc1, HAProxy, Apache y
Prometheus; idm2 (`192.168.56.11`) aloja ldap2, kdc2 y el cliente. Los nombres
logicos ldap1/kdc1 apuntan a idm1 y ldap2/kdc2 a idm2; no existe un nodo edge.

Prometheus recolecta CPU y memoria desde node exporter en ambas IP fisicas, no
una vez por cada rol logico.

El script `02-check-services.sh` genera metricas basicas de estado de servicios, consulta LDAP y puerto KDC en el directorio textfile de node exporter.

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

Programar el ultimo comando con cron o systemd timer si se requiere recoleccion periodica.

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
