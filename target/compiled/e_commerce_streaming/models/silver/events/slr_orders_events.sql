
  
  
  with typed as (
    select
      
      try_cast(order_id as int) as order_id,
      try_cast(customer_id as int) as customer_id,
      try_cast(amount as decimal(18,2)) as amount,
      status,
      
      try_cast(source_inserted_at as timestamp) as source_inserted_at,
      try_cast(source_updated_at as timestamp) as source_updated_at,
      ingested_at as brz_ingested_at,
      current_timestamp() as slr_ingested_at,
      current_timestamp() as slr_updated_at,
      batch_id, operation_type, source_file
    from STREAM `retail_analytics_poc`.`dbt_retail_streaming_poc`.`brz_orders`
  )
  select
    
      
      case when 
  
  `order_id` is not null and `customer_id` is not null and `amount` is not null and `status` is not null and `source_inserted_at` is not null and `source_updated_at` is not null and `brz_ingested_at` is not null and `batch_id` is not null and `source_file` is not null and `operation_type` is not null and 
  
    status in 
  ('PLACED', 'COMPLETED', 'CANCELLED', 'REFUNDED')

    and operation_type in ('INSERT', 'UPDATE')
    and amount between 0 and 100000
  
 then `order_id`
        else cast(raise_error('Invalid orders event: required value, cast, allowed value, or amount range failed') as int)
      end as `order_id`,
      
    
      
      `customer_id`,
      
    
      
      `amount`,
      
    
      
      `status`,
      
    
      
      `source_inserted_at`,
      
    
      
      `source_updated_at`,
      
    
      
      `brz_ingested_at`,
      
    
      
      `slr_ingested_at`,
      
    
      
      `slr_updated_at`,
      
    
      
      `batch_id`,
      
    
      
      `operation_type`,
      
    
      
      `source_file`,
      
    
    
  array(
    
    'order_id',
    
    'customer_id',
    
    'amount',
    
    'status',
    
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
