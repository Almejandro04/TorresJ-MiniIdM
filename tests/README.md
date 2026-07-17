# Pruebas

Las pruebas requieren las VM configuradas y nombres DNS resolubles. El conjunto
se lista primero con `bash tests/scripts/run-tests.sh`.

Las pruebas de fallos cambian servicios o reglas de iptables. Se ejecutan solo
en las VM de laboratorio y el estado se restaura despues de cada experimento.

## Evidencias

Los resultados se registran en `results/tables/` con fecha, nodo, metrica y
resultado.
