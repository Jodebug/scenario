-- The reconstruction must tie back to the platform's own current AUM
-- (mirrors CHECK 5 in the raw dataset script).
with latest_snapshot as (
    select
        account_id,
        month_end_balance,
        row_number() over (partition by account_id order by month_end_date desc) as rn
    from {{ ref('int_moneybox__account_monthly_snapshots') }}
)

select
    s.account_id,
    s.month_end_balance as reconstructed_aum,
    a.current_platform_aum as platform_aum
from latest_snapshot s
join {{ ref('stg_moneybox__accounts') }} a
    on s.account_id = a.account_id
where s.rn = 1
  and s.month_end_balance <> a.current_platform_aum
