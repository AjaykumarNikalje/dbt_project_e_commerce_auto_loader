


with

scoped_bronze as (
    select *
    from `retail_analytics_poc_strm_tab`.`dbt_retail_streaming_poc`.`brz_customers` as bronze
    
)
-- Any rows returned are invalid and fail the test.
select *
from scoped_bronze
where
    -- Required fields and conversions used by Silver.
    try_cast(customer_id as int) is null
    or customer_name is null
    or email is null
    or country is null
    or segment is null
    or try_cast(signup_date as date) is null
    or try_cast(source_inserted_at as timestamp) is null
    or try_cast(source_updated_at as timestamp) is null
    or ingested_at is null
    or operation_type is null
    or source_file is null

    -- Allowed customer values.
    or segment not in ('STANDARD', 'PREMIUM')
    or operation_type not in ('INSERT', 'UPDATE', 'DELETE')