begin;
select no_plan();

select tests.create_user('test_maya');
select tests.create_user('test_jamie');
select tests.create_user('test_kid');

-- Onboarding and the 18+ check ----------------------------------------------

select tests.authenticate_as('test_kid');

select throws_ok(
  $$ select public.complete_onboarding('test_kid', 'Kid', (current_date - interval '18 years' + interval '1 day')::date) $$,
  'P0001', 'under_18',
  'one day short of 18 is rejected'
);

select throws_ok(
  $$ select public.complete_onboarding('test_kid', 'Kid', (current_date + 1)::date) $$,
  'P0001', 'under_18',
  'a future birth date is rejected'
);

select throws_ok(
  $$ select public.complete_onboarding('test_kid', 'Kid', null) $$,
  'P0001', 'under_18',
  'a missing birth date is rejected'
);

select is(
  (select count(*)::integer from public.profiles where id = tests.get_user_id('test_kid')),
  0,
  'a rejected signup creates no profile'
);

select tests.authenticate_as('test_maya');

select lives_ok(
  $$ select public.complete_onboarding('  Test_Maya ', 'Maya', (current_date - interval '18 years')::date) $$,
  'onboarding succeeds on the 18th birthday'
);

select is(
  (select username from public.profiles where id = tests.get_user_id('test_maya')),
  'test_maya',
  'usernames are trimmed and stored lowercase'
);

select throws_ok(
  $$ select public.complete_onboarding('test_maya2', 'Maya', '1990-01-01') $$,
  'P0001', 'already_onboarded',
  'onboarding can only complete once'
);

select tests.authenticate_as('test_jamie');

select throws_ok(
  $$ select public.complete_onboarding('TEST_MAYA', 'Jo', '1990-01-01') $$,
  '23505', null,
  'usernames are unique regardless of case'
);

select throws_ok(
  $$ select public.complete_onboarding('jo smith', 'Jo', '1990-01-01') $$,
  '23514', null,
  'usernames must match the allowed format'
);

select throws_ok(
  $$ select public.complete_onboarding('test_jamie', '   ', '1990-01-01') $$,
  '23514', null,
  'display names cannot be blank'
);

select lives_ok(
  $$ select public.complete_onboarding('test_jamie', 'Jo', '1990-01-01') $$,
  'a second user can onboard'
);

select tests.authenticate_without_user();

select throws_ok(
  $$ select public.complete_onboarding('ghost', 'Ghost', '1990-01-01') $$,
  '42501', 'not_authenticated',
  'onboarding requires a signed-in user'
);

select tests.authenticate_as_anon();

select throws_ok(
  $$ select public.complete_onboarding('ghost', 'Ghost', '1990-01-01') $$,
  '42501', null,
  'anon cannot call onboarding'
);

select tests.as_superuser();

select is(
  (select age_confirmed_at from public.profiles where id = tests.get_user_id('test_maya')),
  now(),
  'onboarding records age_confirmed_at'
);

-- Reading -------------------------------------------------------------------

select tests.authenticate_as('test_maya');

select is(
  (select count(*)::integer from public.profiles where username like 'test\_%'),
  2,
  'signed-in users can read every profile'
);

select tests.authenticate_as_anon();

select throws_ok(
  $$ select * from public.profiles $$,
  '42501', null,
  'anon cannot read profiles'
);

-- Writing -------------------------------------------------------------------

select tests.authenticate_as('test_maya');

select lives_ok(
  $$ update public.profiles set display_name = 'Maya K', bio = 'Thrift everything.' where id = auth.uid() $$,
  'users can update their own display name and bio'
);

select is(
  (select bio from public.profiles where id = auth.uid()),
  'Thrift everything.',
  'the bio update is saved'
);

update public.profiles set display_name = 'Hacked' where username = 'test_jamie';

select is(
  (select display_name from public.profiles where username = 'test_jamie'),
  'Jo',
  'users cannot update someone else''s profile'
);

select throws_ok(
  $$ update public.profiles set username = 'test_maya_new' where id = auth.uid() $$,
  '42501', null,
  'usernames cannot be changed'
);

select throws_ok(
  $$ update public.profiles set age_confirmed_at = null where id = auth.uid() $$,
  '42501', null,
  'age_confirmed_at is read-only'
);

select throws_ok(
  $$ insert into public.profiles (id, username, display_name, age_confirmed_at)
     values (gen_random_uuid(), 'sneaky', 'Sneaky', now()) $$,
  '42501', null,
  'profiles cannot be inserted directly'
);

select throws_ok(
  $$ delete from public.profiles where id = auth.uid() $$,
  '42501', null,
  'profiles cannot be deleted directly'
);

select throws_ok(
  $$ update public.profiles set bio = repeat('x', 301) where id = auth.uid() $$,
  '23514', null,
  'bios are limited to 300 characters'
);

-- Account deletion ----------------------------------------------------------

select tests.as_superuser();

delete from auth.users where id = tests.get_user_id('test_maya');

select is(
  (select count(*)::integer from public.profiles where username = 'test_maya'),
  0,
  'deleting the account deletes the profile'
);

select * from finish();
rollback;
