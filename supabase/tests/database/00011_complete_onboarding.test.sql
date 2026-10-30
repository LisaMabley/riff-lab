begin;
select plan(19);

select tests.create_user('test_maya');
select tests.create_user('test_jamie');
select tests.create_user('test_kid');

-- Who can call it ---------------------------------------------------------------

select function_privs_are(
  'public', 'complete_onboarding', array['text', 'text', 'text'], 'anon', array[]::text[],
  'anon cannot execute complete_onboarding'
);
select function_privs_are(
  'public', 'complete_onboarding', array['text', 'text', 'text'], 'authenticated', array['EXECUTE'],
  'authenticated can execute complete_onboarding'
);

select tests.authenticate_as_anon();

select throws_ok(
  $$ select public.complete_onboarding('ghost', 'Ghost', '1990-01-01') $$,
  '42501', null,
  'anon cannot call onboarding'
);

select tests.authenticate_without_user();

select throws_ok(
  $$ select public.complete_onboarding('ghost', 'Ghost', '1990-01-01') $$,
  '42501', 'not_authenticated',
  'onboarding requires a signed-in user'
);

-- The 18+ check -----------------------------------------------------------------

select tests.authenticate_as('test_kid');

select throws_ok(
  $$ select public.complete_onboarding(
       'test_kid', 'Kid', (current_date - interval '18 years' + interval '1 day')::date::text
     ) $$,
  'P0001', 'under_18',
  'one day short of 18 is rejected'
);

select throws_ok(
  $$ select public.complete_onboarding('test_kid', 'Kid', (current_date + 1)::text) $$,
  'P0001', 'under_18',
  'a future birth date is rejected'
);

select throws_ok(
  $$ select public.complete_onboarding('test_kid', 'Kid', null) $$,
  '22007', 'invalid_birth_date',
  'a missing birth date is rejected'
);

-- The exact message check also confirms the value isn't echoed back in the error.
select throws_ok(
  $$ select public.complete_onboarding('test_kid', 'Kid', '2008-02-30') $$,
  '22007', 'invalid_birth_date',
  'an impossible date is rejected without repeating it'
);

select throws_ok(
  $$ select public.complete_onboarding('test_kid', 'Kid', 'Jan 1 1990') $$,
  '22007', 'invalid_birth_date',
  'only YYYY-MM-DD is accepted'
);

select is(
  (select count(*)::integer from public.profiles where id = auth.uid()),
  0,
  'a rejected signup creates no profile'
);

-- Success -------------------------------------------------------------------------

select tests.authenticate_as('test_maya');

select lives_ok(
  $$ select public.complete_onboarding(
       '  Test_Maya ', ' Maya ', (current_date - interval '18 years')::date::text
     ) $$,
  'onboarding succeeds on the 18th birthday'
);

select results_eq(
  $$ select username, display_name, bio from public.profiles where id = auth.uid() $$,
  $$ values ('test_maya', 'Maya', null::text) $$,
  'username is trimmed and lowercased, display name is trimmed'
);

select is(
  (select age_confirmed_at from public.profiles where id = auth.uid()),
  now(),
  'onboarding records age_confirmed_at'
);

select throws_ok(
  $$ select public.complete_onboarding('test_maya2', 'Maya', '1990-01-01') $$,
  'P0001', 'already_onboarded',
  'onboarding can only complete once'
);

-- Profile rules still apply ---------------------------------------------------------

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
  'a second user can onboard after failed attempts'
);

select is(
  (select count(*)::integer from public.profiles where username like 'test\_%'),
  2,
  'only the two successful signups created profiles'
);

select * from finish();
rollback;
