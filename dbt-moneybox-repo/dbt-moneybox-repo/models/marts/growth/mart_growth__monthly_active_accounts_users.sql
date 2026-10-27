-- Growth view: headline monthly active accounts and active users.
{{ config(materialized='table', cluster_by=['month_end_date'], tags=['growth']) }}

select
    month_end_date,
    count(distinct account_id) as active_accounts,
    count(distinct user_id) as active_users,
    sum(month_end_balance) as active_account_aua
from {{ ref('int_moneybox__account_monthly_snapshots') }}
where active_at_month_end
group by month_end_date
