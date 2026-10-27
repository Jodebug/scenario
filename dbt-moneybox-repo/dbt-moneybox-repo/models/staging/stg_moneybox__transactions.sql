-- All source rows, duplicates intentionally retained at this layer.
{{ config(materialized='view') }}

select
    cast(txn_id as string) as txn_id,
    cast(account_id as bigint) as account_id,
    cast(user_id as bigint) as user_id,
    cast(txn_type as string) as txn_type,
    cast(amount as decimal(18,2)) as amount,
    cast(txn_ts as timestamp) as txn_ts
from {{ source('moneybox_raw', 'transactions') }}
