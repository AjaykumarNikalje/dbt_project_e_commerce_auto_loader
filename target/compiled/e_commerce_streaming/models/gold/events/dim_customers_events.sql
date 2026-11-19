
  select
    
    case when _change_type = 'delete'
      then cast(raise_error('Physical customer deletes are unsupported; use a DELETE CSV event for soft deletion') as int)
      else customer_id end as customer_id,
    customer_name, email, country, segment, signup_date, is_deleted,
    slr_updated_at,
    current_timestamp() as dim_ingested_time,
    current_timestamp() as dim_updated_time,
    
    _commit_version as _cdc_sequence,
    
  array(
    
    'customer_id',
    
    'customer_name',
    
    'email',
    
    'country',
    
    'segment',
    
    'signup_date',
    
    'is_deleted',
    
    'dim_updated_time',
    
    'slr_updated_at'
    
  )
 as _columns_to_update
  from STREAM `retail_analytics_poc`.`dbt_retail_streaming_poc`.`slr_customers` WITH (readChangeFeed = true)
  where _change_type in ('insert', 'update_postimage', 'delete')
