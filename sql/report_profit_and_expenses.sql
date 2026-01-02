/*
Returns monthly period with ingresos (sales total), gastos (expenses) and profit (ingresos - gastos).
Modify the expenses source as appropriate; here we assume a table `gastos` with `monto` and `created_at`.
*/
create or replace function public.report_profit_and_expenses(periods integer default 12)
returns table(period text, ingresos numeric, gastos numeric, profit numeric)
language plpgsql
as $$
begin
  -- If expenses table does not exist, return zeros for gastos
  if to_regclass('public.gastos') is null then
    return query
    with months as (
      select generate_series(date_trunc('month', now()) - (periods-1)*interval '1 month', date_trunc('month', now()), interval '1 month') as d
    ), sales as (
      select date_trunc('month', created_at) as m, sum(total) as ingresos from pedidos group by m
    )
    select to_char(m.d::date, 'YYYY-MM') as period,
           coalesce(s.ingresos,0)::numeric as ingresos,
           0::numeric as gastos,
           (coalesce(s.ingresos,0) - 0::numeric)::numeric as profit
    from months m
    left join sales s on s.m = m.d
    order by m.d desc;
  else
    return query
    with months as (
      select generate_series(date_trunc('month', now()) - (periods-1)*interval '1 month', date_trunc('month', now()), interval '1 month') as d
    ), sales as (
      select date_trunc('month', created_at) as m, sum(total) as ingresos from pedidos group by m
    ), expenses as (
      select date_trunc('month', created_at) as m, sum(monto) as gastos from gastos group by m
    )
    select to_char(m.d::date, 'YYYY-MM') as period,
           coalesce(s.ingresos,0)::numeric as ingresos,
           coalesce(e.gastos,0)::numeric as gastos,
           (coalesce(s.ingresos,0)-coalesce(e.gastos,0))::numeric as profit
    from months m
    left join sales s on s.m = m.d
    left join expenses e on e.m = m.d
    order by m.d desc;
  end if;
end;
$$;
