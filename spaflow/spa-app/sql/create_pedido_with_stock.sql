-- RPC: create_pedido_with_stock
-- Usage: call with { cliente_id, notas, items: [{ producto_id, cantidad, precio_unitario, descripcion_personalizada }], anticipo, consumos, anticipo_metodo }
-- consumos (optional): [{ producto_id, cantidad }] — raw materials to decrement from stock (e.g. tabloides consumed by sobreplatos)
-- This function will:
-- 1) Aggregate total demand per product (items + consumos combined)
-- 2) Verify stock for each product (FOR UPDATE)
-- 3) Create a pedido, insert pedido_items, decrement stock, decrement material stock, and optionally insert pago (anticipo)
-- It will raise an exception and abort the transaction if any product has insufficient stock.

-- Remove legacy 5-argument signature to avoid RPC ambiguity (PGRST203).
drop function if exists public.create_pedido_with_stock(uuid, text, jsonb, numeric, jsonb);

create or replace function public.create_pedido_with_stock(
  cliente_id uuid,
  notas text,
  items jsonb,
  anticipo numeric default null,
  consumos jsonb default '[]'::jsonb,
  anticipo_metodo text default null
) returns table(pedido_id uuid) as $$
declare
  v_pedido_id uuid;
  it jsonb;
  prod_id uuid;
  qty numeric;
  prod_stock numeric;
  prod_nombre text;
  demand_rec record;
begin
  perform public.require_app_role(array['admin', 'empleado']);

  if items is null then
    raise exception 'items array required';
  end if;

  -- ===================================================================
  -- Aggregate total demand per product across BOTH items and consumos.
  -- This prevents the CHECK constraint violation when the same product
  -- appears in items and consumos, or appears multiple times in either.
  -- ===================================================================
  for demand_rec in
    select agg.pid as producto_id, sum(agg.qty) as total_needed
    from (
      -- quantities from items
      select (elem->>'producto_id')::uuid as pid,
             (elem->>'cantidad')::numeric  as qty
      from   jsonb_array_elements(items) as elem
      where  elem->>'producto_id' is not null

      union all

      -- quantities from consumos
      select (elem->>'producto_id')::uuid as pid,
             (elem->>'cantidad')::numeric  as qty
      from   jsonb_array_elements(coalesce(consumos, '[]'::jsonb)) as elem
      where  elem->>'producto_id' is not null
    ) agg
    group by agg.pid
  loop
    -- Lock the row and verify availability
    select stock, nombre into prod_stock, prod_nombre
    from productos
    where id = demand_rec.producto_id
    for update;

    if prod_stock is null then
      raise exception 'Producto "%" no tiene stock registrado',
        coalesce(prod_nombre, demand_rec.producto_id::text);
    end if;

    if prod_stock < demand_rec.total_needed then
      raise exception 'Stock insuficiente para "%" (disponible: %, requerido: %)',
        coalesce(prod_nombre, demand_rec.producto_id::text),
        prod_stock, demand_rec.total_needed;
    end if;
  end loop;

  -- compute total
  insert into pedidos (cliente_id, notas, total)
  values (
    cliente_id,
    notas,
    (select coalesce(sum( (elem->>'cantidad')::numeric * (elem->>'precio_unitario')::numeric ),0) from jsonb_array_elements(items) as elem)
  ) returning id into v_pedido_id;

  -- insert items and decrement stock
  for it in select * from jsonb_array_elements(items)
  loop
    insert into pedido_items (pedido_id, producto_id, descripcion_personalizada, cantidad, precio_unitario)
    values (
      v_pedido_id,
      (it->>'producto_id')::uuid,
      nullif(it->>'descripcion_personalizada',''),
      (it->>'cantidad')::numeric,
      (it->>'precio_unitario')::numeric
    );

    update productos
    set stock = stock - (it->>'cantidad')::numeric
    where id = (it->>'producto_id')::uuid;
  end loop;

  -- decrement raw material stock (consumos)
  if consumos is not null and jsonb_array_length(consumos) > 0 then
    for it in select * from jsonb_array_elements(consumos)
    loop
      update productos
      set stock = stock - (it->>'cantidad')::numeric
      where id = (it->>'producto_id')::uuid;
    end loop;
  end if;

  -- insert anticipo payment if provided
  if anticipo is not null and anticipo > 0 then
    insert into pagos (pedido_id, monto, metodo, referencia, creado_en, es_anticipo)
    values (v_pedido_id, anticipo, anticipo_metodo, null, now(), true);
  end if;

  -- return created pedido id
  pedido_id := v_pedido_id;
  return next;
end;
$$ language plpgsql security definer set search_path = public;

revoke all on function public.create_pedido_with_stock(uuid, text, jsonb, numeric, jsonb, text) from public;
grant execute on function public.create_pedido_with_stock(uuid, text, jsonb, numeric, jsonb, text) to authenticated;

-- Notes:
-- - Deploy the RBAC script before this function so `public.require_app_role()` is available.
-- - This RPC is allowed for `admin` and `empleado` only.
