
    
    select
      count(*) as failures,
      count(*) != 0 as should_warn,
      count(*) != 0 as should_error
    from (
      
    
  

with orders as (
    select *,
        count(*) over (partition by order_id) as order_id_count
    from `retail_analytics_poc_strm_tab`.`dbt_retail_streaming_poc`.`slr_orders`
)
-- Any rows returned fail the test and block dependent Gold models.
select *
from orders
where
    -- Required Silver values.
    order_id is null
    or customer_id is null
    or amount is null
    or status is null
    or source_inserted_at is null
    or source_updated_at is null
    or brz_ingested_at is null
    or slr_ingested_at is null
    or slr_updated_at is null
    or batch_id is null
    or operation_type is null
    or source_file is null

    -- One current row per order.
    or order_id_count > 1

    -- Allowed order values and amount range.
    or status not in ('PLACED', 'COMPLETED', 'CANCELLED', 'REFUNDED')
    or operation_type not in ('INSERT', 'UPDATE')
    or amount < 0
    or amount > 100000

    -- Every order must reference a known customer, including soft-deleted ones.
    or not exists (
        select 1
        from `retail_analytics_poc_strm_tab`.`dbt_retail_streaming_poc`.`slr_customers` as customers
        where customers.customer_id = orders.customer_id
    )
  
  
      
    ) dbt_internal_test