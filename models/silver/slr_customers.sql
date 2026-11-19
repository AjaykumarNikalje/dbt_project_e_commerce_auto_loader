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
typed as (
    select
        try_cast(customer_id as int) as customer_id,
        customer_name, email, country, segment,
        try_cast(signup_date as date) as signup_date,
        operation_type = 'DELETE' as is_deleted,
        try_cast(source_inserted_at as timestamp) as source_inserted_at,
        try_cast(source_updated_at as timestamp) as source_updated_at,
        ingested_at as brz_ingested_at,
        current_timestamp() as slr_ingested_at,
        current_timestamp() as slr_updated_at,
        batch_id, operation_type, source_file
    from {{ ref('brz_customers') }} as bronze
    {% if backfill %}
    where exists (
        select 1 from affected_ids
        where try_cast(bronze.customer_id as int) <=> affected_ids.customer_id
    )
    {% endif %}
),
ranked as (
    select *,
        row_number() over (
            partition by customer_id
            order by source_updated_at desc, brz_ingested_at desc, source_file desc
        ) as row_num
    from typed
),
real_customers as (
    select
        incoming.customer_id,
        incoming.customer_name,
        incoming.email,
        incoming.country,
        incoming.segment,
        incoming.is_deleted,
        incoming.signup_date,
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
        on incoming.customer_id = existing.customer_id
    {% endif %}
    where incoming.row_num = 1
    {% if not backfill and is_incremental() %}
      and (existing.customer_id is null
           or incoming.source_updated_at > existing.source_updated_at)
    {% endif %}
),
order_customer_ids as (
    select distinct try_cast(customer_id as int) as customer_id
    from {{ ref('brz_orders') }}
    where try_cast(customer_id as int) is not null
    {% if backfill %}
      and try_cast(customer_id as int) in (select customer_id from affected_ids)
    {% endif %}
),
placeholder_customers as (
    select
        orders.customer_id,
        concat('Unknown_Customer_', cast(orders.customer_id as string)) as customer_name,
        concat('unknown_customer_', cast(orders.customer_id as string), '@placeholder.invalid') as email,
        'UNKNOWN' as country,
        'UNKNOWN' as segment,
        false as is_deleted,
        cast('1900-01-01' as date) as signup_date,
        cast('1900-01-01 00:00:00' as timestamp) as source_inserted_at,
        cast('1900-01-01 00:00:00' as timestamp) as source_updated_at,
        current_timestamp() as brz_ingested_at,
        current_timestamp() as slr_ingested_at,
        current_timestamp() as slr_updated_at,
        '__placeholder__' as batch_id,
        'INSERT' as operation_type,
        '__placeholder__' as source_file
    from order_customer_ids as orders
    -- Real Bronze customer data always takes priority, including soft deletions.
    where not exists (
        select 1 from {{ ref('brz_customers') }} as customers
        where try_cast(customers.customer_id as int) = orders.customer_id
    )
    {% if is_incremental() %}
    -- Do not recreate an existing placeholder or overwrite a real Silver customer.
      and not exists (
          select 1 from {{ this }} as existing
          where existing.customer_id = orders.customer_id
      )
    {% endif %}
)
select * from real_customers
union all
select * from placeholder_customers
