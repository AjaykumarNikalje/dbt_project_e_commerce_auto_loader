
    
    

with child as (
    select customer_id as from_field
    from `retail_analytics_poc`.`dbt_retail_streaming_poc`.`fact_orders`
    where customer_id is not null
),

parent as (
    select customer_id as to_field
    from `retail_analytics_poc`.`dbt_retail_streaming_poc`.`dim_customers`
)

select
    from_field

from child
left join parent
    on child.from_field = parent.to_field

where parent.to_field is null


