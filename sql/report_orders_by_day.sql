/*
Returns order rows for a given date with client name.
Deploy this in Supabase SQL editor.
*/
create or replace function public.report_orders_by_day(day date, tz text default 'America/Mazatlan')
returns table(id uuid, total numeric, created_at timestamptz, cliente_nombre text)
language plpgsql
as $$
begin
  perform public.require_app_role(array['admin']);

  return query
  select p.id, p.total::numeric, p.created_at, c.nombre
  from pedidos p
  left join clientes c on p.cliente_id = c.id
  where p.created_at >= (day::timestamp at time zone tz)
    and p.created_at < ((day + 1)::timestamp at time zone tz)
  order by p.created_at asc;
end;
$$;

revoke all on function public.report_orders_by_day(date, text) from public;
grant execute on function public.report_orders_by_day(date, text) to authenticated;
