-- Publish customers before their order facts.
-- depends_on: {{ ref('dim_customers') }}

{% set backfill = is_backfill() %}

{% if backfill %}
with affected_ids as (
    select distinct try_cast(order_id as int) as order_id
    from {{ ref('brz_orders') }}
    where (
        try_cast(source_updated_at as timestamp) >= cast('{{ var('from_date') }}' as timestamp)
        and try_cast(source_updated_at as timestamp) <
            cast(date_add(cast('{{ var('to_date') }}' as date), 1) as timestamp)
    )
    -- Invalid timestamps must still reach validation.
    or try_cast(source_updated_at as timestamp) is null
)
{% endif %}
select
    incoming.order_id,
    incoming.customer_id,
    incoming.amount,
    incoming.status,
    incoming.source_inserted_at,
    incoming.source_updated_at,
    incoming.slr_updated_at
from {{ ref('slr_orders') }} as incoming
{% if backfill %}
where incoming.order_id in (select order_id from affected_ids)
{% elif is_incremental() %}
left join {{ this }} as existing
    on incoming.order_id = existing.order_id
where existing.order_id is null
   or incoming.slr_updated_at > existing.slr_updated_at
{% endif %}
