/*
Returns hourly sales totals for a given date (24 rows: 00..23).
Deploy this in Supabase SQL editor.
*/
create or replace function public.report_sales_by_day(day date, tz text default 'America/Mazatlan')
returns table(period text, total numeric)
language sql
as $$
  select to_char(d, 'HH24') as period, coalesce(sum(p.total),0)::numeric as total
  from (
    select generate_series((day::timestamp AT TIME ZONE tz), (day::timestamp AT TIME ZONE tz) + interval '23 hour', interval '1 hour') as d
  ) g
  left join pedidos p on date_trunc('hour', p.created_at) = g.d
  group by g.d
  order by g.d;
$$;
