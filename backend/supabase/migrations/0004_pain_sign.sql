create table if not exists public.pain_sign (
  id uuid primary key default gen_random_uuid(),
  coach_id uuid not null references public.coach (id) on delete cascade,
  label text not null,
  created_at timestamptz not null default now()
);

create index if not exists pain_sign_coach_id_idx on public.pain_sign (coach_id);

comment on table public.pain_sign is
  'Plain-language, non-medical pain description defined by a coach (FR-009, FR-016).';
