# Customer history

`dim_customers_scd2` retains the original project's dbt snapshot definition:

- Source: `ref('slr_customers')`, read as a current-state table.
- Business key: `customer_id`.
- Change detection: a newer `source_updated_at` timestamp.
- History: Silver columns plus the standard `dbt_scd_id`, `dbt_updated_at`,
  `dbt_valid_from`, and `dbt_valid_to` fields. Current versions have NULL
  `dbt_valid_to`.

This is a regular dbt-managed snapshot history table, separate from the streaming
tables and reporting materialized views. It inherits the target catalog/schema
unless project configuration overrides them.

Customer DELETE events remain rows with `is_deleted = true` in Silver. Provided
their source timestamp advances, the snapshot captures that soft deletion as a
new version. Physical deletion handling remains at dbt's default, as in the
original project.

After `dbt_project.yml` and `slr_customers` are implemented, finish and verify the
Silver refresh before running:

```bash
dbt snapshot --select dim_customers_scd2 --profiles-dir .
```

A snapshot captures only the Silver state visible when it executes. Multiple
changes to one customer between snapshot runs will not all be preserved. The
initial snapshot records the current baseline; it does not reconstruct earlier
events from Bronze. Full event history requires a separate CDC/SCD2 design.

Validation on Databricks is pending the project configuration, Silver model, and
connection setup.
