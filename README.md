# E-commerce dbt project

The project uses eight models with direct SQL and standard dbt materializations.

```text
CSV seeds + later CSV appends
              ↓
src_customers / src_orders       append-only Delta source tables
              ↓
brz_customers / brz_orders       streaming tables, keep raw event history
              ↓
slr_customers / slr_orders       incremental Delta tables using MERGE
              ↓
dim_customers / fact_orders      incremental Delta tables using MERGE
              ↓
gld_customer_summary             reporting materialized view
gld_daily_sales                  reporting materialized view

slr_customers → dim_customers_scd2 (regular dbt snapshot)
```

## Initial load

Activate the dbt environment. Connection settings are in the project-local
`profiles.yml`, which is excluded from Git because it contains credentials.
The target catalog/schema must be available to your dbt identity.

```bash
dbt debug --profiles-dir .
dbt seed --profiles-dir .
dbt build --profiles-dir . --exclude resource_type:seed
```

Seed once into an empty destination. There is no longer a seed reload guard. Initial seeds contain 6 customer rows and 8 order rows,
with every source column explicitly configured as STRING. No Volume path,
Auto Loader, custom materialization, inline flow, or change-feed setup is needed.
Databricks must support Unity Catalog streaming tables and materialized views;
use a compatible serverless SQL warehouse. Local checks use dbt-core 1.12.5 and
dbt-databricks 1.12.8.

## New CSV batches

The earlier ingestion macros remain empty. The former CSV append script is disabled.
For later batches, use a separate loader to append rows to `src_customers` or
`src_orders`, then run:

```bash
dbt build --profiles-dir . --exclude resource_type:seed
```

The automatic reseed and full-refresh guards have also been removed. Do not rerun
seeds or reset source tables while preserving existing Bronze streaming
checkpoints: source data must remain append-only.

## Processing rules

Bronze streams new source-table inserts and records `ingested_at`. Silver reads
Bronze as an ordinary table, casts values, ranks events by business
key and source timestamp, then merges only new keys or newer versions of an
existing key. This avoids a global timestamp watermark dropping late events for
other keys. Older/equal-time events do not overwrite newer state. Equal-timestamp events use ingestion time and filename as ranking tie-breakers.
Conflicting equal-time events are not checked by these validation tests.

Silver deliberately scans Bronze history on each run for a simple, correct
baseline. Optimize with persisted processing boundaries only if data volume
requires it. Customer DELETE events set `is_deleted = true`; orders accept INSERT
and UPDATE. Gold merges changed Silver rows by key and `slr_updated_at`.
`merge_exclude_columns` preserves first-ingestion timestamps on updates.

Column names and types match the original eight models. Incremental model
contracts declare their schemas and constraints. Two plain SQL tests reference the corresponding Bronze models:
`tests/brz_customers_validation.sql` and `tests/brz_orders_validation.sql`. They check
required fields and failed casts, allowed segments/statuses/operations, and order
amounts before dependent Silver models run. They return the original invalid Bronze rows; any failures have error severity
and fail the build. Allowed segments/statuses are listed directly in the tests;
the amount limit remains configured by `max_order_amount`.
Silver SQL contains casts, deduplication, and merge selection without inline
`raise_error` validation. Reporting SQL is unchanged and includes
soft-deleted customers, as in the original project. The customer snapshot records
states visible when it runs, not every intermediate source event.

Source-table mutation/reset or full refresh requires a coordinated rebuild;
there is no longer an automatic guard.

## Validation and migration

Offline compilation does not validate warehouse permissions, SQL execution, or
streaming refresh behavior. Test initial loads, updates, late events, soft deletes,
repeat runs, ingestion timestamps, and report reconciliation on Databricks.

If the earlier design was deployed, Silver/dimension/fact objects may already be
streaming tables. They need a planned migration to ordinary Delta tables before
running this design. Existing remote objects have not been changed or dropped.

## Bronze validation gate

Always use `dbt build --profiles-dir . --exclude resource_type:seed` for the
pipeline. `dbt run` alone bypasses data tests. The build order for each entity is:

```text
Bronze refresh → Bronze validation → Silver MERGE → Silver validation → Gold/reporting
```

Invalid Bronze rows remain available for diagnosis. These tests deliberately
check all Bronze history, matching Silver's input; no timestamp watermark is
reintroduced. Resolve invalid raw records before retrying. Tests do not undo the
Bronze refresh or completed work on independent branches. With the project's
`fail_fast: true`, a test error stops scheduling further work; it is not a
transaction covering the whole pipeline. Use one writer/pipeline run at a time
so Bronze does not change between validation and Silver processing.

## Silver validation gate

`tests/slr_customers_validation.sql` checks required values, unique customer IDs
and emails, allowed segments/operations, and consistency of `is_deleted` with
DELETE operations. `tests/slr_orders_validation.sql` checks required values,
unique order IDs, allowed statuses/operations, amount limits, and the customer
relationship. Soft-deleted customers remain valid relationship targets.

These tests run after Silver loads and block dependent Gold models and customer
snapshots on failure during `dbt build`. They inspect current Silver state,
including existing records. They do not roll back the Silver MERGE.

## Gold dimension and fact tests

`tests/dim_customers_validation.sql` checks required dimension values, unique
customer IDs and emails, allowed segments, and processing timestamp order.
`tests/fact_orders_validation.sql` checks required fact values, unique order IDs,
allowed statuses, amount limits, and customer references against `dim_customers`.
Soft-deleted customers are valid relationship targets. Both tests fail on any
returned rows. Run them explicitly with:

```bash
dbt test --profiles-dir . --select dim_customers_validation fact_orders_validation
```

They also run in the full `dbt build`. Explicit dependencies now put customer dimensions before facts and Silver
customers before Silver orders, so their relationship tests gate downstream
reporting, including `gld_daily_sales`, during the full build. Gold validation does not roll back
completed merges.

## Historical backfill for code corrections

Use existing Bronze history when source data was correct but transformation code
needs to be rerun. Only one helper, `is_backfill()`, lives in `macros/backfill.sql`.
The default `load_mode: incremental` preserves the existing incremental path.

```bash
# Normal pipeline (including Bronze refresh).
dbt build --profiles-dir . --exclude resource_type:seed

# Backfill: existing Bronze only; no source/seed load or Bronze refresh.
dbt build --profiles-dir . \
  --select path:models/silver path:models/gold path:tests \
  --vars '{"load_mode":"backfill","from_date":"2026-11-01","to_date":"2026-11-05"}'
```

Dates must be valid YYYY-MM-DD values with `from_date <= to_date`. The range is
inclusive: `source_updated_at >= from_date 00:00:00` and strictly before midnight
after `to_date`, using the warehouse session timezone. Do not use `--full-refresh`
with backfill. Use the selection above so Bronze and snapshots are not executed.

For each entity, select affected IDs from Bronze events in that range, then read
**all retained Bronze events for those IDs**. This preserves the latest source
state even if the latest event is outside the requested dates. The Bronze tests
validate exactly this input. Invalid timestamps remain in scope for validation;
invalid IDs are matched null-safely so malformed keys cannot silently disappear.

Silver recalculates and merges the latest state for each affected ID, including
when its source timestamp equals the existing Silver timestamp. Gold remerges
those IDs regardless of processing timestamps, so Gold-only code changes are
reapplied too. First-ingestion timestamps remain preserved by merge exclusions.
Silver/Gold validation still checks their complete current tables, and reporting
materialized views refresh normally.

This is a current-state repair, not a point-in-time reconstruction. It requires
complete Bronze history for the affected IDs. Existing SCD2 history is unchanged;
changes to business keys or table grain require a separate migration. Run a
single writer/pipeline so Bronze stays stable throughout selection and merge.

## Orders arriving before customers

`slr_customers` reads customer IDs from Bronze orders. If an ID has no real Bronze
customer and no existing Silver customer, it generates one placeholder without
adding columns:

| Column | Placeholder value |
| --- | --- |
| customer_id | Original order customer ID |
| customer_name | `Unknown_Customer_<id>` |
| email | `unknown_customer_<id>@placeholder.invalid` |
| country / segment | `UNKNOWN` |
| signup_date | `1900-01-01` |
| source_inserted_at / source_updated_at | `1900-01-01 00:00:00` |
| operation_type / is_deleted | `INSERT` / `false` |
| batch_id / source_file | `__placeholder__` |
| Processing timestamps | Actual processing time |

Reserve this name prefix and email domain for generated placeholders. Real
customer source timestamps must be after the sentinel; Bronze customer tests
enforce that rule. Silver and dimension tests accept UNKNOWN fields only for
correctly formed placeholders, and continue enforcing uniqueness and non-null
values. Placeholders are never regenerated or used to overwrite real customers.

When the real customer arrives, the existing source timestamp comparison replaces
the placeholder's values. The original Silver and dimension ingestion timestamps
remain unchanged. Gold receives the actual customer details on that run; order
customer IDs stay the same. A genuine DELETE event can also replace a placeholder
and marks the customer soft-deleted.

The dependency order is explicit:

```text
Bronze customer/order tests → Silver customers (real + placeholders)
    → Silver customer tests → Silver orders → Silver order tests
    → Gold dimension → Gold dimension tests → Gold fact
    → Gold fact tests → Reporting
```

The customer backfill scope includes IDs from dated Bronze order events, so an
order-only backfill creates and publishes any required placeholders. Real
customer history still takes priority. Customer snapshot timestamp strategy also
captures placeholders: their validity starts at the sentinel, and a later real
customer version closes that version. The sentinel denotes unknown source time,
not when the customer actually existed; processing timestamps show when the
placeholder was observed. Existing snapshot history is not rebuilt by backfill.

The normal full `dbt build --profiles-dir . --exclude resource_type:seed` command
processes this sequence. Selecting only orders will not automatically build the
customer prerequisites; use the full build or include ancestors in the selection.
