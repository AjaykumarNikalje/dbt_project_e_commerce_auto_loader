
    

    -- Each column must be unique independently, not just as a composite key.
    -- Nulls are excluded, matching dbt's built-in unique test.
    with column_counts as (
        select
            
            `order_id` as value_1,
            count(*) over (partition by `order_id`)
                as occurrences_1
            
        from `retail_analytics_poc`.`dbt_retail_streaming_poc`.`fact_orders`
    ),

    validation as (
        select
            *,
            concat_ws('; ',
                
                case when value_1 is not null
                    and occurrences_1 > 1
                    then 'order_id: duplicate value' end
                    
                
            ) as validation_errors
        from column_counts
    )

    select *
    from validation
    where validation_errors <> ''
