create table if not exists public.daily_formula (
  id uuid primary key default gen_random_uuid(),
  coach_id uuid not null references public.coach (id) on delete cascade,
  session_id uuid not null references public.session (id) on delete restrict,
  date date not null,
  unique (coach_id, date)
);

create index if not exists daily_formula_coach_id_idx on public.daily_formula (coach_id);

comment on table public.daily_formula is
  'Association between a date and a session for a given coach (FR-006). One per coach per date.';

create or replace function public.check_daily_formula_same_coach()
returns trigger
language plpgsql
as $$
declare
  session_coach uuid;
begin
  select coach_id into session_coach from public.session where id = new.session_id;
  if session_coach is null or session_coach <> new.coach_id then
    raise exception 'daily_formula.session_id must belong to the same coach';
  end if;
  return new;
end;
$$;

drop trigger if exists daily_formula_same_coach on public.daily_formula;
create trigger daily_formula_same_coach
  before insert or update on public.daily_formula
  for each row
  execute function public.check_daily_formula_same_coach();
