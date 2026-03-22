-- RPC: create_pedido_with_stock
-- Usage: call with { cliente_id, notas, items: [{ producto_id, cantidad, precio_unitario, descripcion_personalizada }], anticipo, consumos, anticipo_metodo }
-- consumos (optional): [{ producto_id, cantidad }] — raw materials to decrement from stock (e.g. tabloides consumed by sobreplatos)
-- This function will:
-- 1) Verify stock for each product (FOR UPDATE)
-- 2) Verify stock for each raw material in consumos
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
begin
  perform public.require_app_role(array['admin', 'empleado']);

  if items is null then
    raise exception 'items array required';
  end if;

  -- Check availability and lock product rows
  for it in select * from jsonb_array_elements(items)
  loop
    prod_id := (it->>'producto_id')::uuid;
    qty := (it->>'cantidad')::numeric;
    select stock into prod_stock from productos where id = prod_id for update;
    if prod_stock is null then
      raise exception 'Producto % no tiene stock registrado', prod_id;
    end if;
    if prod_stock < qty then
      raise exception 'Stock insuficiente para producto % (disponible: %, requerido: %)', prod_id, prod_stock, qty;
    end if;
  end loop;

  -- Check availability of raw materials (consumos)
  if consumos is not null and jsonb_array_length(consumos) > 0 then
    for it in select * from jsonb_array_elements(consumos)
    loop
      prod_id := (it->>'producto_id')::uuid;
      qty := (it->>'cantidad')::numeric;
      select stock, nombre into prod_stock, prod_nombre from productos where id = prod_id for update;
      if prod_stock is null then
        raise exception 'Material % no tiene stock registrado', coalesce(prod_nombre, prod_id::text);
      end if;
      if prod_stock < qty then
        raise exception 'Stock insuficiente de material "%" (disponible: %, requerido: %)', coalesce(prod_nombre, prod_id::text), prod_stock, qty;
      end if;
    end loop;
  end if;

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
