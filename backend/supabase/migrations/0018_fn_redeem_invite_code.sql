-- FR-022a: a client who has already created their Supabase Auth identity
-- (email + password) calls this function, authenticated, to consume an
-- invite code and attach themselves to the corresponding coach.
-- SECURITY DEFINER: bypasses RLS to read invite_code/coach and insert into
-- client, which regular authenticated users cannot do directly (by design —
-- see contracts/data-access.md). Row-locks the invite_code to avoid a race
-- where two concurrent calls both redeem the same code.
create or replace function public.redeem_invite_code(p_code text)
returns uuid -- the coach_id the caller is now attached to
language plpgsql
security definer
set search_path = public
as $$
declare
  v_invite public.invite_code%rowtype;
  v_caller uuid := auth.uid();
  v_caller_email text;
begin
  if v_caller is null then
    raise exception 'not authenticated';
  end if;

  if exists (select 1 from public.client where id = v_caller) then
    raise exception 'this account is already attached to a coach';
  end if;
  if exists (select 1 from public.coach where id = v_caller) then
    raise exception 'a coach account cannot redeem an invite code';
  end if;

  select * into v_invite from public.invite_code where code = p_code for update;

  if not found then
    raise exception 'invalid invite code';
  end if;
  if v_invite.used_at is not null then
    raise exception 'invite code already used';
  end if;

  select email into v_caller_email from auth.users where id = v_caller;

  insert into public.client (id, coach_id, display_name)
  values (v_caller, v_invite.coach_id, coalesce(v_caller_email, 'Client'));

  update public.invite_code
    set used_at = now(), used_by_client_id = v_caller
    where id = v_invite.id;

  return v_invite.coach_id;
end;
$$;

grant execute on function public.redeem_invite_code(text) to authenticated;
