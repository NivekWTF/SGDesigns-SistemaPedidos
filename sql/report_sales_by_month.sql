/*
Postgres function to return sales grouped by month.
Deploy this in Supabase SQL editor.
*/
create or replace function public.report_sales_by_month(months integer default 12, tz text default 'America/Mazatlan')
returns table(period text, total numeric)
language plpgsql
as $$
begin
  perform public.require_app_role(array['admin']);

  return query
  select to_char(d::date, 'YYYY-MM') as period, coalesce(sum(total), 0)::numeric as total
  from (
    select generate_series(
      date_trunc('month', timezone(tz, now())) - (months - 1) * interval '1 month',
      date_trunc('month', timezone(tz, now())),
      interval '1 month'
    ) as d
  ) g
  left join pedidos p on date_trunc('month', timezone(tz, p.created_at)) = g.d
  group by g.d
  order by g.d desc;
end;
$$;

revoke all on function public.report_sales_by_month(integer, text) from public;
grant execute on function public.report_sales_by_month(integer, text) to authenticated;
