alter table public.invite_code enable row level security;

-- A coach reads/creates only their own invite codes.
drop policy if exists invite_code_select_own on public.invite_code;
create policy invite_code_select_own on public.invite_code
  for select to authenticated
  using (coach_id = auth.uid());

drop policy if exists invite_code_insert_own on public.invite_code;
create policy invite_code_insert_own on public.invite_code
  for insert to authenticated
  with check (coach_id = auth.uid());

-- No UPDATE/DELETE policy for regular authenticated users, and no policy at
-- all grants client/anon access: redemption is handled exclusively by
-- redeem_invite_code() (SECURITY DEFINER, next migration), which bypasses
-- RLS to validate and consume a code (contracts/auth.md, data-access.md).
