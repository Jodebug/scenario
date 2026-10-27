-- Minimal, PII-free projection: keys + lifecycle signal only.
-- Names, DOB, address and salary are intentionally NOT carried downstream.
{{ config(materialized='view') }}

select
    cast(user_id as bigint) as user_id,
    cast(profile_deleted_at as timestamp) as profile_deleted_at
from {{ source('moneybox_raw', 'users') }}
