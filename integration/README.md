# Integracion LDAP Kerberos

LDAP mantiene la identidad y Kerberos realiza la autenticacion. El UID LDAP y el nombre de principal Kerberos deben coincidir.

## Comandos

```text
bash integration/scripts/00-check-ldap-kerberos-users.sh ldap://ldap1.fis.epn.ec
sudo bash integration/scripts/01-map-users.sh ldap://ldap1.fis.epn.ec
bash integration/scripts/02-test-auth-flow.sh jperez ldap://ldap1.fis.epn.ec
```

Los scripts no guardan contrasenas. `kinit` solicita la contrasena de forma interactiva.
