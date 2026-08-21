-- NOT part of the shipped schema. Local-only stub of the pieces of the
-- Supabase `auth` schema that our migrations/tests reference (auth.users,
-- auth.uid()), so migrations can be validated against a plain local
-- Postgres instance without the full Supabase stack. Mirrors the real
-- Supabase behavior closely enough for RLS testing: auth.uid() reads the
-- `request.jwt.claim.sub` GUC, same mechanism PostgREST uses in production.
create extension if not exists pgcrypto;

create schema if not exists auth;

create table if not exists auth.users (
  id uuid primary key default gen_random_uuid(),
  aud text,
  role text,
  email text,
  encrypted_password text,
  email_confirmed_at timestamptz,
  last_sign_in_at timestamptz,
  raw_app_meta_data jsonb,
  raw_user_meta_data jsonb,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  confirmation_token text,
  email_change text,
  email_change_token_new text,
  recovery_token text,
  instance_id uuid
);

create or replace function auth.uid() returns uuid
language sql stable
as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;

grant usage on schema auth to authenticated, anon;
grant select on auth.users to authenticated, anon;
grant usage on schema public to authenticated, anon;

-- Real Supabase projects grant table-level privileges to `authenticated`/
-- `anon` on every public-schema table by default (RLS then narrows what's
-- actually visible/writable per row) — a local plain-Postgres instance
-- doesn't do this automatically, so it's replicated here for parity. Run
-- LAST, after all migrations, so it covers tables created by them.
grant all on all tables in schema public to authenticated;
grant select on all tables in schema public to anon;
grant all on all sequences in schema public to authenticated;
grant execute on all functions in schema public to authenticated, anon;
