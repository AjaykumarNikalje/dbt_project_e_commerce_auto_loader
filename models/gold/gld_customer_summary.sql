with order_summary as (
    select
        customer_id,
        count(*) as total_orders,
        count(case when status = 'COMPLETED' then 1 end) as completed_orders,
        cast(sum(case when status = 'COMPLETED' then amount else 0 end)
            as decimal(28,2)) as completed_sales_amount,
        count(case when status = 'CANCELLED' then 1 end) as cancelled_orders,
        count(case when status = 'REFUNDED' then 1 end) as refunded_orders,
        max(source_inserted_at) as latest_order_at
    from {{ ref('fact_orders') }}
    group by customer_id
)

select
    customers.customer_id,
    customers.customer_name,
    customers.country,
    customers.segment,
    coalesce(orders.total_orders, cast(0 as bigint)) as total_orders,
    coalesce(orders.completed_orders, cast(0 as bigint)) as completed_orders,
    coalesce(orders.completed_sales_amount, cast(0 as decimal(28,2)))
        as completed_sales_amount,
    coalesce(orders.cancelled_orders, cast(0 as bigint)) as cancelled_orders,
    coalesce(orders.refunded_orders, cast(0 as bigint)) as refunded_orders,
    orders.latest_order_at
from {{ ref('dim_customers') }} as customers
left join order_summary as orders
    on customers.customer_id = orders.customer_id
