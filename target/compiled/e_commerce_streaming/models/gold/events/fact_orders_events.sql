
  select
    
    case when _change_type = 'delete'
      then cast(raise_error('Physical order deletes are unsupported') as int)
      else order_id end as order_id,
    customer_id, amount, status, source_inserted_at, source_updated_at, slr_updated_at,
    
    _commit_version as _cdc_sequence,
    
  array(
    
    'order_id',
    
    'customer_id',
    
    'amount',
    
    'status',
    
    'source_inserted_at',
    
    'source_updated_at',
    
    'slr_updated_at'
    
  )
 as _columns_to_update
  from STREAM `retail_analytics_poc`.`dbt_retail_streaming_poc`.`slr_orders` WITH (readChangeFeed = true)
  where _change_type in ('insert', 'update_postimage', 'delete')
