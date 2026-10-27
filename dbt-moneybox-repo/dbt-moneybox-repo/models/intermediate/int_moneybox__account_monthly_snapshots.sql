-- Point-in-time month-end state per account, reconstructed from canonical
-- transactions. Never restated, so churn and reactivation are visible
-- naturally (the balance crosses zero and crosses back).
{{ config(materialized='table', cluster_by=['month_end_date', 'account_id']) }}

with month_end_balances as (
    select
        m.month_end_date,
        t.account_id,
        sum(t.signed_amount) as month_end_balance
    from {{ ref('int_moneybox__month_spine') }} m
    join {{ ref('int_moneybox__transactions_canonical') }} t
        on t.txn_ts < cast(date_add(m.month_end_date, 1) as timestamp)
    group by m.month_end_date, t.account_id
)

select
    m.month_end_date,
    l.account_id,
    l.user_id,
    l.product_type,
    l.effective_reporting_closed_at,
    l.lifecycle_quality_status,
    coalesce(b.month_end_balance, 0) as month_end_balance,
    (l.effective_reporting_closed_at is null
        or l.effective_reporting_closed_at > m.month_end_date
    ) as reporting_open_at_month_end,
    -- Active = funded AND reporting-open at month end. Practice ground truth:
    -- account 105 (deleted profile, funded) stays in all-account AUM but is
    -- NOT active.
    (coalesce(b.month_end_balance, 0) > 0
        and (l.effective_reporting_closed_at is null
             or l.effective_reporting_closed_at > m.month_end_date)
    ) as active_at_month_end
from {{ ref('int_moneybox__month_spine') }} m
join {{ ref('int_moneybox__account_lifecycle') }} l
    on l.opened_at <= m.month_end_date
left join month_end_balances b
    on b.month_end_date = m.month_end_date
   and b.account_id = l.account_id
