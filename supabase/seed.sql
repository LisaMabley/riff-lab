-- Local development data. Runs after migrations on `supabase db reset`.
-- Three users who have completed onboarding. They have no auth identities yet, so they can't
-- sign in. That comes with the sign-in ticket.

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change
)
values
  ('00000000-0000-4000-8000-000000000001', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'maya@example.test', '', now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-4000-8000-000000000002', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'jo@example.test', '', now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', ''),
  ('00000000-0000-4000-8000-000000000003', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'sam@example.test', '', now(),
   '{"provider":"email","providers":["email"]}', '{}', now(), now(), '', '', '', '');

insert into public.profiles (id, username, display_name, bio, age_confirmed_at)
values
  ('00000000-0000-4000-8000-000000000001', 'maya', 'Maya', 'Thrift store maximalist.', now()),
  ('00000000-0000-4000-8000-000000000002', 'jo.makes', 'Jo', null, now()),
  ('00000000-0000-4000-8000-000000000003', 'sam_k', 'Sam K', 'Mostly black, sometimes more black.', now());
