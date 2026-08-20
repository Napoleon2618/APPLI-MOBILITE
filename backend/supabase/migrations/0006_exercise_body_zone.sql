create table if not exists public.exercise_body_zone (
  exercise_id uuid not null references public.exercise (id) on delete cascade,
  body_zone_id uuid not null references public.body_zone (id) on delete cascade,
  primary key (exercise_id, body_zone_id)
);

comment on table public.exercise_body_zone is
  'Many-to-many association between exercise and body_zone (data-model.md).';

-- Enforce that an exercise can only be associated with a body_zone owned by
-- the same coach (data-model.md constraint), since a CHECK constraint cannot
-- express a cross-table condition.
create or replace function public.check_exercise_body_zone_same_coach()
returns trigger
language plpgsql
as $$
declare
  exercise_coach uuid;
  zone_coach uuid;
begin
  select coach_id into exercise_coach from public.exercise where id = new.exercise_id;
  select coach_id into zone_coach from public.body_zone where id = new.body_zone_id;
  if exercise_coach is null or zone_coach is null or exercise_coach <> zone_coach then
    raise exception 'exercise and body_zone must belong to the same coach';
  end if;
  return new;
end;
$$;

drop trigger if exists exercise_body_zone_same_coach on public.exercise_body_zone;
create trigger exercise_body_zone_same_coach
  before insert or update on public.exercise_body_zone
  for each row
  execute function public.check_exercise_body_zone_same_coach();
