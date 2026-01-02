/*
Postgres function to return sales grouped by week.
Deploy this in Supabase SQL editor.
*/
create or replace function public.report_sales_by_week(weeks integer default 8)
returns table(period text, total numeric)
language sql
as $$
  select to_char(d::date, 'IYYY-"W"IW') as period, coalesce(sum(total),0)::numeric as total
  from (
    select generate_series(date_trunc('week', now()) - (weeks-1)*interval '1 week', date_trunc('week', now()), interval '1 week') as d
  ) g
  left join pedidos p on date_trunc('week', p.created_at) = g.d
  group by g.d
  order by g.d desc;
$$;
