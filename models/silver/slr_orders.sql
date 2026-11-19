-- Customers (including placeholders) must load and pass validation first.
-- depends_on: {{ ref('slr_customers') }}

{% set backfill = is_backfill() %}

with
{% if backfill %}
affected_ids as (
    select distinct try_cast(order_id as int) as order_id
    from {{ ref('brz_orders') }}
    where (
        try_cast(source_updated_at as timestamp) >= cast('{{ var('from_date') }}' as timestamp)
        and try_cast(source_updated_at as timestamp) <
            cast(date_add(cast('{{ var('to_date') }}' as date), 1) as timestamp)
    )
    -- Invalid timestamps must still reach validation.
    or try_cast(source_updated_at as timestamp) is null
),
{% endif %}
typed as (
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
    from {{ ref('brz_orders') }} as bronze
    {% if backfill %}
    where exists (
        select 1 from affected_ids
        where try_cast(bronze.order_id as int) <=> affected_ids.order_id
    )
    {% endif %}
),
ranked as (
    select *,
        row_number() over (
            partition by order_id
            order by source_updated_at desc, brz_ingested_at desc, source_file desc
        ) as row_num
    from typed
)
select
    incoming.order_id,
    incoming.customer_id,
    incoming.amount,
    incoming.status,
    incoming.source_inserted_at,
    incoming.source_updated_at,
    incoming.brz_ingested_at,
    incoming.slr_ingested_at,
    incoming.slr_updated_at,
    incoming.batch_id,
    incoming.operation_type,
    incoming.source_file
from ranked as incoming
{% if not backfill and is_incremental() %}
left join {{ this }} as existing
    on incoming.order_id = existing.order_id
{% endif %}
where incoming.row_num = 1
{% if not backfill and is_incremental() %}
  and (existing.order_id is null
       or incoming.source_updated_at > existing.source_updated_at)
{% endif %}
