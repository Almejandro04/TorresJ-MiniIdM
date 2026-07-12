.PHONY: help check inventory pki pki-demo-certs ldap kerberos integration web ha monitoring test clean

help:
	@echo "TorresJ-MiniIdM - Comandos disponibles"
	@echo ""
	@echo "  make check          Verificar estructura basica y entorno"
	@echo "  make inventory      Mostrar plan de nodos"
	@echo "  make pki            Ejecutar fase PKI"
	@echo "  make ldap           Ejecutar fase LDAP"
	@echo "  make kerberos       Ejecutar fase Kerberos"
	@echo "  make integration    Ejecutar fase Integracion LDAP-Kerberos"
	@echo "  make web            Ejecutar fase Web"
	@echo "  make ha             Ejecutar fase Alta Disponibilidad"
	@echo "  make monitoring     Ejecutar fase Monitoreo"
	@echo "  make test           Ejecutar pruebas"
	@echo "  make clean          Limpiar archivos temporales"
	@echo "  make pki-demo-certs Crear certificados demo de servidores"
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
	@test -d inventory
	@bash scripts/00-check-environment.sh
	@echo "Estructura basica correcta."

inventory:
	@echo "Plan de nodos:"
	@echo ""
	@cat inventory/topology.md

pki:
	@bash pki/scripts/00-init-ca.sh

pki-demo-certs:
	@bash pki/scripts/01-create-server-cert.sh ldap1.fis.epn.ec ldap1
	@bash pki/scripts/01-create-server-cert.sh ldap2.fis.epn.ec ldap2
	@bash pki/scripts/01-create-server-cert.sh kdc1.fis.epn.ec kdc1
	@bash pki/scripts/01-create-server-cert.sh kdc2.fis.epn.ec kdc2
	@bash pki/scripts/01-create-server-cert.sh web.fis.epn.ec web

ldap:
	@echo "  bash ldap/scripts/00-install-openldap.sh"
	@echo "  bash ldap/scripts/01-load-base-dit.sh"
	@echo "  bash ldap/scripts/02-enable-ldaps.sh ldap1"
	@echo "  bash ldap/scripts/03-test-ldap-search.sh ldap://localhost"
	@echo "  bash ldap/scripts/04-test-replication.sh"
	@echo "  bash ldap/scripts/05-backup-ldap.sh ldap://localhost"

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