# Credential Rotation Runbook

1. Create or rotate the Snowflake service user key pair.
2. Update the private key in the secret manager.
3. Deploy the Airflow/GitHub secret update.
4. Run `dbt parse`, `dbt debug` and a limited `dbt build --select state:modified+`.
5. Disable the old public key after successful validation.
6. Review `SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY` for unexpected authentication attempts.

Never rotate by committing `.env` files, private keys or passwords.
