-- Guards that apply to the whole schema, so a forgotten table or column fails loudly.
begin;
select no_plan();

select is_empty(
  $$
    select c.relname
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relkind in ('r', 'p')
      and not c.relrowsecurity
  $$,
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

select * from finish();
rollback;
