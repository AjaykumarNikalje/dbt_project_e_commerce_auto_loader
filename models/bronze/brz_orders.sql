select
  cast(order_id as string) as order_id,
  cast(customer_id as string) as customer_id,
  cast(amount as string) as amount,
  cast(status as string) as status,
  cast(source_inserted_at as string) as source_inserted_at,
  cast(source_updated_at as string) as source_updated_at,
  cast(batch_id as string) as batch_id,
  cast(operation_type as string) as operation_type,
  cast(source_file as string) as source_file,
  current_timestamp() as ingested_at
from STREAM {{ ref('src_orders') }}
