-- Every Closed account must resolve to an effective reporting closure
-- date (via correction or source value).
select
    account_id,
    source_status,
    lifecycle_quality_status
from {{ ref('int_moneybox__account_lifecycle') }}
where source_status = 'Closed'
  and effective_reporting_closed_at is null
