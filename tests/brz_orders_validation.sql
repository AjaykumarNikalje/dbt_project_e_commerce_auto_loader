{{ config(severity='error') }}
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
scoped_bronze as (
    select *
    from {{ ref('brz_orders') }} as bronze
    {% if backfill %}
    where exists (
        select 1 from affected_ids
        where try_cast(bronze.order_id as int) <=> affected_ids.order_id
    )
    {% endif %}
)
-- Any rows returned are invalid and fail the test.
select *
from scoped_bronze
where
    -- Required fields and conversions used by Silver.
    try_cast(order_id as int) is null
    or try_cast(customer_id as int) is null
    or try_cast(amount as decimal(18,2)) is null
    or status is null
    or try_cast(source_inserted_at as timestamp) is null
    or try_cast(source_updated_at as timestamp) is null
    or ingested_at is null
    or batch_id is null
    or operation_type is null
    or source_file is null

    -- Allowed order values.
    or status not in ('PLACED', 'COMPLETED', 'CANCELLED', 'REFUNDED')
    or operation_type not in ('INSERT', 'UPDATE')

    -- Allowed order amount.
    or try_cast(amount as decimal(18,2)) < 0
    or try_cast(amount as decimal(18,2)) > {{ var('max_order_amount') }}
