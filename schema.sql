-- =====================================================================
-- TALLY DATABASE SETUP
-- Copy ALL of this file and paste it into the Supabase SQL editor, then
-- press "Run". It creates the three tables Tally needs and turns on the
-- security rules (row-level-security policies) that keep each person's
-- data private to their own account. It is safe to run once; running it
-- again does nothing harmful (everything below is written to be re-runnable).
-- =====================================================================

-- =====================================================================
-- TALLY CLOUD SCHEMA  (Supabase / Postgres)
-- Run this verbatim in the Supabase SQL editor. Safe to re-run.
-- Three tables mirror the three localStorage keys:
--   transactions  <- tally_txns      (real rows; queryable + dedupeable)
--   merchant_overrides <- tally_overrides (one row per normalized merchant)
--   plan          <- tally_plan       (one tiny jsonb blob per user)
-- Security model: RLS enabled AND forced on every table; anon role hard-
-- revoked (logged-out Tally uses only GoTrue, never PostgREST); user_id
-- defaults to auth.uid() and is pinned by WITH CHECK on every write.
-- =====================================================================

-- gen_random_uuid() lives in pgcrypto (present by default on Supabase).
create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------
-- 1. TRANSACTIONS  (one row per imported purchase)
--    amount: positive = money spent (client already normalizes WF/Amex).
--    ext_id: the client's EXISTING dedupe identity, supplied verbatim by
--    the client so client and server can never disagree on "same row":
--      ext_id = date + '|' + description + '|' + amount   (RAW js number,
--      i.e. NOT zero-padded: "2026-06-01|Netflix.com|15.5", "...|70").
--    This matches dedupe() at index.html line ~1398 exactly. Do NOT use a
--    generated/normalized key here -- it would diverge from the client and
--    re-create duplicates.
-- ---------------------------------------------------------------------
create table if not exists public.transactions (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid not null default auth.uid()
                references auth.users (id) on delete cascade,
  txn_date    date          not null,                       -- 'YYYY-MM-DD'
  description text          not null check (char_length(description) <= 500),
  amount      numeric(12,2) not null check (amount >= 0),    -- positive = spent
  ext_id      text          not null check (char_length(ext_id) <= 600),
  created_at  timestamptz   not null default now(),
  -- One logical transaction per user. The ON CONFLICT target for idempotent
  -- re-imports: importing the same CSV twice (or overlapping ranges on two
  -- devices) collapses to one row.
  unique (user_id, ext_id)
);

-- Fast per-user month windowing / ordering (mirrors monthsAvailable()).
create index if not exists transactions_user_date_idx
  on public.transactions (user_id, txn_date desc);

-- ---------------------------------------------------------------------
-- 2. MERCHANT_OVERRIDES  (learned merchant -> category; one row per merchant)
--    merchant = normMerchant(description): lowercased, non-alpha stripped,
--    whitespace collapsed, first 3 words (index.html line ~385). The client
--    sends this key as-is; the DB stores it verbatim (no re-normalization).
-- ---------------------------------------------------------------------
create table if not exists public.merchant_overrides (
  user_id    uuid not null default auth.uid()
               references auth.users (id) on delete cascade,
  merchant   text not null check (char_length(merchant) <= 120),
  category   text not null check (char_length(category) <= 40),
  updated_at timestamptz not null default now(),
  primary key (user_id, merchant)            -- upsert target; natural per-user key
);

-- ---------------------------------------------------------------------
-- 3. PLAN  (single jsonb blob per user; mirrors tally_plan)
--    data = {v, income:{'YYYY-MM':num}, split:{needs,wants,savings}, bucketMap:{}}
-- ---------------------------------------------------------------------
create table if not exists public.plan (
  user_id    uuid primary key default auth.uid()
               references auth.users (id) on delete cascade,
  data       jsonb not null default '{}'::jsonb
               check (pg_column_size(data) <= 100000),   -- ~100KB ceiling
  updated_at timestamptz not null default now()
);

-- =====================================================================
-- ROW LEVEL SECURITY  -- the real authorization boundary.
-- Enable AND force, so even a table-owner path is constrained. anon and
-- authenticated are not owners, so they can never bypass.
-- =====================================================================
alter table public.transactions       enable row level security;
alter table public.merchant_overrides enable row level security;
alter table public.plan               enable row level security;

alter table public.transactions       force row level security;
alter table public.merchant_overrides force row level security;
alter table public.plan               force row level security;

-- ---- TRANSACTIONS policies (one per verb; no FOR ALL) ----
drop policy if exists txn_select on public.transactions;
create policy txn_select on public.transactions
  for select to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists txn_insert on public.transactions;
create policy txn_insert on public.transactions
  for insert to authenticated
  with check (user_id = (select auth.uid()));

drop policy if exists txn_update on public.transactions;
create policy txn_update on public.transactions
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

drop policy if exists txn_delete on public.transactions;
create policy txn_delete on public.transactions
  for delete to authenticated
  using (user_id = (select auth.uid()));

-- ---- MERCHANT_OVERRIDES policies ----
drop policy if exists ovr_select on public.merchant_overrides;
create policy ovr_select on public.merchant_overrides
  for select to authenticated using (user_id = (select auth.uid()));
drop policy if exists ovr_insert on public.merchant_overrides;
create policy ovr_insert on public.merchant_overrides
  for insert to authenticated with check (user_id = (select auth.uid()));
drop policy if exists ovr_update on public.merchant_overrides;
create policy ovr_update on public.merchant_overrides
  for update to authenticated using (user_id = (select auth.uid()))
                              with check (user_id = (select auth.uid()));
drop policy if exists ovr_delete on public.merchant_overrides;
create policy ovr_delete on public.merchant_overrides
  for delete to authenticated using (user_id = (select auth.uid()));

-- ---- PLAN policies ----
drop policy if exists plan_select on public.plan;
create policy plan_select on public.plan
  for select to authenticated using (user_id = (select auth.uid()));
drop policy if exists plan_insert on public.plan;
create policy plan_insert on public.plan
  for insert to authenticated with check (user_id = (select auth.uid()));
drop policy if exists plan_update on public.plan;
create policy plan_update on public.plan
  for update to authenticated using (user_id = (select auth.uid()))
                             with check (user_id = (select auth.uid()));
drop policy if exists plan_delete on public.plan;
create policy plan_delete on public.plan
  for delete to authenticated using (user_id = (select auth.uid()));

-- =====================================================================
-- keep plan.updated_at / merchant_overrides.updated_at honest on writes
-- =====================================================================
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end $$;

drop trigger if exists plan_touch on public.plan;
create trigger plan_touch before update on public.plan
  for each row execute function public.touch_updated_at();

drop trigger if exists ovr_touch on public.merchant_overrides;
create trigger ovr_touch before update on public.merchant_overrides
  for each row execute function public.touch_updated_at();

-- =====================================================================
-- HARD-REVOKE the anon role from all three tables. Logged-out Tally never
-- reads/writes data; anon only needs GoTrue (signup/login/reset). This is
-- defense in depth: even a dropped/loose policy can't leak to anon.
-- 'authenticated' keeps table privileges; RLS narrows them to own rows.
-- =====================================================================
revoke all on public.transactions       from anon;
revoke all on public.merchant_overrides from anon;
revoke all on public.plan               from anon;

grant select, insert, update, delete on public.transactions       to authenticated;
grant select, insert, update, delete on public.merchant_overrides to authenticated;
grant select, insert, update, delete on public.plan               to authenticated;
