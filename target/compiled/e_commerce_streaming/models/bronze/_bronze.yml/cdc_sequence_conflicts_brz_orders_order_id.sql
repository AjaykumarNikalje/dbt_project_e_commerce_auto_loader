
  
  select
    try_cast(`order_id` as int) as entity_id,
    try_cast(source_updated_at as timestamp) as event_sequence
  from `retail_analytics_poc`.`dbt_retail_streaming_poc`.`brz_orders`
  group by try_cast(`order_id` as int),
           try_cast(source_updated_at as timestamp)
  having count(distinct to_json(struct(* EXCEPT (ingested_at)))) > 1
