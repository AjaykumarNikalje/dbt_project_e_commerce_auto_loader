
    

    -- Each column must be unique independently, not just as a composite key.
    -- Nulls are excluded, matching dbt's built-in unique test.
    with column_counts as (
        select
            
            `customer_id` as value_1,
            count(*) over (partition by `customer_id`)
                as occurrences_1,
            
            `email` as value_2,
            count(*) over (partition by `email`)
                as occurrences_2
            
        from `retail_analytics_poc`.`dbt_retail_streaming_poc`.`slr_customers`
    ),

    validation as (
        select
            *,
            concat_ws('; ',
                
                case when value_1 is not null
                    and occurrences_1 > 1
                    then 'customer_id: duplicate value' end
                    ,
                
                case when value_2 is not null
                    and occurrences_2 > 1
                    then 'email: duplicate value' end
                    
                
            ) as validation_errors
        from column_counts
    )

    select *
    from validation
    where validation_errors <> ''
