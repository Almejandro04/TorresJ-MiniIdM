# Pruebas

Las pruebas requieren las VM configuradas y nombres DNS resolubles. Ejecutar primero `bash tests/scripts/run-tests.sh` para listar el conjunto.

Las pruebas de fallos cambian servicios o reglas iptables. Ejecutarlas solo en las VM de laboratorio y restaurar el estado despues de cada experimento.

## Evidencias

Registrar los resultados en `results/tables/` con fecha, nodo, metrica y resultado.
