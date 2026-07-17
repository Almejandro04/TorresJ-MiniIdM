# TorresJ-MiniIdM

Infraestructura de identidad segura para el proyecto de Sistemas Distribuidos
de FIS. Integra OpenLDAP, MIT Kerberos, una PKI ECDSA, Apache con TLS y
Kerberos, HAProxy, Prometheus y pruebas funcionales y de fallos.

## Servicios y nombres

| Elemento | Valor |
|---|---|
| Base DN de LDAP | `dc=fis,dc=epn,dc=ec` |
| Realm de Kerberos | `FIS.EPN.EC` |
| Punto de acceso LDAP | `ldap.fis.epn.edu.ec:1636` |
| Servicio web | `https://web.fis.epn.ec/` |
| KDC primario y secundario | `kdc1.fis.epn.ec` y `kdc2.fis.epn.ec` |

## Topologia final

La implementacion usa dos VM. Los nombres `ldap1`, `ldap2`, `kdc1` y `kdc2`
son roles logicos que resuelven a la VM indicada.

| VM | IP | Roles |
|---|---|---|
| `idm1` | `192.168.56.10` | CA raiz ECDSA, ldap1, kdc1, Apache, HAProxy, Prometheus y node exporter |
| `idm2` | `192.168.56.11` | ldap2, kdc2, cliente de pruebas y node exporter |

LDAP usa `ldap1` como maestro de escritura y `ldap2` como replica. HAProxy
atiende en el puerto externo `1636`, utiliza `ldap1` normalmente y activa
`ldap2` como respaldo para consultas de lectura. Kerberos puede emitir tickets
desde `kdc2` cuando `kdc1` no esta disponible.

No hay VIP, Keepalived, un tercer nodo, un segundo HAProxy ni un segundo
Apache. Por tanto, la perdida completa de `idm1` no esta cubierta y no existe
alta disponibilidad de escritura LDAP.

## Antes de desplegar

Se requiere Ubuntu Server 26.04 en las dos VM, acceso `root` o `sudo`, los
nombres del laboratorio resueltos y conectividad entre los nodos. El plan de
DNS y las entradas de `/etc/hosts` estan en
[inventory/](inventory/). Los comandos que instalan o modifican servicios se
ejecutan en la VM correspondiente con privilegios de administrador.

Para revisar el repositorio y conocer los objetivos disponibles:

```bash
make check
make inventory
make help
make test
```

`make ldap`, `make kerberos`, `make integration`, `make web`, `make ha` y
`make monitoring` muestran el orden recomendado; no despliegan por si solos
los servicios. El procedimiento completo, separado por VM y con el orden
correcto de los componentes, esta en [docs/deployment.md](docs/deployment.md).

Puntos importantes del despliegue:

- El DIT se carga y `syncprov` se configura en `idm1` antes de configurar el
  consumidor de replicación en `idm2`.
- `kerberos/scripts/01-init-realm.sh` se ejecuta solamente en `idm1`.
- El keytab y el *stash* requeridos se copian de forma segura a `idm2`; la
  base del KDC secundario llega mediante `kprop`.
- Los hashes LDAP se generan localmente cuando el script los solicita; los
  marcadores `REPLACE_WITH_*` del repositorio no contienen secretos reales.

## Estructura del repositorio

```text
docs/        Arquitectura, despliegue, seguridad, plan de pruebas y evidencias
inventory/   Topologia, DNS y ejemplo de /etc/hosts
pki/         CA OpenSSL ECDSA y certificados de servidor
ldap/        DIT, TLS, replicacion y scripts OpenLDAP
kerberos/    Realm, principals, keytabs y propagacion del KDC
integration/ Validaciones entre usuarios LDAP y principals Kerberos
web/         Apache con TLS y mod_auth_gssapi
ha/          HAProxy para el punto de acceso LDAP
monitoring/  Prometheus, node exporter y metricas propias
tests/       Pruebas funcionales y de inyeccion de fallos
fault-tests/ Experimentos controlados que alteran servicios o red
results/     Evidencia de las mediciones y material para el informe
```

## Validacion y resultados

Las pruebas automaticas se ejecutan solo cuando las VM ya estan configuradas:

```bash
make test-run
```

Incluyen consultas LDAP/LDAPS, autenticacion Kerberos, tickets de servicio,
TLS web y HAProxy. Las pruebas de fallos pueden detener servicios o insertar
reglas de `iptables`; deben ejecutarse exclusivamente en el laboratorio y con
el mecanismo `--apply` cuando el script lo requiera. Los detalles se
encuentran en [tests/README.md](tests/README.md) y
[fault-tests/README.md](fault-tests/README.md).

Las mediciones finales ejecutadas el 14 de julio de 2026 se resumen en
[RESULTADOS.md](RESULTADOS.md).

## Seguridad

No se versionan claves privadas, certificados generados, CSR, estado de la
CA, contrasenas, hashes reales, keytabs, *stash* de Kerberos ni resultados
crudos. Si alguno de estos elementos se hubiese publicado, hay que retirarlo
del indice de Git y rotarlo antes de compartir el repositorio.

Para el KDC secundario, tanto los alias `kdc1`/`kdc2` como los nombres reales
`idm1`/`idm2` requieren principals de host. La propagacion usa un dump
protegido de `kdb5_util` y `kprop`; nunca se debe inicializar un realm nuevo en
`idm2`. El detalle operativo esta en [kerberos/README.md](kerberos/README.md).

## Documentacion complementaria

- [Arquitectura](docs/architecture.md)
- [Despliegue](docs/deployment.md)
- [Notas de seguridad](docs/security-notes.md)
- [Plan de pruebas](docs/testing-plan.md)
- [Esquema del informe](docs/report-outline.md)
- [Evidencias de ejecucion](docs/evidence/README.md)
