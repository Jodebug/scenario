-- Accounts with source status and closure dates preserved for validation.
{{ config(materialized='view') }}

select
    cast(account_id as bigint) as account_id,
    cast(user_id as bigint) as user_id,
    cast(product_type as string) as product_type,
    cast(opened_at as date) as opened_at,
    cast(closed_at as date) as closed_at,
    cast(status as string) as status,
    cast(plan_value as decimal(18,2)) as current_platform_aum
from {{ source('moneybox_raw', 'accounts') }}
