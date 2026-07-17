# Notas de seguridad

Las claves privadas generadas, los certificados, los archivos CSR, el estado
de la CA, los keytabs y los resultados crudos no se suben a Git.

Si los artefactos generados se hubieran incluido antes de agregar
`.gitignore`, se retiran del índice de Git sin borrar los archivos locales. En
un entorno real, las claves afectadas se rotan.

En el laboratorio académico, los artefactos PKI locales se regeneran con:

```text
make pki
make pki-demo-certs
```

Las contraseñas, los hashes de contraseña, las claves privadas y los keytabs
no se versionan.
