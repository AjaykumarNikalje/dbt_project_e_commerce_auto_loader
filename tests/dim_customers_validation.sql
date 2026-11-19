{{ config(severity='error') }}

with customers as (
    select *,
        customer_name = concat('Unknown_Customer_', cast(customer_id as string)) as is_placeholder,
        count(*) over (partition by customer_id) as customer_id_count,
        count(*) over (partition by email) as email_count
    from {{ ref('dim_customers') }}
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
    or (segment not in ('STANDARD', 'PREMIUM') and not is_placeholder)
    or dim_updated_time < dim_ingested_time

    -- Placeholder values remain explicit until actual customer data arrives.
    or (is_placeholder and (
        segment <> 'UNKNOWN'
        or country <> 'UNKNOWN'
        or email <> concat('unknown_customer_', cast(customer_id as string), '@placeholder.invalid')
        or signup_date <> cast('1900-01-01' as date)
        or is_deleted <> false
    ))
