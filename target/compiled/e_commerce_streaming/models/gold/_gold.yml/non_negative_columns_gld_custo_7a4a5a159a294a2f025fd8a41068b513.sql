
    select *
    from `retail_analytics_poc`.`dbt_retail_streaming_poc`.`gld_customer_summary`
    where
        
        `total_orders` < 0 or
        
        `completed_orders` < 0 or
        
        `completed_sales_amount` < 0 or
        
        `cancelled_orders` < 0 or
        
        `refunded_orders` < 0
        
