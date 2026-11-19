select
    cast(source_inserted_at as date) as order_date,
    count(*) as total_orders,
    count(case when status = 'PLACED' then 1 end) as placed_orders,
    count(case when status = 'COMPLETED' then 1 end) as completed_orders,
    cast(sum(case when status = 'COMPLETED' then amount else 0 end)
        as decimal(28,2)) as completed_sales_amount,
    count(case when status = 'CANCELLED' then 1 end) as cancelled_orders,
    cast(sum(case when status = 'CANCELLED' then amount else 0 end)
        as decimal(28,2)) as cancelled_order_amount,
    count(case when status = 'REFUNDED' then 1 end) as refunded_orders,
    cast(sum(case when status = 'REFUNDED' then amount else 0 end)
        as decimal(28,2)) as refunded_order_amount
from {{ ref('fact_orders') }}
group by cast(source_inserted_at as date)



