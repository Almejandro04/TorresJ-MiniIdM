# Arquitectura

```text
                 +-------------------+
                 | cliente.fis.epn.ec|
                 +-------------------+
                   |      |      |
                   |      |      +--> HTTPS y Kerberos --> web.fis.epn.ec
                   |      |
                   |      +--> Kerberos --> kdc1 o kdc2
                   |
                   +--> LDAPS :1636 --> ldap.fis.epn.edu.ec
                                      |
                                      +--> ldap1 (principal)
                                      +--> ldap2 (respaldo)
```

`ldap1` funciona como maestro de escritura y `ldap2` como réplica de lectura.
HAProxy se ejecuta únicamente en idm1 y expone
`ldap.fis.epn.edu.ec:1636`; mantiene TLS hacia ambos servidores LDAP en el
puerto 636, utiliza `ldap1` como principal y activa `ldap2` mediante la marca
`backup` solo cuando el maestro deja de responder. Por ello, la conmutación por
error de LDAP conserva principalmente las consultas de lectura y no garantiza
alta disponibilidad de escritura ni una configuración multimaestro.

La implementación final se compone de dos VM físicas: idm1
(`192.168.56.10`) aloja la CA raíz ECDSA, ldap1, kdc1, Apache, HAProxy,
Prometheus y node exporter. idm2 (`192.168.56.11`) aloja ldap2, kdc2, el
cliente de pruebas y node exporter. Los nombres ldap1, ldap2, kdc1 y kdc2
corresponden a roles lógicos. `kdc1` funciona como KDC primario y `kdc2`
recibe la base de Kerberos propagada para emitir tickets ante un fallo de kdc1.

No se utilizan VIP, Keepalived, un tercer nodo, un segundo HAProxy ni un
segundo Apache. La pérdida completa de idm1 no está cubierta: la alta
disponibilidad se implementa en los servicios LDAP y Kerberos, no en toda la
VM.

La CA raíz firma los certificados de LDAP, KDC, web y el punto de acceso LDAP. LDAP
almacena los datos de identidad; Kerberos autentica a los usuarios y servicios.
