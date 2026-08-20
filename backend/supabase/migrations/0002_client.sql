create table if not exists public.client (
  id uuid primary key references auth.users (id) on delete cascade,
  coach_id uuid not null references public.coach (id) on delete restrict,
  display_name text not null,
  created_at timestamptz not null default now()
);

create index if not exists client_coach_id_idx on public.client (coach_id);

comment on table public.client is
  'A client account (consultation role), attached to exactly one coach (FR-021).';
comment on column public.client.coach_id is
  'Fixed at creation, not modifiable by the client afterwards (FR-021).';
