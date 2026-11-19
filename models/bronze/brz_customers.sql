select
  cast(customer_id as string) as customer_id,
  cast(customer_name as string) as customer_name,
  cast(email as string) as email,
  cast(country as string) as country,
  cast(segment as string) as segment,
  cast(signup_date as string) as signup_date,
  cast(source_inserted_at as string) as source_inserted_at,
  cast(source_updated_at as string) as source_updated_at,
  cast(batch_id as string) as batch_id,
  cast(operation_type as string) as operation_type,
  cast(source_file as string) as source_file,
  current_timestamp() as ingested_at
from STREAM {{ ref('src_customers') }}
