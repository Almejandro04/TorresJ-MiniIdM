# Flujo LDAP Kerberos

LDAP almacena la identidad, perfil, grupos, home, shell y correo. Kerberos almacena la credencial de autenticacion y entrega tickets.

```text
Cliente -> LDAP: consulta uid y perfil
Cliente -> KDC: kinit usuario@FIS.EPN.EC
KDC -> Cliente: TGT Kerberos
Cliente -> Servicio: ticket de servicio
```

Cada usuario LDAP debe tener el mismo identificador que la parte izquierda de su principal Kerberos.

```text
uid=jperez,ou=users,dc=fis,dc=epn,dc=ec -> jperez@FIS.EPN.EC
uid=malvan,ou=users,dc=fis,dc=epn,dc=ec -> malvan@FIS.EPN.EC
uid=dnoboa,ou=users,dc=fis,dc=epn,dc=ec -> dnoboa@FIS.EPN.EC
```

Esta base no sincroniza contrasenas entre LDAP y Kerberos. Las contrasenas se gestionan por Kerberos y los hashes LDAP son solo atributos de la plantilla del directorio.
