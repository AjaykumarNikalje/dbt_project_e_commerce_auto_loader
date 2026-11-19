-- back compat for old kwarg name
  
  
  
  
  
  
      
          
          
      
  

    merge
    into
        `retail_analytics_poc_strm_tab`.`dbt_retail_streaming_poc`.`dim_customers` as DBT_INTERNAL_DEST
    using
        `dim_customers__dbt_tmp` as DBT_INTERNAL_SOURCE
    on
        
              DBT_INTERNAL_SOURCE.`customer_id` <=> DBT_INTERNAL_DEST.`customer_id`
          
    when matched
        then update set
            `customer_id` = DBT_INTERNAL_SOURCE.`customer_id`, `customer_name` = DBT_INTERNAL_SOURCE.`customer_name`, `email` = DBT_INTERNAL_SOURCE.`email`, `country` = DBT_INTERNAL_SOURCE.`country`, `segment` = DBT_INTERNAL_SOURCE.`segment`, `signup_date` = DBT_INTERNAL_SOURCE.`signup_date`, `is_deleted` = DBT_INTERNAL_SOURCE.`is_deleted`, `dim_updated_time` = DBT_INTERNAL_SOURCE.`dim_updated_time`, `slr_updated_at` = DBT_INTERNAL_SOURCE.`slr_updated_at`
    when not matched
        then insert
            (`customer_id`, `customer_name`, `email`, `country`, `segment`, `signup_date`, `is_deleted`, `slr_updated_at`, `dim_ingested_time`, `dim_updated_time`) VALUES (DBT_INTERNAL_SOURCE.`customer_id`, DBT_INTERNAL_SOURCE.`customer_name`, DBT_INTERNAL_SOURCE.`email`, DBT_INTERNAL_SOURCE.`country`, DBT_INTERNAL_SOURCE.`segment`, DBT_INTERNAL_SOURCE.`signup_date`, DBT_INTERNAL_SOURCE.`is_deleted`, DBT_INTERNAL_SOURCE.`slr_updated_at`, DBT_INTERNAL_SOURCE.`dim_ingested_time`, DBT_INTERNAL_SOURCE.`dim_updated_time`)
