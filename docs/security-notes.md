# Security notes

Generated private keys, certificates, CSR files, CA state, keytabs and raw results must not be uploaded to Git.

If generated artifacts were tracked before `.gitignore` was added, remove them from the Git index without deleting the local files. Rotate the affected keys in a real environment.

For the academic laboratory, regenerate local PKI artifacts with:

```text
make pki
make pki-demo-certs
```

Do not commit passwords, password hashes, private keys or keytabs.
