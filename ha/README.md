# Alta disponibilidad LDAP

HAProxy se ejecuta en idm1 y expone `ldap.fis.epn.edu.ec` en el puerto externo
`1636`. Termina TLS con el certificado del nombre virtual y conecta por TLS a
los servidores LDAP `ldap1` (idm1) y `ldap2` (idm2), ambos en su puerto
interno 636.
El puerto externo 636 solo es viable cuando HAProxy tiene un nodo o IP
independiente; en esta topologia lo utiliza slapd en idm1.

La implementacion final tiene dos VM: idm1 (`192.168.56.10`) aloja la CA
ECDSA, ldap1, kdc1, HAProxy, Apache, Prometheus y node exporter; idm2
(`192.168.56.11`) aloja ldap2, kdc2, el cliente y node exporter. ldap1,
ldap2, kdc1 y kdc2 son roles logicos.

HAProxy envia las conexiones a ldap1 en condiciones normales. ldap2 esta
configurado como `backup`, por lo que solo recibe conexiones cuando ldap1 deja
de responder. La conmutacion por error conserva principalmente consultas de lectura: ldap1
sigue siendo el unico maestro de escritura y no hay LDAP multimaster ni alta
disponibilidad de escritura.

No existen VIP, Keepalived, un tercer nodo, un segundo HAProxy ni un segundo
Apache. La perdida completa de idm1 no esta cubierta.

## Despliegue

```text
make pki-demo-certs
sudo bash ha/scripts/00-install-haproxy.sh
sudo bash ha/scripts/01-configure-ldap-lb.sh
make ha-test LDAP_LB_URI=ldaps://ldap.fis.epn.edu.ec:1636
```

Para la prueba controlada de conmutacion por error desde idm1, se utiliza el
script protegido por `--apply`; este detiene y restaura slapd mediante un
`trap`:

```text
sudo bash fault-tests/test-ldap-failover.sh --apply
```

La metrica registrada es el tiempo hasta la primera respuesta LDAP exitosa
despues de detener ldap1; no representa por si sola la estabilidad total del
balanceador.
