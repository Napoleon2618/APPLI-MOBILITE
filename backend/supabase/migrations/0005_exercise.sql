create table if not exists public.exercise (
  id uuid primary key default gen_random_uuid(),
  coach_id uuid not null references public.coach (id) on delete cascade,
  name text not null,
  description text not null,
  instructions text not null,
  youtube_video_url text,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists exercise_coach_id_idx on public.exercise (coach_id);
create index if not exists exercise_active_idx on public.exercise (coach_id) where archived_at is null;

comment on table public.exercise is
  'A mobility/stretching exercise created by a coach.';
comment on column public.exercise.youtube_video_url is
  'Demonstration video hosted on YouTube; no video file is stored in Supabase Storage (data-model.md).';
comment on column public.exercise.archived_at is
  'Set instead of a hard delete when the exercise is referenced by a session_log (FR-023). Terminal state, not reversible in this spec.';

-- Keep updated_at current on every row change.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists exercise_set_updated_at on public.exercise;
create trigger exercise_set_updated_at
  before update on public.exercise
  for each row
  execute function public.set_updated_at();
