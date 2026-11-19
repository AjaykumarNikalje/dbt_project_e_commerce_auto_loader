{% set backfill = is_backfill() %}

{% if backfill %}
with affected_ids as (
    select distinct try_cast(customer_id as int) as customer_id
    from {{ ref('brz_customers') }}
    where (
        try_cast(source_updated_at as timestamp) >= cast('{{ var('from_date') }}' as timestamp)
        and try_cast(source_updated_at as timestamp) <
            cast(date_add(cast('{{ var('to_date') }}' as date), 1) as timestamp)
    )
    -- Invalid timestamps must still reach validation.
    or try_cast(source_updated_at as timestamp) is null

    union
    select distinct try_cast(customer_id as int) as customer_id
    from {{ ref('brz_orders') }}
    where (
        try_cast(source_updated_at as timestamp) >= cast('{{ var('from_date') }}' as timestamp)
        and try_cast(source_updated_at as timestamp) <
            cast(date_add(cast('{{ var('to_date') }}' as date), 1) as timestamp)
    )
    or try_cast(source_updated_at as timestamp) is null
)
{% endif %}
select
    incoming.customer_id,
    incoming.customer_name,
    incoming.email,
    incoming.country,
    incoming.segment,
    incoming.signup_date,
    incoming.is_deleted,
    incoming.slr_updated_at,
    current_timestamp() as dim_ingested_time,
    current_timestamp() as dim_updated_time
from {{ ref('slr_customers') }} as incoming
{% if backfill %}
where incoming.customer_id in (select customer_id from affected_ids)
{% elif is_incremental() %}
left join {{ this }} as existing
    on incoming.customer_id = existing.customer_id
where existing.customer_id is null
   or incoming.slr_updated_at > existing.slr_updated_at
{% endif %}
