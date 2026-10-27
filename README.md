# moneybox_analytics (dbt)

dbt project for the Moneybox practice pipeline: monthly AUA, active accounts
and active users for the Growth and Finance teams, built on the fictional
practice data in `workspace.moneybox_practice_raw` (frozen as of 2026-03-31).

## Structure

* `models/staging` — typed, renamed 1:1 views over the raw source; no business logic
* `models/intermediate` — canonical transactions, account lifecycle (closure
  corrections + reporting closures), month spine, point-in-time month-end snapshots
* `models/marts/finance` — month x product AUA with the all-account vs
  reporting-open reconciliation gap kept visible
* `models/marts/growth` — monthly active accounts and active users
* `models/marts/audit` — exception report for the Finance reconciliation
* `seeds` — `account_closure_corrections`: Finance/Ops-owned correction facts
  (currently mirrors the UC table of the same name)
* `tests` — singular edge-case tests
* `macros/generate_schema_name.sql` — prefixes custom schemas with the target
  schema so dev/prod never collide (e.g. `moneybox_dbt_dev_staging`)

## Running

1. Copy `profiles.example.yml` to `~/.dbt/profiles.yml`; fill in `host` and
   `http_path` (a Serverless SQL warehouse), then authenticate with dbt CLI OAuth.
2. `dbt deps && dbt build` (models + seeds + tests in dependency order)
3. `dbt docs generate && dbt docs serve` for the lineage graph

Alternative: run `dbt build` as a Lakeflow Job dbt task on a schedule
(e.g. nightly after source loads).

## Design decisions (data quality)

* Duplicates: exact duplicates are collapsed in `int_moneybox__transactions_canonical`
  with audit columns (`source_row_count`, `duplicate_rows_removed`). Conflicting
  versions of the same `txn_id` are NOT auto-resolved: they survive as separate
  rows and fail the uniqueness test — a data incident to investigate, not a fix.
* Missing closure date (account 104): corrected via the closure-corrections seed,
  flagged `closure_date_corrected`; never inferred by the pipeline.
* Deleted profile with funded account (105): reporting-only closure on the
  deletion date. Assets stay in all-account AUM; the gap is exposed as
  `reconciliation_gap` in the finance mart, never silently netted off.
* Zero-balance open accounts / churn and reactivation: snapshots are point-in-time
  and never restated; activity is whatever the balance was at month end.

## Definitions

* reporting-open = not effectively closed, where effective closure takes
  correction > source closure date > profile deletion date
* active account = positive month-end balance AND reporting-open at month end

## PII

`stg_moneybox__users` deliberately drops name, DOB, address and salary — marts
consume keys only. Open questions for the DPO before widening grants:
retention window for transaction history vs right-to-erasure, pseudonymisation
of user_id in Growth marts, legitimate basis for holding salary at all.

## Databricks notes

* Adapter: `dbt-databricks`; run against a Serverless SQL warehouse (Photon)
* Marts and snapshots liquid-clustered on `month_end_date`
* One UC schema per layer; dbt lineage flows into Unity Catalog automatically
