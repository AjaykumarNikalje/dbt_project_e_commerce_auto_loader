

with customers as (
    select *,
        count(*) over (partition by customer_id) as customer_id_count,
        count(*) over (partition by email) as email_count
    from `retail_analytics_poc_strm_tab`.`dbt_retail_streaming_poc`.`slr_customers`
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
    or segment not in ('STANDARD', 'PREMIUM')
    or operation_type not in ('INSERT', 'UPDATE', 'DELETE')
    or is_deleted <> (operation_type = 'DELETE')