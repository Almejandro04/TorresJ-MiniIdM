# Resultados de pruebas

Pruebas reales ejecutadas el 14 de julio de 2026.

## LDAP sin TLS

| Medida | Resultado |
|---|---:|
| Promedio | 115.00 ms |
| Minimo | 100 ms |
| Maximo | 170 ms |
| Mediana | 110 ms |

## LDAPS

| Medida | Resultado |
|---|---:|
| Promedio | 237.00 ms |
| Minimo | 110 ms |
| Maximo | 680 ms |
| Mediana | 140 ms |

## Diferencia observada LDAP vs LDAPS

| Medida | Resultado |
|---|---:|
| Diferencia promedio | 122.00 ms |
| Diferencia porcentual | 106.09 % |

Diferencia de latencia total observada entre consultas LDAP y LDAPS. No se
interpreta como tiempo puro del establecimiento TLS.

## Rendimiento de HAProxy

| Medida | Resultado |
|---|---:|
| Solicitudes | 100 |
| Concurrencia | 5 |
| Rendimiento | 41.84 solicitudes por segundo |
| Latencia promedio | 112.60 ms |
| Exitosas | 100 |
| Fallidas | 0 |

## Replicacion LDAP

Valores observados: 130 ms, 140 ms, 420 ms, 120 ms y 500 ms.

| Medida | Resultado |
|---|---:|
| Pruebas exitosas | 5 de 5 |
| Promedio | 262 ms |
| Minimo | 120 ms |
| Maximo | 500 ms |
| Mediana | 140 ms |

Retardo extremo a extremo observado.

## Conmutación por error de LDAP

| Medida | Resultado |
|---|---:|
| Primera respuesta exitosa después de detener el maestro | 6560 ms |
| Tiempo de restauración | 50 ms |
| Resultado | correcto |

El valor de 6560 ms corresponde al tiempo hasta obtener la primera respuesta
LDAP exitosa después de detener `ldap1`. Esta medición incluye el tiempo que
HAProxy necesita para detectar la caída del servidor principal y activar
`ldap2` como servidor de respaldo. No representa el tiempo de estabilidad
total del balanceador.

## Conmutación por error de Kerberos

| Medida | Resultado |
|---|---:|
| Linea base | 140 ms |
| KDC de linea base | 192.168.56.10 |
| Conmutación por error | 160 ms |
| KDC secundario utilizado | 192.168.56.11 |
| Sobrecarga observada | 20 ms |
| Resultado | correcto |

## Caída de Apache mediante kill -9

| Medida | Resultado |
|---|---:|
| PID anterior | 1331 |
| PID nuevo | 5394 |
| Tiempo de recuperacion funcional | 410 ms |
| Resultado | correcto |

systemd reinicio Apache con un PID diferente y el servicio volvio a responder.

## Particion de red LDAP

| Medida | Resultado |
|---|---|
| Trafico bloqueado | Entre idm1 y 192.168.56.11:636 |
| Duracion de la particion | 10 segundos |
| LDAP directo antes del bloqueo | disponible |
| LDAP directo durante el bloqueo | no disponible |
| LDAP directo despues del bloqueo | recuperado |
| HAProxy | continuo respondiendo |
| Resultado | correcto |

## Certificado invalido

- Apache cargo temporalmente un certificado compatible con la clave instalada.
- El certificado era autofirmado.
- curl lo rechazo con error 60.
- Resultado: expected_tls_failure.
- El certificado original se restauro correctamente.
- Apache quedo activo.
