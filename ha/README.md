# Alta disponibilidad LDAP

HAProxy se ejecuta en idm1 y expone `ldap.fis.epn.edu.ec` en el puerto externo
`1636`. Termina TLS con el certificado del nombre virtual y conecta por TLS a
los backends `ldap1` (idm1) y `ldap2` (idm2), ambos en su puerto interno 636.
El puerto externo 636 solo es viable cuando HAProxy tiene un nodo o IP
independiente; en esta topologia lo utiliza slapd en idm1.

La implementacion final tiene dos VM: idm1 aloja ldap1, kdc1, HAProxy, Apache,
Prometheus y la CA; idm2 aloja ldap2, kdc2 y el cliente. No existe un nodo
edge.

## Despliegue

```text
make pki-demo-certs
sudo bash ha/scripts/00-install-haproxy.sh
sudo bash ha/scripts/01-configure-ldap-lb.sh
make ha-test LDAP_LB_URI=ldaps://ldap.fis.epn.edu.ec:1636
```

Para la prueba de failover, ejecutar `sudo systemctl stop slapd` en ldap1 y luego:

```text
make ha-failover LDAP_LB_URI=ldaps://ldap.fis.epn.edu.ec:1636
```

La operacion de escritura sigue dirigida al LDAP master. El balanceador solo ofrece lecturas disponibles por los dos backends.
