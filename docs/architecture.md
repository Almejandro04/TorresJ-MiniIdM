# Architecture

```text
                 +-------------------+
                 | client.fis.epn.ec |
                 +-------------------+
                   |      |      |
                   |      |      +--> HTTPS and Kerberos --> web.fis.epn.ec
                   |      |
                   |      +--> Kerberos --> kdc1 or kdc2
                   |
                   +--> LDAPS :1636 --> ldap.fis.epn.edu.ec
                                      |
                                      +--> ldap1 (principal)
                                      +--> ldap2 (respaldo)
```

`ldap1` es el maestro de escritura y `ldap2` es la replica de lectura. HAProxy
se ejecuta solamente en idm1 y expone `ldap.fis.epn.edu.ec:1636`; mantiene TLS
hacia ambos backends en 636, usa `ldap1` como principal y activa `ldap2` con
la marca `backup` solo si el maestro deja de responder. Por ello el failover
LDAP mantiene principalmente consultas de lectura y no garantiza alta
disponibilidad de escritura ni una configuracion multimaster.

La implementacion final tiene dos VM fisicas: idm1 (`192.168.56.10`) aloja la
CA raiz ECDSA, ldap1, kdc1, Apache, HAProxy, Prometheus y node exporter. idm2
(`192.168.56.11`) aloja ldap2, kdc2, el cliente de pruebas y node exporter.
Los nombres ldap1, ldap2, kdc1 y kdc2 son roles logicos. `kdc1` es el KDC
primario y `kdc2` recibe la base Kerberos propagada para emitir tickets ante
un fallo de kdc1.

No existe VIP, Keepalived, un tercer nodo, un segundo HAProxy ni un segundo
Apache. La perdida completa de idm1 no esta cubierta: la alta disponibilidad
se implementa a nivel de los servicios LDAP y Kerberos, no de toda la VM.

The root CA signs certificates for LDAP, KDC, web and the LDAP frontend. LDAP stores identity data; Kerberos authenticates users and services.
