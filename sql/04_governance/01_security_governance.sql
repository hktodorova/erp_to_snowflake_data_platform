use database ENTERPRISE_DWH;
use schema GOVERNANCE;

create or replace masking policy GOVERNANCE.EMAIL_MASK as (val string) returns string ->
  case
    when current_role() in ('ROLE_DATA_PLATFORM_ADMIN', 'ROLE_AUDITOR') then val
    when val is null then null
    else regexp_replace(val, '(^.).*(@.*$)', '\\1***\\2')
  end;

create or replace masking policy GOVERNANCE.CUSTOMER_NAME_MASK as (val string) returns string ->
  case
    when current_role() in ('ROLE_DATA_PLATFORM_ADMIN', 'ROLE_AUDITOR') then val
    when val is null then null
    else concat(left(val, 1), '***')
  end;

create table if not exists GOVERNANCE.ROLE_COUNTRY_ACCESS (
    role_name string not null,
    country_code string not null,
    granted_at timestamp_ntz default current_timestamp()
);

merge into GOVERNANCE.ROLE_COUNTRY_ACCESS target
using (
    select 'ROLE_DATA_ANALYST_CH' as role_name, 'CH' as country_code union all
    select 'ROLE_DATA_ANALYST_DACH' as role_name, 'CH' as country_code union all
    select 'ROLE_DATA_ANALYST_DACH' as role_name, 'DE' as country_code union all
    select 'ROLE_DATA_ANALYST_DACH' as role_name, 'AT' as country_code
) source
on target.role_name = source.role_name
and target.country_code = source.country_code
when not matched then insert (role_name, country_code) values (source.role_name, source.country_code);

create or replace row access policy GOVERNANCE.COUNTRY_ACCESS_POLICY as (country_code string) returns boolean ->
  exists (
    select 1
    from GOVERNANCE.ROLE_COUNTRY_ACCESS a
    where a.role_name = current_role()
      and a.country_code = country_code
  )
  or current_role() in ('ROLE_DATA_PLATFORM_ADMIN', 'ROLE_AUDITOR');

-- Apply policies to concrete marts consumed by BI and ML.
alter table if exists MARTS.DIM_CUSTOMER
  modify column email set masking policy GOVERNANCE.EMAIL_MASK;

alter table if exists MARTS.DIM_CUSTOMER
  modify column customer_name set masking policy GOVERNANCE.CUSTOMER_NAME_MASK;

alter table if exists MARTS.DIM_CUSTOMER
  add row access policy GOVERNANCE.COUNTRY_ACCESS_POLICY on (country_code);

alter table if exists MARTS.FACT_REVENUE
  add row access policy GOVERNANCE.COUNTRY_ACCESS_POLICY on (country_code);

alter table if exists FEATURES.FEATURE_CUSTOMER_REVENUE_90D
  add row access policy GOVERNANCE.COUNTRY_ACCESS_POLICY on (country_code);
