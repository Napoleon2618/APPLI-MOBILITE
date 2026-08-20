create table if not exists public.exercise_pain_sign (
  exercise_id uuid not null references public.exercise (id) on delete cascade,
  pain_sign_id uuid not null references public.pain_sign (id) on delete cascade,
  primary key (exercise_id, pain_sign_id)
);

comment on table public.exercise_pain_sign is
  'Many-to-many association between exercise and pain_sign (data-model.md).';

create or replace function public.check_exercise_pain_sign_same_coach()
returns trigger
language plpgsql
as $$
declare
  exercise_coach uuid;
  sign_coach uuid;
begin
  select coach_id into exercise_coach from public.exercise where id = new.exercise_id;
  select coach_id into sign_coach from public.pain_sign where id = new.pain_sign_id;
  if exercise_coach is null or sign_coach is null or exercise_coach <> sign_coach then
    raise exception 'exercise and pain_sign must belong to the same coach';
  end if;
  return new;
end;
$$;

drop trigger if exists exercise_pain_sign_same_coach on public.exercise_pain_sign;
create trigger exercise_pain_sign_same_coach
  before insert or update on public.exercise_pain_sign
  for each row
  execute function public.check_exercise_pain_sign_same_coach();
