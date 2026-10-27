-- Reconstructed balances can legitimately be zero (emptied accounts),
-- never negative.
select
    month_end_date,
    account_id,
    month_end_balance
from {{ ref('int_moneybox__account_monthly_snapshots') }}
where month_end_balance < 0
