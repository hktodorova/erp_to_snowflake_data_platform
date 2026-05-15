use database ENTERPRISE_DWH;

create or replace dynamic table MARTS.DT_CUSTOMER_REVENUE_DAILY
  target_lag = '30 minutes'
  warehouse = WH_TRANSFORM_M
as
select
    payload:customer_id::string as customer_id,
    payload:order_date::date as order_date,
    count(*) as order_count,
    sum(payload:net_amount::number(18,2)) as net_revenue
from RAW.RAW_ERP_ORDERS
where payload:status::string in ('invoiced', 'shipped')
group by 1, 2;
