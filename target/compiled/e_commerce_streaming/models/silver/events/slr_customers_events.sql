
  
  
  with typed as (
    select
      
      try_cast(customer_id as int) as customer_id,
      customer_name, email, country, segment,
      try_cast(signup_date as date) as signup_date,
      operation_type = 'DELETE' as is_deleted,
      
      try_cast(source_inserted_at as timestamp) as source_inserted_at,
      try_cast(source_updated_at as timestamp) as source_updated_at,
      ingested_at as brz_ingested_at,
      current_timestamp() as slr_ingested_at,
      current_timestamp() as slr_updated_at,
      batch_id, operation_type, source_file
    from STREAM `retail_analytics_poc`.`dbt_retail_streaming_poc`.`brz_customers`
  )
  select
    
      
      case when 
  
  `customer_id` is not null and `customer_name` is not null and `email` is not null and `country` is not null and `segment` is not null and `signup_date` is not null and `source_inserted_at` is not null and `source_updated_at` is not null and `brz_ingested_at` is not null and `source_file` is not null and `operation_type` is not null and 
  
    segment in 
  ('STANDARD', 'PREMIUM')

    and operation_type in ('INSERT', 'UPDATE', 'DELETE')
  
 then `customer_id`
        else cast(raise_error('Invalid customers event: required value, cast, allowed value, or amount range failed') as int)
      end as `customer_id`,
      
    
      
      `customer_name`,
      
    
      
      `email`,
      
    
      
      `country`,
      
    
      
      `segment`,
      
    
      
      `is_deleted`,
      
    
      
      `signup_date`,
      
    
      
      `source_inserted_at`,
      
    
      
      `source_updated_at`,
      
    
      
      `brz_ingested_at`,
      
    
      
      `slr_ingested_at`,
      
    
      
      `slr_updated_at`,
      
    
      
      `batch_id`,
      
    
      
      `operation_type`,
      
    
      
      `source_file`,
      
    
    
  array(
    
    'customer_id',
    
    'customer_name',
    
    'email',
    
    'country',
    
    'segment',
    
    'is_deleted',
    
    'signup_date',
    
    'source_inserted_at',
    
    'source_updated_at',
    
    'brz_ingested_at',
    
    'slr_updated_at',
    
    'batch_id',
    
    'operation_type',
    
    'source_file'
    
  )
 as _columns_to_update
  from typed
