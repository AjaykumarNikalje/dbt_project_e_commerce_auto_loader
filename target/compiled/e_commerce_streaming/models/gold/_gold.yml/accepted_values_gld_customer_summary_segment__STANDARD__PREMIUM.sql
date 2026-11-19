
    
    

with all_values as (

    select
        segment as value_field,
        count(*) as n_records

    from `retail_analytics_poc`.`dbt_retail_streaming_poc`.`gld_customer_summary`
    group by segment

)

select *
from all_values
where value_field not in (
    'STANDARD','PREMIUM'
)


