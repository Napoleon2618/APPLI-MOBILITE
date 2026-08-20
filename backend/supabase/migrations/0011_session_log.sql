create table if not exists public.session_log (
  id uuid primary key default gen_random_uuid(),
  client_id uuid not null references public.client (id) on delete cascade,
  session_id uuid not null references public.session (id) on delete restrict,
  completed_at timestamptz not null default now(),
  source_mode text not null check (source_mode in ('daily_formula', 'body_zone', 'pain_sign'))
);

create index if not exists session_log_client_id_idx on public.session_log (client_id);
create index if not exists session_log_session_id_idx on public.session_log (session_id);

comment on table public.session_log is
  'Record that a client followed a session on a given date (FR-013). Write-once, never updated.';
comment on column public.session_log.source_mode is
  'Which navigation mode led to this followed session — for later product analysis.';

-- FR-023: deleting an exercise referenced (via session_exercise) by a
-- session that has at least one session_log row archives it instead of
-- deleting it. Returning NULL from a BEFORE DELETE trigger cancels the
-- delete; the UPDATE below performs the archive instead.
create or replace function public.archive_instead_of_delete_exercise()
returns trigger
language plpgsql
as $$
declare
  is_referenced_by_history boolean;
begin
  select exists (
    select 1
    from public.session_exercise se
    join public.session_log sl on sl.session_id = se.session_id
    where se.exercise_id = old.id
  ) into is_referenced_by_history;

  if is_referenced_by_history then
    update public.exercise set archived_at = now() where id = old.id;
    return null; -- cancel the DELETE; the exercise row is kept (archived).
  end if;

  return old; -- not referenced by any followed session: allow the hard delete.
end;
$$;

drop trigger if exists exercise_archive_instead_of_delete on public.exercise;
create trigger exercise_archive_instead_of_delete
  before delete on public.exercise
  for each row
  execute function public.archive_instead_of_delete_exercise();
