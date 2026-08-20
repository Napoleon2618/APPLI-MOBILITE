create table if not exists public.invite_code (
  id uuid primary key default gen_random_uuid(),
  coach_id uuid not null references public.coach (id) on delete cascade,
  code text not null unique,
  created_at timestamptz not null default now(),
  used_at timestamptz,
  used_by_client_id uuid references public.client (id) on delete set null
);

create index if not exists invite_code_coach_id_idx on public.invite_code (coach_id);

comment on table public.invite_code is
  'Coach-generated token letting a client self-register and auto-attach to that coach (FR-022a).';
comment on column public.invite_code.used_at is
  'Set once, at first (and only) successful redemption via redeem_invite_code().';
