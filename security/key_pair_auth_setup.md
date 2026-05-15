# Snowflake Key-Pair Authentication

Use key-pair authentication for service users instead of passwords.

```bash
openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out rsa_key.p8 -nocrypt
openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub
```

Set the public key on a dedicated service user:

```sql
ALTER USER SVC_ERP_DBT SET RSA_PUBLIC_KEY = '<public_key_without_header_footer>';
```

Store the private key in GitHub Actions secrets, Airflow secrets backend, AWS Secrets Manager, Azure Key Vault, or HashiCorp Vault. Do not commit the key.
