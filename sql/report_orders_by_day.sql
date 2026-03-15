/*
Returns order rows for a given date with client name.
Deploy this in Supabase SQL editor.
*/
create or replace function public.report_orders_by_day(day date, tz text default 'America/Mazatlan')
returns table(id uuid, total numeric, created_at timestamptz, cliente_nombre text)
language sql
as $$
  select p.id, p.total::numeric, p.created_at, c.nombre
  from pedidos p
  left join clientes c on p.cliente_id = c.id
  where p.created_at >= (day::timestamp AT TIME ZONE tz)
    and p.created_at < ((day + 1)::timestamp AT TIME ZONE tz)
  order by p.created_at asc;
$$;
