# CSV batches

Initial files are combined into `seeds/src_customers.csv` and
`seeds/src_orders.csv` for the initial dbt seed load.

For later CSV files, append data to the source tables with a separate loader.
The previous macro-based append script is disabled because custom macros have
been emptied. Do not replace the source tables or reload the initial data.
