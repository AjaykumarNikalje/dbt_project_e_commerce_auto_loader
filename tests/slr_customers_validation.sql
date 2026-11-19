{{ config(severity='error') }}

with customers as (
    select *,
        customer_name = concat('Unknown_Customer_', cast(customer_id as string)) as is_placeholder,
        count(*) over (partition by customer_id) as customer_id_count,
        count(*) over (partition by email) as email_count
    from {{ ref('slr_customers') }}
)
-- Any rows returned fail the test and block dependent Gold models.
select *
from customers
where
    -- Required Silver values.
    customer_id is null
    or customer_name is null
    or email is null
    or country is null
    or segment is null
    or signup_date is null
    or source_inserted_at is null
    or source_updated_at is null
    or brz_ingested_at is null
    or slr_ingested_at is null
    or slr_updated_at is null
    or operation_type is null
    or source_file is null
    or is_deleted is null

    -- One current row per customer; emails must also be unique.
    or customer_id_count > 1
    or email_count > 1

    -- Allowed values and consistent soft deletion.
    or (segment not in ('STANDARD', 'PREMIUM') and not is_placeholder)
    or operation_type not in ('INSERT', 'UPDATE', 'DELETE')
    or is_deleted <> (operation_type = 'DELETE')

    -- UNKNOWN values are reserved for correctly formed placeholder customers.
    or (is_placeholder and (
        segment <> 'UNKNOWN'
        or country <> 'UNKNOWN'
        or email <> concat('unknown_customer_', cast(customer_id as string), '@placeholder.invalid')
        or signup_date <> cast('1900-01-01' as date)
        or source_inserted_at <> cast('1900-01-01 00:00:00' as timestamp)
        or source_updated_at <> cast('1900-01-01 00:00:00' as timestamp)
        or source_file <> '__placeholder__'
        or batch_id is null
        or batch_id <> '__placeholder__'
        or operation_type <> 'INSERT'
        or is_deleted <> false
    ))
