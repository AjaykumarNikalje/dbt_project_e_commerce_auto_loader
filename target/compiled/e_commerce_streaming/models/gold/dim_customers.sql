


select
    incoming.customer_id,
    incoming.customer_name,
    incoming.email,
    incoming.country,
    incoming.segment,
    incoming.signup_date,
    incoming.is_deleted,
    incoming.slr_updated_at,
    current_timestamp() as dim_ingested_time,
    current_timestamp() as dim_updated_time
from `retail_analytics_poc_strm_tab`.`dbt_retail_streaming_poc`.`slr_customers` as incoming

left join `retail_analytics_poc_strm_tab`.`dbt_retail_streaming_poc`.`dim_customers` as existing
    on incoming.customer_id = existing.customer_id
where existing.customer_id is null
   or incoming.slr_updated_at > existing.slr_updated_at
