-- Finance view: month x product AUA. All-account AUM keeps residual
-- assets on reporting-closed accounts; reporting_open_aua is what the
-- board report shows. The gap is exposed, never silently netted off.
{{ config(materialized='table', cluster_by=['month_end_date'], tags=['finance']) }}

select
    s.month_end_date,
    s.product_type,
    count(distinct s.account_id) as accounts_with_assets,
    sum(s.month_end_balance) as all_account_aua,
    sum(case
            when s.reporting_open_at_month_end then s.month_end_balance
            else 0
        end) as reporting_open_aua,
    sum(s.month_end_balance)
        - sum(case
                   when s.reporting_open_at_month_end then s.month_end_balance
                   else 0
              end) as reconciliation_gap
from {{ ref('int_moneybox__account_monthly_snapshots') }} s
where s.month_end_balance > 0
group by s.month_end_date, s.product_type
