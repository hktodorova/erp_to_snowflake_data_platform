use database ENTERPRISE_DWH;

create or replace view OBSERVABILITY.V_FAILED_TASKS as
select *
from table(information_schema.task_history())
where state = 'FAILED';

create or replace view OBSERVABILITY.V_LONG_RUNNING_QUERIES as
select
    query_id,
    user_name,
    warehouse_name,
    execution_status,
    total_elapsed_time / 1000 as elapsed_seconds,
    query_text,
    start_time
from table(information_schema.query_history())
where total_elapsed_time > 300000;

create or replace view OBSERVABILITY.V_WAREHOUSE_COST_SIGNALS as
select
    warehouse_name,
    date_trunc('day', start_time) as usage_day,
    sum(credits_used) as credits_used
from snowflake.account_usage.warehouse_metering_history
group by 1, 2;
