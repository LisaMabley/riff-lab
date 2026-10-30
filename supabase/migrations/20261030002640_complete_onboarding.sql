-- Onboarding and the 18+ check.
--
-- complete_onboarding() creates the caller's profile once they pass the 18+ check. The birth
-- date is compared and then discarded: only the time the check passed (age_confirmed_at) is
-- stored. It is never stored, returned, or included in an error message. Don't log it.
--
-- p_birth_date is text, not date, so a malformed value fails inside the function with a
-- generic error. As a date parameter, Postgres would reject it before the function runs, with
-- an error message (and log line) that includes the value.

create function public.complete_onboarding(
  p_username text,
  p_display_name text,
  p_birth_date text
)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := (select auth.uid());
  v_birth_date date;
  v_profile public.profiles;
begin
  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;

  -- Same rules as isAdult() in packages/core/src/age.ts: a real YYYY-MM-DD calendar date.
  if p_birth_date is null or p_birth_date !~ '^\d{4}-\d{2}-\d{2}$' then
    raise exception 'invalid_birth_date' using errcode = '22007';
  end if;
  begin
    v_birth_date := p_birth_date::date;
  exception when others then
    raise exception 'invalid_birth_date' using errcode = '22007';
  end;

  -- Future dates fail this comparison too.
  if v_birth_date > current_date - interval '18 years' then
    raise exception 'under_18' using errcode = 'P0001';
  end if;

  if exists (select 1 from public.profiles where id = v_user_id) then
    raise exception 'already_onboarded' using errcode = 'P0001';
  end if;

  insert into public.profiles (id, username, display_name, age_confirmed_at)
  values (v_user_id, lower(btrim(p_username)), btrim(p_display_name), now())
  returning * into v_profile;

  return v_profile;
end;
$$;

revoke execute on function public.complete_onboarding(text, text, text) from public, anon;
grant execute on function public.complete_onboarding(text, text, text) to authenticated;
