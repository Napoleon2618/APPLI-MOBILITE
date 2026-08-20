create table if not exists public.session_exercise (
  session_id uuid not null references public.session (id) on delete cascade,
  exercise_id uuid not null references public.exercise (id) on delete cascade,
  position integer not null,
  primary key (session_id, exercise_id),
  unique (session_id, position)
);

comment on table public.session_exercise is
  'Ordered many-to-many association between session and exercise (data-model.md).';
comment on column public.session_exercise.position is
  'Execution order within the session.';

-- ON DELETE CASCADE on exercise_id: safe here because a BEFORE DELETE trigger
-- on public.exercise (see 0011_session_log.sql) intercepts the delete and
-- converts it to an archive (FR-023) whenever the exercise is referenced by
-- a session_log; the cascade only ever actually runs for exercises that have
-- never been followed by a client, where removing the composition row is
-- the correct behavior.

create or replace function public.check_session_exercise_same_coach()
returns trigger
language plpgsql
as $$
declare
  session_coach uuid;
  exercise_coach uuid;
begin
  select coach_id into session_coach from public.session where id = new.session_id;
  select coach_id into exercise_coach from public.exercise where id = new.exercise_id;
  if session_coach is null or exercise_coach is null or session_coach <> exercise_coach then
    raise exception 'session and exercise must belong to the same coach';
  end if;
  return new;
end;
$$;

drop trigger if exists session_exercise_same_coach on public.session_exercise;
create trigger session_exercise_same_coach
  before insert or update on public.session_exercise
  for each row
  execute function public.check_session_exercise_same_coach();
