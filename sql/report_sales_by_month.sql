/*
Postgres function to return sales grouped by month.
Deploy this in Supabase SQL editor.
*/
create or replace function public.report_sales_by_month(months integer default 12)
returns table(period text, total numeric)
language sql
as $$
  select to_char(d::date, 'YYYY-MM') as period, coalesce(sum(total),0)::numeric as total
  from (
    select generate_series(date_trunc('month', now()) - (months-1)*interval '1 month', date_trunc('month', now()), interval '1 month') as d
  ) g
  left join pedidos p on date_trunc('month', p.created_at) = g.d
  group by g.d
  order by g.d desc;
$$;
