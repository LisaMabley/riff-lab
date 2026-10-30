-- Guards that apply to the whole schema, so a forgotten table or column fails loudly.
begin;
select plan(3);

create function pg_temp.tables_without_rls()
returns setof name
language sql
as $$
  select c.relname
  from pg_class c
  join pg_namespace n on n.oid = c.relnamespace
  where n.nspname = 'public'
    and c.relkind in ('r', 'p')
    and not c.relrowsecurity
$$;

select is_empty(
  'select * from pg_temp.tables_without_rls()',
  'every table in public has row-level security enabled'
);

-- The 18+ check takes a birth date and discards it. It must never be stored.
select is_empty(
  $$
    select n.nspname, c.relname, a.attname
    from pg_attribute a
    join pg_class c on c.oid = a.attrelid
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relkind in ('r', 'p', 'v', 'm')
      and a.attnum > 0
      and not a.attisdropped
      and (a.attname ilike '%birth%' or a.attname ilike '%dob%')
  $$,
  'no table or view has a birth date column'
);

-- Check that the RLS guard can actually fail (rolled back at the end).
create table public.guard_check_without_rls (id int);
select results_eq(
  'select * from pg_temp.tables_without_rls()',
  $$ values ('guard_check_without_rls'::name) $$,
  'the RLS guard catches a table without row-level security'
);

select * from finish();
rollback;
