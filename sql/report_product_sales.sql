-- Consulta para saber cuántas unidades de un producto se vendieron en un rango de fechas.
-- Busca por nombre de producto (coincidencia parcial, case-insensitive).
--
-- Ejemplos de uso:
--   select * from report_product_sales('tabloide', '2026-01-01', '2026-03-05');
--   select * from report_product_sales('couche');  -- sin rango = todo el historial

create or replace function public.report_product_sales(
  product_name text,
  date_from date default null,
  date_to   date default null,
  tz text default 'America/Mazatlan'
)
returns table(
  producto_id   uuid,
  producto      text,
  total_cantidad numeric,
  total_ventas   numeric,
  num_pedidos    bigint
)
language plpgsql
as $$
begin
  perform public.require_app_role(array['admin']);

  return query
  select
    pi.producto_id,
    pr.nombre as producto,
    sum(pi.cantidad)::numeric as total_cantidad,
    sum(pi.cantidad * pi.precio_unitario)::numeric as total_ventas,
    count(distinct pi.pedido_id) as num_pedidos
  from pedido_items pi
  join productos pr on pr.id = pi.producto_id
  join pedidos p on p.id = pi.pedido_id
  where pr.nombre ilike '%' || product_name || '%'
    and (date_from is null or p.created_at >= (date_from::timestamp at time zone tz))
    and (date_to is null or p.created_at < ((date_to + 1)::timestamp at time zone tz))
  group by pi.producto_id, pr.nombre
  order by total_cantidad desc;
end;
$$;

revoke all on function public.report_product_sales(text, date, date, text) from public;
grant execute on function public.report_product_sales(text, date, date, text) to authenticated;
