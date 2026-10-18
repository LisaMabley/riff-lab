-- Profiles and the 18+ check.
--
-- The birth date entered at signup is compared in complete_onboarding() and then discarded.
-- Only the time the check passed (profiles.age_confirmed_at) is stored.

create function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

revoke execute on function public.set_updated_at() from public, anon, authenticated;

-- Profiles ------------------------------------------------------------------

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  -- Stored lowercase, so the unique constraint is case-insensitive.
  username text not null,
  display_name text not null,
  bio text,
  -- When the 18+ check passed. Read-only; no default, so every insert path must set it.
  age_confirmed_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_username_key unique (username),
  constraint profiles_username_format check (username ~ '^[a-z0-9_.]{3,30}$'),
  constraint profiles_display_name_length check (char_length(btrim(display_name)) between 1 and 50),
  constraint profiles_bio_length check (char_length(bio) <= 300)
);

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;

-- Column privileges keep id, username, age_confirmed_at, and created_at immutable for API users.
-- Rows are created only through complete_onboarding() and removed by the auth.users cascade.
revoke all on public.profiles from anon, authenticated;
grant select on public.profiles to authenticated;
grant update (display_name, bio) on public.profiles to authenticated;

create policy "Signed-in users can read profiles"
  on public.profiles for select
  to authenticated
  using (true);

create policy "Users can update their own profile"
  on public.profiles for update
  to authenticated
  using ((select auth.uid()) = id)
  with check ((select auth.uid()) = id);

-- Onboarding ----------------------------------------------------------------

-- Creates the caller's profile once they pass the 18+ check. p_birth_date is only compared,
-- never stored, and never included in an error message. Don't log it.
create function public.complete_onboarding(
  p_username text,
  p_display_name text,
  p_birth_date date
)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_user_id uuid := auth.uid();
  v_profile public.profiles;
begin
  if v_user_id is null then
    raise exception 'not_authenticated' using errcode = '42501';
  end if;

  -- Null and future dates fail this comparison too.
  if p_birth_date is null or p_birth_date > current_date - interval '18 years' then
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

revoke execute on function public.complete_onboarding(text, text, date) from public, anon;
grant execute on function public.complete_onboarding(text, text, date) to authenticated;
