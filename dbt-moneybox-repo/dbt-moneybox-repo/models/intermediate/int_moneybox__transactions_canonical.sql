-- Deduplicate exact-duplicate events and keep an audit trail.
-- Conflicting versions of the same txn_id are NOT auto-resolved: they
-- survive as separate rows and fail the uniqueness test in schema.yml.
{{ config(materialized='table') }}

with deduplicated as (
    select
        txn_id,
        account_id,
        user_id,
        txn_type,
        amount,
        txn_ts,
        count(*) as source_row_count
    from {{ ref('stg_moneybox__transactions') }}
    group by txn_id, account_id, user_id, txn_type, amount, txn_ts
)

select
    txn_id,
    account_id,
    user_id,
    txn_type,
    amount,
    txn_ts,
    case
        when txn_type in ('deposit', 'govt_bonus') then amount
        when txn_type in ('withdrawal', 'platform_fee') then -amount
        else null
    end as signed_amount,
    source_row_count,
    source_row_count - 1 as duplicate_rows_removed
from deduplicated
