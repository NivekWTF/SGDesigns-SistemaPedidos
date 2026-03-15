create or replace function public.report_profit_and_expenses_weekly(weeks integer default 8, tz text default 'America/Mazatlan')
returns table(period text, ingresos numeric, gastos numeric, profit numeric)
language plpgsql
as $$
begin
  if to_regclass('public.gastos') is null then
    return query
    with ws as (
      select generate_series(
        date_trunc('week', timezone(tz, now())) - (weeks-1)*interval '1 week',
        date_trunc('week', timezone(tz, now())),
        interval '1 week'
      ) as d
    ), sales as (
      select date_trunc('week', timezone(tz, created_at)) as w, sum(total) as ingresos from pedidos group by w
    )
    select to_char(ws.d::date, 'IYYY-"W"IW') as period,
           coalesce(s.ingresos,0)::numeric as ingresos,
           0::numeric as gastos,
           (coalesce(s.ingresos,0) - 0::numeric)::numeric as profit
    from ws
    left join sales s on s.w = ws.d
    order by ws.d desc;
  else
    return query
    with ws as (
      select generate_series(
        date_trunc('week', timezone(tz, now())) - (weeks-1)*interval '1 week',
        date_trunc('week', timezone(tz, now())),
        interval '1 week'
      ) as d
    ), sales as (
      select date_trunc('week', timezone(tz, created_at)) as w, sum(total) as ingresos from pedidos group by w
    ), expenses as (
      select date_trunc('week', timezone(tz, created_at)) as w, sum(monto) as gastos from gastos group by w
    )
    select to_char(ws.d::date, 'IYYY-"W"IW') as period,
           coalesce(s.ingresos,0)::numeric as ingresos,
           coalesce(e.gastos,0)::numeric as gastos,
           (coalesce(s.ingresos,0)-coalesce(e.gastos,0))::numeric as profit
    from ws
    left join sales s on s.w = ws.d
    left join expenses e on e.w = ws.d
    order by ws.d desc;
  end if;
end;
$$;
