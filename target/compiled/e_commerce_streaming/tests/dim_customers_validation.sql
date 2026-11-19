

with customers as (
    select *,
        count(*) over (partition by customer_id) as customer_id_count,
        count(*) over (partition by email) as email_count
    from `retail_analytics_poc_strm_tab`.`dbt_retail_streaming_poc`.`dim_customers`
)
-- Any rows returned are invalid and fail the test.
select *
from customers
where
    -- Required dimension values.
    customer_id is null
    or customer_name is null
    or email is null
    or country is null
    or segment is null
    or signup_date is null
    or is_deleted is null
    or dim_ingested_time is null
    or dim_updated_time is null
    or slr_updated_at is null

    -- One current row per customer; emails must also be unique.
    or customer_id_count > 1
    or email_count > 1

    -- Allowed customer segments and processing timestamp order.
    or segment not in ('STANDARD', 'PREMIUM')
    or dim_updated_time < dim_ingested_time