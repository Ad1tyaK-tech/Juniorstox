-- ============================================================
-- Juniorstox — Security Migration
-- Run this once in the Supabase SQL Editor (Dashboard → SQL Editor → New query)
-- ============================================================

-- ── 1. SESSIONS TABLE ────────────────────────────────────────────────────────
-- Stores one token per login/create. iOS app sends this token with every
-- authenticated request so RPCs can verify identity without direct table access.

create table if not exists sessions (
  token      uuid        primary key default gen_random_uuid(),
  username   text        not null references accounts(username) on delete cascade,
  expires_at timestamptz not null default (now() + interval '30 days')
);
create index if not exists sessions_username_idx   on sessions(username);
create index if not exists sessions_expires_at_idx on sessions(expires_at);

-- No RLS policies on sessions → no anon direct access.
alter table sessions enable row level security;


-- ── 2. LOCK DOWN accounts TABLE ──────────────────────────────────────────────
-- Drop whichever open policies existed. Names vary — drop all common variants.
-- If you're unsure of the names, run:
--   select policyname from pg_policies where tablename = 'accounts';
-- then add more drop statements below.

drop policy if exists "public read"       on accounts;
drop policy if exists "public write"      on accounts;
drop policy if exists "anon select"       on accounts;
drop policy if exists "anon update"       on accounts;
drop policy if exists "anon delete"       on accounts;
drop policy if exists "allow_anon_select" on accounts;
drop policy if exists "allow_anon_update" on accounts;
drop policy if exists "allow_anon_delete" on accounts;

-- RLS is already enabled. No policies = no anon REST access. Done.


-- ── 3. LOCK DOWN market_prices TABLE — keep public SELECT ────────────────────

drop policy if exists "public write"      on market_prices;
drop policy if exists "anon insert"       on market_prices;
drop policy if exists "anon update"       on market_prices;
drop policy if exists "anon delete"       on market_prices;
drop policy if exists "allow_anon_insert" on market_prices;
drop policy if exists "allow_anon_update" on market_prices;
drop policy if exists "allow_anon_delete" on market_prices;

-- Ensure the read policy exists (re-create if it was also dropped):
do $$
begin
  if not exists (
    select 1 from pg_policies
     where tablename = 'market_prices'
       and cmd        = 'SELECT'
  ) then
    execute 'create policy "public read" on market_prices for select using (true)';
  end if;
end $$;


-- ── 4. MODIFY login_account — add session token to return set ────────────────

drop function if exists login_account(text, text);

create or replace function login_account(p_username text, p_password text)
returns table (
  username               text,
  password_hash          text,
  keycode_hash           text,
  cash_balance           float8,
  starting_balance       float8,
  shares_owned_json      text,
  purchase_prices_json   text,
  net_worth_history_json text,
  last_snapshot_at       timestamptz,
  created_at             timestamptz,
  daily_challenge_json   text,
  achievements_json      text,
  settings_json          text,
  session_token          uuid
)
language plpgsql security definer set search_path = public
as $$
declare
  v_account accounts%rowtype;
  v_token   uuid;
begin
  select * into v_account from accounts a where a.username = p_username;
  if not found               then raise exception 'not_found';      end if;
  if v_account.password_hash <> p_password
                             then raise exception 'wrong_password'; end if;

  -- Prune expired sessions for this user
  delete from sessions where sessions.username = p_username and expires_at < now();

  -- Issue a new 30-day session
  insert into sessions (username) values (p_username) returning token into v_token;

  return query select
    v_account.username, v_account.password_hash, v_account.keycode_hash,
    v_account.cash_balance, v_account.starting_balance,
    v_account.shares_owned_json, v_account.purchase_prices_json,
    v_account.net_worth_history_json,
    v_account.last_snapshot_at, v_account.created_at,
    v_account.daily_challenge_json, v_account.achievements_json,
    v_account.settings_json,
    v_token;
end; $$;


-- ── 5. MODIFY create_account — add session token to return set ───────────────

drop function if exists create_account(text, text);

create or replace function create_account(p_username text, p_password text)
returns table (
  username               text,
  password_hash          text,
  keycode_hash           text,
  cash_balance           float8,
  starting_balance       float8,
  shares_owned_json      text,
  purchase_prices_json   text,
  net_worth_history_json text,
  last_snapshot_at       timestamptz,
  created_at             timestamptz,
  daily_challenge_json   text,
  achievements_json      text,
  settings_json          text,
  session_token          uuid
)
language plpgsql security definer set search_path = public
as $$
declare
  v_account accounts%rowtype;
  v_token   uuid;
begin
  if exists (select 1 from accounts where accounts.username = p_username) then
    raise exception 'username_taken';
  end if;

  insert into accounts (username, password_hash)
  values (p_username, p_password)
  returning * into v_account;

  insert into sessions (username) values (p_username) returning token into v_token;

  return query select
    v_account.username, v_account.password_hash, v_account.keycode_hash,
    v_account.cash_balance, v_account.starting_balance,
    v_account.shares_owned_json, v_account.purchase_prices_json,
    v_account.net_worth_history_json,
    v_account.last_snapshot_at, v_account.created_at,
    v_account.daily_challenge_json, v_account.achievements_json,
    v_account.settings_json,
    v_token;
end; $$;


-- ── 6. fetch_account — session-authenticated account read ────────────────────

create or replace function fetch_account(p_username text, p_session_token uuid)
returns setof accounts
language plpgsql security definer set search_path = public
as $$
begin
  if not exists (
    select 1 from sessions
     where token      = p_session_token
       and username   = p_username
       and expires_at > now()
  ) then
    raise exception 'unauthorized';
  end if;

  return query select * from accounts where accounts.username = p_username;
end; $$;


-- ── 7. save_account — session-authenticated account update ───────────────────
-- Note: password_hash is intentionally excluded. Password changes go through
-- reset_password only.

create or replace function save_account(
  p_session_token          uuid,
  p_keycode_hash           text,
  p_cash_balance           float8,
  p_starting_balance       float8,
  p_shares_owned_json      text,
  p_purchase_prices_json   text,
  p_net_worth_history_json text,
  p_last_snapshot_at       timestamptz,
  p_daily_challenge_json   text,
  p_achievements_json      text,
  p_settings_json          text
)
returns void
language plpgsql security definer set search_path = public
as $$
declare v_username text;
begin
  select username into v_username from sessions
   where token = p_session_token and expires_at > now();
  if not found then raise exception 'unauthorized'; end if;

  update accounts set
    keycode_hash           = p_keycode_hash,
    cash_balance           = p_cash_balance,
    starting_balance       = p_starting_balance,
    shares_owned_json      = p_shares_owned_json,
    purchase_prices_json   = p_purchase_prices_json,
    net_worth_history_json = p_net_worth_history_json,
    last_snapshot_at       = p_last_snapshot_at,
    daily_challenge_json   = p_daily_challenge_json,
    achievements_json      = p_achievements_json,
    settings_json          = p_settings_json
  where accounts.username = v_username;
end; $$;


-- ── 8. delete_account — session-authenticated account deletion ───────────────

create or replace function delete_account(p_session_token uuid)
returns void
language plpgsql security definer set search_path = public
as $$
declare v_username text;
begin
  select username into v_username from sessions
   where token = p_session_token and expires_at > now();
  if not found then raise exception 'unauthorized'; end if;

  delete from accounts where accounts.username = v_username;
  -- sessions cascade-delete via the foreign key on delete cascade
end; $$;


-- ── 9. find_username_by_keycode — returns only the username, not the account ─
-- Used by ForgotPassword (phase 1) and isKeycodeTaken (account creation check).
-- Intentionally returns only username — no password hash, no account data.

create or replace function find_username_by_keycode(p_keycode_hash text)
returns table(username text)
language plpgsql security definer set search_path = public
as $$
begin
  return query
    select a.username from accounts a
     where a.keycode_hash = p_keycode_hash
       and a.keycode_hash <> '';
end; $$;


-- ── 10. reset_password — atomic keycode-authenticated password reset ──────────
-- The keycode hash is the credential for this operation (user is locked out).
-- Invalidates all existing sessions on success so stale tokens can't be reused.

create or replace function reset_password(p_keycode_hash text, p_new_password_hash text)
returns table(username text)
language plpgsql security definer set search_path = public
as $$
declare v_username text;
begin
  if p_keycode_hash = '' then raise exception 'invalid_keycode'; end if;

  select a.username into v_username from accounts a
   where a.keycode_hash = p_keycode_hash;
  if not found then raise exception 'not_found'; end if;

  update accounts set password_hash = p_new_password_hash
   where accounts.username = v_username;

  -- Invalidate all sessions so the old password can't be reused via a live token
  delete from sessions where sessions.username = v_username;

  return query select v_username;
end; $$;
