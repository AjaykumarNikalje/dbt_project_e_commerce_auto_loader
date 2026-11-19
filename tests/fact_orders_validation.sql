{{ config(severity='error') }}

with orders as (
    select *,
        count(*) over (partition by order_id) as order_id_count
    from {{ ref('fact_orders') }}
)
-- Any rows returned are invalid and fail the test.
select *
from orders
where
    -- Required fact values.
    order_id is null
    or customer_id is null
    or amount is null
    or status is null
    or source_inserted_at is null
    or source_updated_at is null
    or slr_updated_at is null

    -- One current row per order.
    or order_id_count > 1

    -- Allowed order statuses and amount range.
    or status not in ('PLACED', 'COMPLETED', 'CANCELLED', 'REFUNDED')
    or amount < 0
    or amount > {{ var('max_order_amount') }}

    -- Every order must reference a customer in the Gold dimension.
    -- Soft-deleted customers remain valid relationship targets.
    or not exists (
        select 1
        from {{ ref('dim_customers') }} as customers
        where customers.customer_id = orders.customer_id
    )
