-- Exception report for the Finance reconciliation: what the pipeline fixed
-- (duplicates, corrections) and what remains visible (reporting-only
-- closures, still-missing closure dates).
{{ config(materialized='table', tags=['audit']) }}

with duplicate_summary as (
    select coalesce(sum(duplicate_rows_removed), 0) as duplicates_removed
    from {{ ref('int_moneybox__transactions_canonical') }}
),
correction_summary as (
    select
        count_if(lifecycle_quality_status = 'closure_date_corrected')
            as closure_dates_corrected,
        count_if(lifecycle_quality_status = 'missing_closure_date')
            as closure_dates_still_missing,
        count_if(lifecycle_quality_status = 'reporting_closed_profile_deleted')
            as reporting_only_closures
    from {{ ref('int_moneybox__account_lifecycle') }}
)

select
    d.duplicates_removed,
    c.closure_dates_corrected,
    c.closure_dates_still_missing,
    c.reporting_only_closures
from duplicate_summary d
cross join correction_summary c
