.PHONY: help check inventory pki pki-demo-certs ldap ldap-hash ldap-config ldap-config-apply ldap-certs ldap-enable-ldaps ldap-enable-ldaps-listener ldap-load ldap-syncprov ldap-replication-consumer ldap-search ldap-backup kerberos kerberos-users kerberos-services kerberos-keytabs kerberos-host-keytabs kerberos-check-propagation kerberos-kinit kerberos-propagate kerberos-failover integration integration-users integration-map integration-auth web web-https web-kerberos ha ha-test ha-failover monitoring monitoring-start monitoring-check test test-run clean

LDAP_NODE ?= ldap1
LDAP_URI ?= ldap://localhost
KRB_USER ?= jperez
KDC_SECONDARY ?= kdc2.fis.epn.ec
INTEGRATION_LDAP_URI ?= ldap://ldap1.fis.epn.ec
LDAP_LB_URI ?= ldaps://ldap.fis.epn.edu.ec:1636
WEB_HOST ?= web.fis.epn.ec
WEB_URL ?= https://web.fis.epn.ec/

help:
	@echo "TorresJ-MiniIdM - Comandos disponibles"
	@echo ""
	@echo "  make check          Verifica la estructura basica y el entorno"
	@echo "  make inventory      Muestra el plan de nodos"
	@echo "  make pki            Ejecuta la fase PKI"
	@echo "  make ldap           Ejecuta la fase LDAP"
	@echo "  make kerberos       Ejecuta la fase Kerberos"
	@echo "  make integration    Ejecuta la fase de integracion LDAP-Kerberos"
	@echo "  make web            Ejecuta la fase web"
	@echo "  make ha             Ejecuta la fase de alta disponibilidad"
	@echo "  make monitoring     Ejecuta la fase de monitoreo"
	@echo "  make test           Ejecuta las pruebas"
	@echo "  make clean          Limpia los archivos temporales"
	@echo "  make pki-demo-certs Crea certificados de demostracion para servidores"
	@echo ""
	@echo "  make ldap-hash      Genera un hash SSHA LDAP"
	@echo "  make ldap-config    Muestra la configuracion base de slapd"
	@echo "  make ldap-config-apply Aplica la configuracion base de slapd"
	@echo "  make ldap-certs LDAP_NODE=ldap1 Copia los certificados LDAP"
	@echo "  make ldap-enable-ldaps LDAP_NODE=ldap1 Aplica TLS a LDAP"
	@echo "  make ldap-enable-ldaps-listener Habilita el listener ldaps:///"
	@echo "  make ldap-load      Carga el DIT LDAP"
	@echo "  make ldap-syncprov  Configura el proveedor ldap1"
	@echo "  make ldap-replication-consumer Configura el consumidor ldap2"
	@echo "  make ldap-search LDAP_URI=ldap://localhost Consulta LDAP"
	@echo "  make ldap-backup LDAP_URI=ldap://localhost Respalda LDAP"
	@echo "  make kerberos       Muestra el orden de despliegue de Kerberos"
	@echo "  make kerberos-users Crea principals de usuario"
	@echo "  make kerberos-services Crea principals de servicio"
	@echo "  make kerberos-keytabs Exporta keytabs de servicio"
	@echo "  make kerberos-host-keytabs Exporta keytabs de host"
	@echo "  make kerberos-check-propagation Revisa los requisitos de kprop"
	@echo "  make kerberos-kinit KRB_USER=jperez Prueba kinit"
	@echo "  make kerberos-propagate KDC_SECONDARY=kdc2.fis.epn.ec Propaga el KDC"
	@echo "  make kerberos-failover KRB_USER=jperez Prueba la conmutación por error del KDC"
	@echo "  make integration    Muestra las pruebas LDAP-Kerberos"
	@echo "  make integration-users Valida los usuarios LDAP"
	@echo "  make integration-map Valida el mapeo LDAP-Kerberos"
	@echo "  make integration-auth KRB_USER=jperez Prueba el flujo de autenticacion"
	@echo "  make web            Muestra el despliegue web con TLS y Kerberos"
	@echo "  make web-https WEB_HOST=web.fis.epn.ec Prueba TLS web"
	@echo "  make web-kerberos KRB_USER=jperez Prueba Kerberos web"
	@echo "  make ha             Muestra el despliegue de HAProxy para LDAP"
	@echo "  make ha-test LDAP_LB_URI=ldaps://ldap.fis.epn.edu.ec:1636 Prueba LDAP por el balanceador"
	@echo "  make ha-failover     Prueba la lectura despues de detener ldap1"
	@echo "  make monitoring     Muestra el despliegue de Prometheus"
	@echo "  make monitoring-start Configura Prometheus"
	@echo "  make monitoring-check Recolecta metricas basicas"
	@echo "  make test           Lista las pruebas de laboratorio"
	@echo "  make test-run       Ejecuta las pruebas automaticas en las VM"
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
	@bash pki/scripts/01-create-server-cert.sh ldap.fis.epn.edu.ec ldap
	@bash pki/scripts/01-create-server-cert.sh kdc1.fis.epn.ec kdc1
	@bash pki/scripts/01-create-server-cert.sh kdc2.fis.epn.ec kdc2
	@bash pki/scripts/01-create-server-cert.sh web.fis.epn.ec web

ldap:
	@echo "Orden LDAP recomendado:"
	@echo "  1. bash ldap/scripts/00-install-openldap.sh"
	@echo "  2. sudo make ldap-config-apply"
	@echo "  3. sudo make ldap-certs LDAP_NODE=ldap1"
	@echo "  4. sudo make ldap-enable-ldaps LDAP_NODE=ldap1"
	@echo "  5. sudo make ldap-enable-ldaps-listener"
	@echo "  6. Los hashes en ldap/ldif se reemplazan con make ldap-hash"
	@echo "  7. make ldap-load"
	@echo "  8. sudo make ldap-syncprov en ldap1"
	@echo "  9. sudo make ldap-replication-consumer en ldap2"
	@echo " 10. make ldap-search LDAP_URI=ldap://localhost"

ldap-hash:
	@bash ldap/scripts/00-generate-password-hash.sh

ldap-config:
	@bash ldap/scripts/01-configure-slapd.sh

ldap-config-apply:
	@bash ldap/scripts/01-configure-slapd.sh --apply

ldap-certs:
	@bash ldap/scripts/02-install-ldap-certificates.sh "$(LDAP_NODE)"

ldap-enable-ldaps:
	@bash ldap/scripts/03-enable-ldaps.sh "$(LDAP_NODE)"

ldap-enable-ldaps-listener:
	@bash ldap/scripts/10-enable-ldaps-listener.sh

ldap-load:
	@bash ldap/scripts/04-load-base-dit.sh

ldap-syncprov:
	@bash ldap/scripts/08-enable-syncprov.sh

ldap-replication-consumer:
	@bash ldap/scripts/09-enable-replication-consumer.sh

ldap-search:
	@bash ldap/scripts/05-test-ldap-search.sh "$(LDAP_URI)"

ldap-backup:
	@bash ldap/scripts/07-backup-ldap.sh "$(LDAP_URI)"

kerberos:
	@echo "Orden Kerberos recomendado:"
	@echo "  idm1: se instala, se inicializa el realm y se exportan los keytabs de host"
	@echo "  idm2: se instala, se copia idm2.keytab y el stash, y se configura kpropd"
	@echo "  kerberos/scripts/01-init-realm.sh no se ejecuta en idm2"
	@echo "  1. sudo make kerberos-check-propagation"
	@echo "  2. sudo make kerberos-propagate KDC_SECONDARY=kdc2.fis.epn.ec"
	@echo "  3. En idm2 se verifica la base y se inicia krb5-kdc"

kerberos-users:
	@bash kerberos/scripts/02-create-user-principals.sh

kerberos-services:
	@bash kerberos/scripts/03-create-service-principals.sh

kerberos-keytabs:
	@bash kerberos/scripts/04-export-keytabs.sh

kerberos-host-keytabs:
	@bash kerberos/scripts/09-export-host-keytabs.sh

kerberos-check-propagation:
	@bash kerberos/scripts/07-propagate-kdc-db.sh --check "$(KDC_SECONDARY)"

kerberos-kinit:
	@bash kerberos/scripts/05-test-kinit.sh "$(KRB_USER)"

kerberos-propagate:
	@bash kerberos/scripts/07-propagate-kdc-db.sh "$(KDC_SECONDARY)"

kerberos-failover:
	@bash kerberos/scripts/08-test-kdc-failover.sh "$(KRB_USER)"

integration:
	@echo "Pruebas de integracion LDAP Kerberos:"
	@echo "  make integration-users"
	@echo "  make integration-map"
	@echo "  make integration-auth KRB_USER=jperez"

integration-users:
	@bash integration/scripts/00-check-ldap-kerberos-users.sh "$(INTEGRATION_LDAP_URI)"

integration-map:
	@bash integration/scripts/01-map-users.sh "$(INTEGRATION_LDAP_URI)"

integration-auth:
	@bash integration/scripts/02-test-auth-flow.sh "$(KRB_USER)" "$(INTEGRATION_LDAP_URI)"

web:
	@echo "Despliegue web TLS Kerberos:"
	@echo "  1. sudo bash web/scripts/00-install-web-deps.sh"
	@echo "  2. sudo bash web/scripts/01-start-web.sh"
	@echo "  3. make web-https"
	@echo "  4. make web-kerberos KRB_USER=jperez"

web-https:
	@bash web/scripts/02-test-https.sh "$(WEB_HOST)"

web-kerberos:
	@bash web/scripts/03-test-kerberos-web.sh "$(KRB_USER)" "$(WEB_URL)"

ha:
	@echo "Despliegue HAProxy LDAP:"
	@echo "  1. sudo bash ha/scripts/00-install-haproxy.sh"
	@echo "  2. make pki-demo-certs"
	@echo "  3. sudo bash ha/scripts/01-configure-ldap-lb.sh"
	@echo "  4. make ha-test LDAP_LB_URI=ldaps://ldap.fis.epn.edu.ec:1636"
	@echo "  5. La prueba se ejecuta después de detener slapd en ldap1: make ha-failover"

ha-test:
	@bash ha/scripts/02-test-ldap-lb.sh "$(LDAP_LB_URI)"

ha-failover:
	@bash ha/scripts/03-test-ldap-failover.sh "$(LDAP_LB_URI)"

monitoring:
	@echo "Despliegue Prometheus:"
	@echo "  1. sudo bash monitoring/scripts/00-install-monitoring.sh"
	@echo "  2. sudo make monitoring-start"
	@echo "  3. sudo make monitoring-check"

monitoring-start:
	@bash monitoring/scripts/01-start-prometheus.sh

monitoring-check:
	@bash monitoring/scripts/02-check-services.sh

test:
	@bash scripts/03-run-all-tests.sh

test-run:
	@bash scripts/03-run-all-tests.sh run

clean:
	@bash scripts/02-cleanup-lab.sh
