# Alta disponibilidad LDAP

HAProxy expone `ldap.fis.epn.edu.ec` en el puerto 636. Termina TLS con el certificado del nombre virtual y conecta por TLS a `ldap1` y `ldap2`.

## Despliegue

```text
make pki-demo-certs
sudo bash ha/scripts/00-install-haproxy.sh
sudo bash ha/scripts/01-configure-ldap-lb.sh
make ha-test
```

Para la prueba de failover, ejecutar `sudo systemctl stop slapd` en ldap1 y luego:

```text
make ha-failover
```

La operacion de escritura sigue dirigida al LDAP master. El balanceador solo ofrece lecturas disponibles por los dos backends.
