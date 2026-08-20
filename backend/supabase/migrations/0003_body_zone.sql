create table if not exists public.body_zone (
  id uuid primary key default gen_random_uuid(),
  coach_id uuid not null references public.coach (id) on delete cascade,
  label text not null,
  created_at timestamptz not null default now()
);

create index if not exists body_zone_coach_id_idx on public.body_zone (coach_id);

comment on table public.body_zone is
  'Anatomical location category defined by a coach (e.g. back, shoulders, hips).';
