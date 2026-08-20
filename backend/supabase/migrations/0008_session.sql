create table if not exists public.session (
  id uuid primary key default gen_random_uuid(),
  coach_id uuid not null references public.coach (id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now()
);

create index if not exists session_coach_id_idx on public.session (coach_id);

comment on table public.session is
  'An ordered set of exercises created by a coach.';
