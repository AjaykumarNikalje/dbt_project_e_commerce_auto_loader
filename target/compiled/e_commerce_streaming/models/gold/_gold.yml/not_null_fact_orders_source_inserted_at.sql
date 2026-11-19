
    
    



select source_inserted_at
from `retail_analytics_poc`.`dbt_retail_streaming_poc`.`fact_orders`
where source_inserted_at is null


