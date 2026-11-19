{{ config(severity='error') }}
{% set backfill = is_backfill() %}

with
{% if backfill %}
affected_ids as (
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
),
{% endif %}
scoped_bronze as (
    select *
    from {{ ref('brz_customers') }} as bronze
    {% if backfill %}
    where exists (
        select 1 from affected_ids
        where try_cast(bronze.customer_id as int) <=> affected_ids.customer_id
    )
    {% endif %}
)
-- Any rows returned are invalid and fail the test.
select *
from scoped_bronze
where
    -- Required fields and conversions used by Silver.
    try_cast(customer_id as int) is null
    or customer_name is null
    or email is null
    or country is null
    or segment is null
    or try_cast(signup_date as date) is null
    or try_cast(source_inserted_at as timestamp) is null
    or try_cast(source_updated_at as timestamp) is null
    or ingested_at is null
    or operation_type is null
    or source_file is null

    -- Allowed customer values.
    or segment not in ('STANDARD', 'PREMIUM')
    or operation_type not in ('INSERT', 'UPDATE', 'DELETE')

    -- Reserve the placeholder identity and old timestamp for generated rows.
    or substring(customer_name, 1, 17) = 'Unknown_Customer_'
    or email like '%@placeholder.invalid'
    or try_cast(source_updated_at as timestamp) <= cast('1900-01-01 00:00:00' as timestamp)
