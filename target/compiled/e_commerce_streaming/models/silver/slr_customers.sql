

with

typed as (
    select
        try_cast(customer_id as int) as customer_id,
        customer_name, email, country, segment,
        try_cast(signup_date as date) as signup_date,
        operation_type = 'DELETE' as is_deleted,
        try_cast(source_inserted_at as timestamp) as source_inserted_at,
        try_cast(source_updated_at as timestamp) as source_updated_at,
        ingested_at as brz_ingested_at,
        current_timestamp() as slr_ingested_at,
        current_timestamp() as slr_updated_at,
        batch_id, operation_type, source_file
    from `retail_analytics_poc_strm_tab`.`dbt_retail_streaming_poc`.`brz_customers` as bronze
    
),
ranked as (
    select *,
        row_number() over (
            partition by customer_id
            order by source_updated_at desc, brz_ingested_at desc, source_file desc
        ) as row_num
    from typed
)
select
    incoming.customer_id,
    incoming.customer_name,
    incoming.email,
    incoming.country,
    incoming.segment,
    incoming.is_deleted,
    incoming.signup_date,
    incoming.source_inserted_at,
    incoming.source_updated_at,
    incoming.brz_ingested_at,
    incoming.slr_ingested_at,
    incoming.slr_updated_at,
    incoming.batch_id,
    incoming.operation_type,
    incoming.source_file
from ranked as incoming

left join `retail_analytics_poc_strm_tab`.`dbt_retail_streaming_poc`.`slr_customers` as existing
    on incoming.customer_id = existing.customer_id

where incoming.row_num = 1

  and (existing.customer_id is null
       or incoming.source_updated_at > existing.source_updated_at)
