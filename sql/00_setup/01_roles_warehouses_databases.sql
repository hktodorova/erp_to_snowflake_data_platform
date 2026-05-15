use role securityadmin;

create role if not exists ROLE_DATA_PLATFORM_ADMIN;
create role if not exists ROLE_DATA_ENGINEER;
create role if not exists ROLE_TRANSFORM;
create role if not exists ROLE_ANALYST;
create role if not exists ROLE_DATA_ANALYST_CH;
create role if not exists ROLE_DATA_ANALYST_DACH;
create role if not exists ROLE_AUDITOR;

use role sysadmin;

create database if not exists ENTERPRISE_DWH;
create schema if not exists ENTERPRISE_DWH.RAW;
create schema if not exists ENTERPRISE_DWH.STAGING;
create schema if not exists ENTERPRISE_DWH.RAW_VAULT;
create schema if not exists ENTERPRISE_DWH.MARTS;
create schema if not exists ENTERPRISE_DWH.FEATURES;
create schema if not exists ENTERPRISE_DWH.GOVERNANCE;
create schema if not exists ENTERPRISE_DWH.OBSERVABILITY;
create schema if not exists ENTERPRISE_DWH.SNAPSHOTS;

create warehouse if not exists WH_INGEST_XS
  warehouse_size = 'XSMALL'
  auto_suspend = 60
  auto_resume = true
  initially_suspended = true;

create warehouse if not exists WH_TRANSFORM_M
  warehouse_size = 'MEDIUM'
  auto_suspend = 120
  auto_resume = true
  initially_suspended = true;

create warehouse if not exists WH_ANALYTICS_S
  warehouse_size = 'SMALL'
  auto_suspend = 60
  auto_resume = true
  initially_suspended = true;

create warehouse if not exists WH_ML_M
  warehouse_size = 'MEDIUM'
  auto_suspend = 300
  auto_resume = true
  initially_suspended = true;
