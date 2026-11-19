"""The macro-based CSV append helper has been removed."""

if __name__ == "__main__":
    raise SystemExit(
        "CSV append helper is unavailable because custom macros were emptied. "
        "Append later batches to src_customers/src_orders through a separate loader."
    )
