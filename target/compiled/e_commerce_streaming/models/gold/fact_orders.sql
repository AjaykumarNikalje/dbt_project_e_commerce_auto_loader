


select
    incoming.order_id,
    incoming.customer_id,
    incoming.amount,
    incoming.status,
    incoming.source_inserted_at,
    incoming.source_updated_at,
    incoming.slr_updated_at
from `retail_analytics_poc_strm_tab`.`dbt_retail_streaming_poc`.`slr_orders` as incoming

left join `retail_analytics_poc_strm_tab`.`dbt_retail_streaming_poc`.`fact_orders` as existing
    on incoming.order_id = existing.order_id
where existing.order_id is null
   or incoming.slr_updated_at > existing.slr_updated_at
