-- Profiles: one per user, created during onboarding.
--
-- Signed-in users can read every profile. Owners can change only their display name and bio.
-- Rows are inserted by complete_onboarding() (next migration) and removed by the auth.users
-- cascade, so API users can't insert or delete them directly.

-- Shared trigger function for tables with an updated_at column.
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

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  -- Stored lowercase, so the unique constraint is case-insensitive.
  username text not null,
  display_name text not null,
  bio text,
  -- When the 18+ check passed. Read-only for users. No default, so every insert path must set it.
  age_confirmed_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_username_key unique (username),
  -- Mirrors USERNAME_PATTERN in packages/core/src/username.ts.
  constraint profiles_username_format check (username ~ '^[a-z0-9_.]{3,30}$'),
  -- Limits mirror packages/core/src/limits.ts. Placeholders until spec §19 is settled.
  constraint profiles_display_name_length check (
    char_length(btrim(display_name)) >= 1 and char_length(display_name) <= 50
  ),
  constraint profiles_bio_length check (char_length(bio) <= 300)
);

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

alter table public.profiles enable row level security;

-- Column-level update grant keeps id, username, age_confirmed_at, and the timestamps immutable.
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
