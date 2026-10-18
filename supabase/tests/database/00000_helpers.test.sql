-- Test helpers, installed into a `tests` schema in the local database. This file runs first
-- (alphabetical order) and isn't wrapped in a transaction, so the helpers persist for the
-- other test files. `supabase db reset` removes them.
--
-- Usage in a test:
--   select tests.create_profile('maya');   -- as the default superuser, during setup
--   select tests.authenticate_as('maya');  -- act as Maya (role authenticated + JWT claims)
--   select tests.authenticate_as_anon();   -- act as a signed-out visitor
--   select tests.as_superuser();           -- back to the test runner's role

create extension if not exists pgtap with schema extensions;

create schema if not exists tests;
grant usage on schema tests to anon, authenticated;

create or replace function tests.create_user(p_identifier text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid := gen_random_uuid();
begin
  insert into auth.users (
    id, instance_id, aud, role, email, raw_app_meta_data, raw_user_meta_data,
    created_at, updated_at
  )
  values (
    v_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
    p_identifier || '@tests.local', '{}', '{}', now(), now()
  );
  return v_id;
end;
$$;

create or replace function tests.get_user_id(p_identifier text)
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
  select id from auth.users where email = p_identifier || '@tests.local';
$$;

-- A user who has completed onboarding. The identifier doubles as the username.
create or replace function tests.create_profile(p_identifier text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid := tests.create_user(p_identifier);
begin
  insert into public.profiles (id, username, display_name, age_confirmed_at)
  values (v_id, p_identifier, p_identifier, now());
  return v_id;
end;
$$;

create or replace function tests.authenticate_as(p_identifier text)
returns void
language plpgsql
as $$
declare
  v_id uuid := tests.get_user_id(p_identifier);
begin
  if v_id is null then
    raise exception 'tests.authenticate_as: no user %', p_identifier;
  end if;
  perform set_config('role', 'authenticated', true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', v_id, 'role', 'authenticated')::text,
    true
  );
end;
$$;

create or replace function tests.authenticate_as_anon()
returns void
language plpgsql
as $$
begin
  perform set_config('role', 'anon', true);
  perform set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);
end;
$$;

-- Signed in as `authenticated` but with no user id in the token.
create or replace function tests.authenticate_without_user()
returns void
language plpgsql
as $$
begin
  perform set_config('role', 'authenticated', true);
  perform set_config('request.jwt.claims', json_build_object('role', 'authenticated')::text, true);
end;
$$;

create or replace function tests.as_superuser()
returns void
language plpgsql
as $$
begin
  perform set_config('role', 'none', true);
  perform set_config('request.jwt.claims', '', true);
end;
$$;

grant execute on all functions in schema tests to anon, authenticated;

select plan(1);
select has_function('tests', 'authenticate_as', array['text'], 'test helpers are installed');
select * from finish();
