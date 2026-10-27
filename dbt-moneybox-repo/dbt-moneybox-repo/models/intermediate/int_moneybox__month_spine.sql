-- Complete month grid from first account opening to the latest transaction,
-- so months with zero activity still appear in Growth trends.
{{ config(materialized='table') }}

with bounds as (
    select
        cast(date_trunc('month', min(a.opened_at)) as date) as first_month,
        cast(
            date_trunc('month', greatest(max(a.opened_at), cast(max(t.txn_ts) as date)))
            as date
        ) as last_month
    from {{ ref('stg_moneybox__accounts') }} a
    cross join {{ ref('stg_moneybox__transactions') }} t
),
spine as (
    select explode(sequence(first_month, last_month, interval 1 month)) as month_start_date
    from bounds
)

select
    month_start_date,
    cast(last_day(month_start_date) as date) as month_end_date
from spine
