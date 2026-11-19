
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  


with

scoped_bronze as (
    select *
    from `retail_analytics_poc_strm_tab`.`dbt_retail_streaming_poc`.`brz_orders` as bronze
    
)
-- Any rows returned are invalid and fail the test.
select *
from scoped_bronze
where
    -- Required fields and conversions used by Silver.
    try_cast(order_id as int) is null
    or try_cast(customer_id as int) is null
    or try_cast(amount as decimal(18,2)) is null
    or status is null
    or try_cast(source_inserted_at as timestamp) is null
    or try_cast(source_updated_at as timestamp) is null
    or ingested_at is null
    or batch_id is null
    or operation_type is null
    or source_file is null

    -- Allowed order values.
    or status not in ('PLACED', 'COMPLETED', 'CANCELLED', 'REFUNDED')
    or operation_type not in ('INSERT', 'UPDATE')

    -- Allowed order amount.
    or try_cast(amount as decimal(18,2)) < 0
    or try_cast(amount as decimal(18,2)) > 100000
  
  
      
    ) dbt_internal_test