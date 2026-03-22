/*
Postgres function to return sales grouped by week.
Deploy this in Supabase SQL editor.
*/
create or replace function public.report_sales_by_week(weeks integer default 8, tz text default 'America/Mazatlan')
returns table(period text, total numeric)
language plpgsql
as $$
begin
  perform public.require_app_role(array['admin']);

  return query
  select to_char(d::date, 'IYYY-"W"IW') as period, coalesce(sum(total), 0)::numeric as total
  from (
    select generate_series(
      date_trunc('week', timezone(tz, now())) - (weeks - 1) * interval '1 week',
      date_trunc('week', timezone(tz, now())),
      interval '1 week'
    ) as d
  ) g
  left join pedidos p on date_trunc('week', timezone(tz, p.created_at)) = g.d
  group by g.d
  order by g.d desc;
end;
$$;

revoke all on function public.report_sales_by_week(integer, text) from public;
grant execute on function public.report_sales_by_week(integer, text) to authenticated;
