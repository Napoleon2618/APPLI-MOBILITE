-- Local-dev seed data (T027). Applied automatically by `supabase start` /
-- `supabase db reset`, or pasted manually into the Supabase Dashboard's
-- SQL Editor for a cloud project. Matches quickstart.md's stated
-- prerequisites. Safe to re-run (every insert is a no-op on conflict).
--
-- Demo credentials (demo/test data — replace before going further than
-- manual testing):
--   Coach:    coach1@example.com    / CoachPass123!
--   Client A: clienta@example.com   / ClientPass123!  (seeded directly)
--   Client B: clientb@example.com   / ClientPass123!  (seeded directly)
-- A fresh, unused invite code ('DEMO-INVITE-1') is also seeded so the
-- invite-code signup flow (FR-022a) can be exercised live in the app.
--
-- IMPORTANT (hosted/cloud projects): inserting directly into auth.users
-- like this may not be enough to log in on every Supabase Auth version —
-- newer versions also expect a matching row in auth.identities. If the
-- demo accounts below don't let you log in after running this script,
-- create them instead via Dashboard → Authentication → Users → Add user
-- (check "Auto Confirm User"), using the same emails/passwords, then
-- re-run just the "public.*" inserts below (the auth.users block will
-- simply no-op if those accounts already exist from the dashboard).

-- auth.users rows use the standard local-seed pattern (bcrypt via pgcrypto)
-- since this runs as plain SQL, not through the Auth API.
insert into auth.users (
  instance_id, id, aud, role, email, encrypted_password,
  email_confirmed_at, last_sign_in_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, email_change, email_change_token_new, recovery_token
) values
  (
    '00000000-0000-0000-0000-000000000000',
    'c0000000-0000-0000-0000-000000000001',
    'authenticated', 'authenticated',
    'coach1@example.com', crypt('CoachPass123!', gen_salt('bf')),
    now(), now(),
    '{"provider":"email","providers":["email"]}', '{}',
    now(), now(), '', '', '', ''
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    'c1000000-0000-0000-0000-000000000001',
    'authenticated', 'authenticated',
    'clienta@example.com', crypt('ClientPass123!', gen_salt('bf')),
    now(), now(),
    '{"provider":"email","providers":["email"]}', '{}',
    now(), now(), '', '', '', ''
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    'c1000000-0000-0000-0000-000000000002',
    'authenticated', 'authenticated',
    'clientb@example.com', crypt('ClientPass123!', gen_salt('bf')),
    now(), now(),
    '{"provider":"email","providers":["email"]}', '{}',
    now(), now(), '', '', '', ''
  )
on conflict (id) do nothing;

insert into public.coach (id, display_name) values
  ('c0000000-0000-0000-0000-000000000001', 'Coach Démo')
on conflict (id) do nothing;

insert into public.client (id, coach_id, display_name) values
  ('c1000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Client A (démo)'),
  ('c1000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000001', 'Client B (démo)')
on conflict (id) do nothing;

-- A fresh invite code, ready to redeem via the app's signup screen (FR-022a).
insert into public.invite_code (id, coach_id, code) values
  ('c2000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'DEMO-INVITE-1')
on conflict (id) do nothing;

-- Content: zones, signs, exercises, associations.
insert into public.body_zone (id, coach_id, label) values
  ('c3000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Dos'),
  ('c3000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000001', 'Épaules'),
  ('c3000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000001', 'Hanches'),
  ('c3000000-0000-0000-0000-000000000004', 'c0000000-0000-0000-0000-000000000001', 'Genoux'),
  ('c3000000-0000-0000-0000-000000000005', 'c0000000-0000-0000-0000-000000000001', 'Chevilles (sans exercice associé — pour tester l''état vide)')
on conflict (id) do nothing;

insert into public.pain_sign (id, coach_id, label) values
  ('c4000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Douleur au coude'),
  ('c4000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000001', 'Ça tire dans le bas du dos'),
  ('c4000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000001', 'Épaule raide le matin'),
  ('c4000000-0000-0000-0000-000000000004', 'c0000000-0000-0000-0000-000000000001', 'Genou qui craque (sans exercice associé — pour tester l''état vide)')
on conflict (id) do nothing;

insert into public.exercise (id, coach_id, name, description, instructions, youtube_video_url) values
  (
    'c5000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001',
    'Étirement du chat-vache', 'Mobilise en douceur toute la colonne vertébrale.',
    'À quatre pattes, alternez dos rond et dos creux pendant 10 respirations.',
    'https://www.youtube.com/watch?v=demo-cat-cow'
  ),
  (
    'c5000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000001',
    'Cercles d''épaules', 'Détend les épaules et le haut du dos.',
    'Faites 10 grands cercles d''épaules vers l''avant puis 10 vers l''arrière.',
    'https://www.youtube.com/watch?v=demo-shoulder-circles'
  ),
  (
    'c5000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000001',
    'Étirement du coude', 'Soulage les tensions autour du coude.',
    'Bras tendu, tirez doucement les doigts vers vous pendant 20 secondes de chaque côté.',
    null
  )
on conflict (id) do nothing;

insert into public.exercise_body_zone (exercise_id, body_zone_id) values
  ('c5000000-0000-0000-0000-000000000001', 'c3000000-0000-0000-0000-000000000001'),
  ('c5000000-0000-0000-0000-000000000002', 'c3000000-0000-0000-0000-000000000002')
on conflict (exercise_id, body_zone_id) do nothing;

insert into public.exercise_pain_sign (exercise_id, pain_sign_id) values
  ('c5000000-0000-0000-0000-000000000001', 'c4000000-0000-0000-0000-000000000002'),
  ('c5000000-0000-0000-0000-000000000002', 'c4000000-0000-0000-0000-000000000003'),
  ('c5000000-0000-0000-0000-000000000003', 'c4000000-0000-0000-0000-000000000001')
on conflict (exercise_id, pain_sign_id) do nothing;

insert into public.session (id, coach_id, name) values
  ('c6000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', 'Réveil musculaire du matin')
on conflict (id) do nothing;

insert into public.session_exercise (session_id, exercise_id, position) values
  ('c6000000-0000-0000-0000-000000000001', 'c5000000-0000-0000-0000-000000000001', 1),
  ('c6000000-0000-0000-0000-000000000001', 'c5000000-0000-0000-0000-000000000002', 2)
on conflict (session_id, exercise_id) do nothing;

insert into public.daily_formula (coach_id, session_id, date) values
  ('c0000000-0000-0000-0000-000000000001', 'c6000000-0000-0000-0000-000000000001', current_date)
on conflict (coach_id, date) do nothing;
