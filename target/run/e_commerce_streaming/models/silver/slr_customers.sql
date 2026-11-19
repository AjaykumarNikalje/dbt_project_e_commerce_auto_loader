-- back compat for old kwarg name
  
  
  
  
  
  
      
          
          
      
  

    merge
    into
        `retail_analytics_poc_strm_tab`.`dbt_retail_streaming_poc`.`slr_customers` as DBT_INTERNAL_DEST
    using
        `slr_customers__dbt_tmp` as DBT_INTERNAL_SOURCE
    on
        
              DBT_INTERNAL_SOURCE.`customer_id` <=> DBT_INTERNAL_DEST.`customer_id`
          
    when matched
        then update set
            `customer_id` = DBT_INTERNAL_SOURCE.`customer_id`, `customer_name` = DBT_INTERNAL_SOURCE.`customer_name`, `email` = DBT_INTERNAL_SOURCE.`email`, `country` = DBT_INTERNAL_SOURCE.`country`, `segment` = DBT_INTERNAL_SOURCE.`segment`, `is_deleted` = DBT_INTERNAL_SOURCE.`is_deleted`, `signup_date` = DBT_INTERNAL_SOURCE.`signup_date`, `source_inserted_at` = DBT_INTERNAL_SOURCE.`source_inserted_at`, `source_updated_at` = DBT_INTERNAL_SOURCE.`source_updated_at`, `brz_ingested_at` = DBT_INTERNAL_SOURCE.`brz_ingested_at`, `slr_updated_at` = DBT_INTERNAL_SOURCE.`slr_updated_at`, `batch_id` = DBT_INTERNAL_SOURCE.`batch_id`, `operation_type` = DBT_INTERNAL_SOURCE.`operation_type`, `source_file` = DBT_INTERNAL_SOURCE.`source_file`
    when not matched
        then insert
            (`customer_id`, `customer_name`, `email`, `country`, `segment`, `is_deleted`, `signup_date`, `source_inserted_at`, `source_updated_at`, `brz_ingested_at`, `slr_ingested_at`, `slr_updated_at`, `batch_id`, `operation_type`, `source_file`) VALUES (DBT_INTERNAL_SOURCE.`customer_id`, DBT_INTERNAL_SOURCE.`customer_name`, DBT_INTERNAL_SOURCE.`email`, DBT_INTERNAL_SOURCE.`country`, DBT_INTERNAL_SOURCE.`segment`, DBT_INTERNAL_SOURCE.`is_deleted`, DBT_INTERNAL_SOURCE.`signup_date`, DBT_INTERNAL_SOURCE.`source_inserted_at`, DBT_INTERNAL_SOURCE.`source_updated_at`, DBT_INTERNAL_SOURCE.`brz_ingested_at`, DBT_INTERNAL_SOURCE.`slr_ingested_at`, DBT_INTERNAL_SOURCE.`slr_updated_at`, DBT_INTERNAL_SOURCE.`batch_id`, DBT_INTERNAL_SOURCE.`operation_type`, DBT_INTERNAL_SOURCE.`source_file`)
