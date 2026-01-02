-- RPC: create_pedido_with_stock
-- Usage: call with { cliente_id, notas, items: [{ producto_id, cantidad, precio_unitario, descripcion_personalizada }], anticipo }
-- This function will:
-- 1) Verify stock for each product (FOR UPDATE)
-- 2) Create a pedido, insert pedido_items, decrement stock, and optionally insert pago (anticipo)
-- It will raise an exception and abort the transaction if any product has insufficient stock.

create or replace function public.create_pedido_with_stock(
  cliente_id uuid,
  notas text,
  items jsonb,
  anticipo numeric default null
) returns table(pedido_id uuid) as $$
declare
  v_pedido_id uuid;
  it jsonb;
  prod_id uuid;
  qty numeric;
  prod_stock numeric;
begin
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

  -- insert anticipo payment if provided
  if anticipo is not null and anticipo > 0 then
    insert into pagos (pedido_id, monto, metodo, referencia, creado_en, es_anticipo)
    values (v_pedido_id, anticipo, null, null, now(), true);
  end if;

  -- return created pedido id
  pedido_id := v_pedido_id;
  return next;
end;
$$ language plpgsql security definer;

-- Notes:
-- - Deploy this SQL in the Supabase SQL editor (not in the client). Ensure the role used by the RPC has rights to update productos.stock, insert into pedidos/pedido_items/pagos.
-- - Consider adding a dedicated DB role or policy that allows calling this RPC while preventing direct client updates to `productos.stock`.
