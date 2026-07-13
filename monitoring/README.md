# Monitoreo

El proyecto usa Prometheus y node exporter. Prometheus recolecta CPU y memoria desde node exporter en cada nodo.

El script `02-check-services.sh` genera metricas basicas de estado de servicios, consulta LDAP y puerto KDC en el directorio textfile de node exporter.

## Despliegue

En todos los nodos:

```text
sudo bash monitoring/scripts/00-install-monitoring.sh
```

En edge:

```text
sudo bash monitoring/scripts/01-start-prometheus.sh
```

En el nodo que ejecuta las comprobaciones:

```text
sudo bash monitoring/scripts/02-check-services.sh
```

Programar el ultimo comando con cron o systemd timer si se requiere recoleccion periodica.

## Metricas

```text
node_cpu_seconds_total
node_memory_MemAvailable_bytes
miniidm_service_up
miniidm_ldap_query_success
miniidm_ldap_query_latency_milliseconds
miniidm_kdc_port_up
```
