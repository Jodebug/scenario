-- One row per account: source status, closure corrections, and reporting
-- closures from profile deletion, resolved into a single effective closure
-- date and a data-quality status.
-- Effective closure precedence: correction > source closure date > profile deletion.
{{ config(materialized='table') }}

select
    a.account_id,
    a.user_id,
    a.product_type,
    a.opened_at,
    a.status as source_status,
    a.closed_at as source_closed_at,
    c.corrected_closed_at,
    cast(u.profile_deleted_at as date) as profile_deleted_date,
    case
        when c.corrected_closed_at is not null then c.corrected_closed_at
        when a.closed_at is not null then a.closed_at
        when u.profile_deleted_at is not null then cast(u.profile_deleted_at as date)
        else null
    end as effective_reporting_closed_at,
    case
        when c.corrected_closed_at is not null
            then concat('closure date corrected: ', c.correction_reason)
        when a.closed_at is not null then 'closed in source'
        when u.profile_deleted_at is not null then 'reporting closure: profile deleted'
        else null
    end as reporting_closure_reason,
    case
        when c.corrected_closed_at is not null then 'closure_date_corrected'
        when a.status = 'Closed' and a.closed_at is null then 'missing_closure_date'
        when u.profile_deleted_at is not null and a.status = 'Open'
            then 'reporting_closed_profile_deleted'
        when a.closed_at is not null then 'closed_in_source'
        else 'open'
    end as lifecycle_quality_status
from {{ ref('stg_moneybox__accounts') }} a
left join {{ ref('stg_moneybox__users') }} u
    on a.user_id = u.user_id
left join {{ ref('account_closure_corrections') }} c
    on a.account_id = c.account_id
