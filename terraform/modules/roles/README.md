# Snowflake Role Module

This folder documents the intended module split for enterprise Terraform usage:

- service roles: loader, transformer, analyst, steward, auditor
- role hierarchy and grants
- future grants for schemas and governed objects

The root module remains runnable as a compact public portfolio example. In a production repository, move role resources from `terraform/main.tf` here and instantiate the module once per environment.
