-- Extension needed for gen_random_uuid() used by every table's primary key below.
create extension if not exists pgcrypto;

create table if not exists public.coach (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null,
  created_at timestamptz not null default now()
);

comment on table public.coach is
  'A coach account (admin/content role), owner of its own content space (data-model.md).';
