provider "snowflake" {}

locals {
  schemas = ["RAW", "STAGING", "RAW_VAULT", "MARTS", "FEATURES", "GOVERNANCE", "OBSERVABILITY", "SNAPSHOTS"]

  warehouses = {
    WH_INGEST_XS = {
      size           = "XSMALL"
      min_cluster    = 1
      max_cluster    = 1
      statement_secs = 1800
    }
    WH_TRANSFORM_M = {
      size           = "MEDIUM"
      min_cluster    = 1
      max_cluster    = 2
      statement_secs = 3600
    }
    WH_ANALYTICS_S = {
      size           = "SMALL"
      min_cluster    = 1
      max_cluster    = 2
      statement_secs = 1800
    }
    WH_ML_M = {
      size           = "MEDIUM"
      min_cluster    = 1
      max_cluster    = 2
      statement_secs = 7200
    }
  }

  roles = {
    ROLE_DATA_PLATFORM_ADMIN = "Owns platform administration, release management and break-glass access"
    ROLE_DATA_ENGINEER       = "Loads immutable raw data and operates ingestion"
    ROLE_TRANSFORM           = "Owns dbt transformations and vault/mart builds"
    ROLE_ANALYST             = "Consumes curated marts and features"
    ROLE_DATA_ANALYST_CH     = "Consumes governed Swiss rows"
    ROLE_DATA_ANALYST_DACH   = "Consumes governed DACH rows"
    ROLE_AUDITOR             = "Audits access, lineage and observability views"
  }
}

resource "snowflake_database" "dwh" {
  name    = var.database_name
  comment = "${var.environment} enterprise data warehouse"
}

resource "snowflake_schema" "schemas" {
  for_each = toset(local.schemas)
  database = snowflake_database.dwh.name
  name     = each.value
  comment  = "${var.environment} ${each.value} schema"
}

resource "snowflake_warehouse" "warehouses" {
  for_each = local.warehouses

  name                                = each.key
  warehouse_size                      = each.value.size
  auto_suspend                        = var.warehouse_auto_suspend_seconds
  auto_resume                         = true
  initially_suspended                 = true
  min_cluster_count                   = each.value.min_cluster
  max_cluster_count                   = each.value.max_cluster
  scaling_policy                      = "ECONOMY"
  statement_timeout_in_seconds        = each.value.statement_secs
  statement_queued_timeout_in_seconds = 600
  comment                             = "${var.environment} workload-isolated warehouse"
}

resource "snowflake_account_role" "roles" {
  for_each = local.roles
  name     = each.key
  comment  = each.value
}

resource "snowflake_grant_privileges_to_account_role" "database_usage" {
  for_each          = snowflake_account_role.roles
  account_role_name = each.value.name
  privileges        = ["USAGE"]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.dwh.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "warehouse_usage" {
  for_each          = snowflake_warehouse.warehouses
  account_role_name = snowflake_account_role.roles[each.key == "WH_INGEST_XS" ? "ROLE_DATA_ENGINEER" : each.key == "WH_ANALYTICS_S" ? "ROLE_ANALYST" : each.key == "WH_ML_M" ? "ROLE_ANALYST" : "ROLE_TRANSFORM"].name
  privileges        = ["USAGE", "OPERATE"]

  on_account_object {
    object_type = "WAREHOUSE"
    object_name = each.value.name
  }
}

resource "snowflake_grant_privileges_to_account_role" "raw_loader_schema" {
  account_role_name = snowflake_account_role.roles["ROLE_DATA_ENGINEER"].name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE STAGE", "CREATE FILE FORMAT", "CREATE PIPE"]

  on_schema {
    schema_name = "${snowflake_database.dwh.name}.${snowflake_schema.schemas["RAW"].name}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "transform_schema_ownership" {
  for_each          = { for s in ["STAGING", "RAW_VAULT", "MARTS", "FEATURES", "SNAPSHOTS"] : s => s }
  account_role_name = snowflake_account_role.roles["ROLE_TRANSFORM"].name
  privileges        = ["USAGE", "CREATE TABLE", "CREATE VIEW", "CREATE DYNAMIC TABLE", "CREATE TASK"]

  on_schema {
    schema_name = "${snowflake_database.dwh.name}.${snowflake_schema.schemas[each.key].name}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "analyst_read_marts" {
  for_each          = { for s in ["MARTS", "FEATURES"] : s => s }
  account_role_name = snowflake_account_role.roles["ROLE_ANALYST"].name
  privileges        = ["USAGE"]

  on_schema {
    schema_name = "${snowflake_database.dwh.name}.${snowflake_schema.schemas[each.key].name}"
  }
}

resource "snowflake_grant_privileges_to_account_role" "analyst_future_select" {
  for_each          = { for s in ["MARTS", "FEATURES"] : s => s }
  account_role_name = snowflake_account_role.roles["ROLE_ANALYST"].name
  privileges        = ["SELECT"]

  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "${snowflake_database.dwh.name}.${snowflake_schema.schemas[each.key].name}"
    }
  }
}

resource "snowflake_masking_policy" "mask_email" {
  database         = snowflake_database.dwh.name
  schema           = snowflake_schema.schemas["GOVERNANCE"].name
  name             = "MASK_EMAIL"
  return_data_type = "STRING"
  body             = "case when current_role() in ('${snowflake_account_role.roles["ROLE_DATA_PLATFORM_ADMIN"].name}', '${snowflake_account_role.roles["ROLE_TRANSFORM"].name}') then val else regexp_replace(val, '(^.).*(@.*$)', '\\1***\\2') end"

  argument {
    name = "VAL"
    type = "STRING"
  }
}

resource "snowflake_row_access_policy" "regional_country_filter" {
  database    = snowflake_database.dwh.name
  schema      = snowflake_schema.schemas["GOVERNANCE"].name
  name        = "REGIONAL_COUNTRY_FILTER"
  body        = "current_role() in ('${snowflake_account_role.roles["ROLE_DATA_PLATFORM_ADMIN"].name}', '${snowflake_account_role.roles["ROLE_TRANSFORM"].name}') or country_code in (${join(",", [for c in var.analyst_countries : "'${c}'"])})"

  argument {
    name = "COUNTRY_CODE"
    type = "STRING"
  }
}
