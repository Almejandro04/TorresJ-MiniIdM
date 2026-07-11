.PHONY: help check pki ldap kerberos integration web ha monitoring test clean

help:
	@echo "TorresJ-MiniIdM - Comandos disponibles"
	@echo ""
	@echo "  make check          Verificar estructura basica y entorno"
	@echo "  make pki            Ejecutar fase PKI"
	@echo "  make ldap           Ejecutar fase LDAP"
	@echo "  make kerberos       Ejecutar fase Kerberos"
	@echo "  make integration    Ejecutar fase Integracion LDAP-Kerberos"
	@echo "  make web            Ejecutar fase Web"
	@echo "  make ha             Ejecutar fase Alta Disponibilidad"
	@echo "  make monitoring     Ejecutar fase Monitoreo"
	@echo "  make test           Ejecutar pruebas"
	@echo "  make clean          Limpiar archivos temporales"
	@echo ""

check:
	@echo "Verificando estructura basica del proyecto..."
	@test -d docs
	@test -d pki
	@test -d ldap
	@test -d kerberos
	@test -d integration
	@test -d web
	@test -d ha
	@test -d monitoring
	@test -d tests
	@test -d results
	@test -d scripts
	@bash scripts/00-check-environment.sh
	@echo "Estructura basica correcta."

pki:
	@echo "TODO: implementar fase PKI."

ldap:
	@echo "TODO: implementar fase LDAP."

kerberos:
	@echo "TODO: implementar fase Kerberos."

integration:
	@echo "TODO: implementar fase Integracion LDAP-Kerberos."

web:
	@echo "TODO: implementar fase Web."

ha:
	@echo "TODO: implementar fase Alta Disponibilidad."

monitoring:
	@echo "TODO: implementar fase Monitoreo."

test:
	@bash scripts/03-run-all-tests.sh

clean:
	@bash scripts/02-cleanup-lab.sh