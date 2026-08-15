-- SQL Script: delete_pedido_with_stock_rollback.sql
-- Devolución/Rollback automático de inventario al eliminar un pedido

-- 1. Función principal de rollback de stock
CREATE OR REPLACE FUNCTION public.rollback_pedido_stock(p_pedido_id uuid)
RETURNS void AS $$
DECLARE
  item record;
  prod_nombre text;
  v_mat_id uuid;
  v_consumed numeric;
BEGIN
  -- Recorrer todos los items asociados al pedido que se va a eliminar
  FOR item IN
    SELECT pi.producto_id, pi.cantidad, pi.descripcion_personalizada, p.nombre AS prod_nombre
    FROM public.pedido_items pi
    LEFT JOIN public.productos p ON p.id = pi.producto_id
    WHERE pi.pedido_id = p_pedido_id
  LOOP
    -- Restaurar stock del producto principal si tiene producto_id
    IF item.producto_id IS NOT NULL THEN
      UPDATE public.productos
      SET stock = COALESCE(stock, 0) + item.cantidad,
          updated_at = now()
      WHERE id = item.producto_id;
    END IF;

    -- Obtener nombre en minúsculas para evaluar reglas de consumo de materiales
    prod_nombre := lower(coalesce(item.prod_nombre, item.descripcion_personalizada, ''));

    -- Regla 1: Tarjetas de presentación consumen Tabloide Couché Grueso (25 unidades por tabloide)
    IF prod_nombre LIKE '%tarjeta%presentaci%' THEN
      v_consumed := ceil(item.cantidad / 25.0);
      SELECT id INTO v_mat_id FROM public.productos WHERE lower(nombre) LIKE '%tabloide couche grueso%' LIMIT 1;
      IF v_mat_id IS NOT NULL THEN
        UPDATE public.productos
        SET stock = COALESCE(stock, 0) + v_consumed,
            updated_at = now()
        WHERE id = v_mat_id;
      END IF;

    -- Regla 2: Esquelas consumen Tabloide Etiqueta (9 unidades por tabloide)
    ELSIF prod_nombre LIKE '%esquela%' THEN
      v_consumed := ceil(item.cantidad / 9.0);
      SELECT id INTO v_mat_id FROM public.productos WHERE lower(nombre) LIKE '%tabloide etiqueta%' LIMIT 1;
      IF v_mat_id IS NOT NULL THEN
        UPDATE public.productos
        SET stock = COALESCE(stock, 0) + v_consumed,
            updated_at = now()
        WHERE id = v_mat_id;
      END IF;
    END IF;

  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 2. Trigger Function que se ejecuta antes de borrar un pedido
CREATE OR REPLACE FUNCTION public.trg_func_rollback_pedido_stock()
RETURNS trigger AS $$
BEGIN
  PERFORM public.rollback_pedido_stock(OLD.id);
  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 3. Crear el Trigger en la tabla public.pedidos
DROP TRIGGER IF EXISTS trg_rollback_pedido_stock ON public.pedidos;
CREATE TRIGGER trg_rollback_pedido_stock
  BEFORE DELETE ON public.pedidos
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_func_rollback_pedido_stock();

-- 4. Función RPC para eliminar pedido con rollback (disponible vía API)
CREATE OR REPLACE FUNCTION public.delete_pedido_with_stock_rollback(p_pedido_id uuid)
RETURNS boolean AS $$
BEGIN
  -- Verificar permisos si existe require_app_role
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'require_app_role') THEN
    PERFORM public.require_app_role(ARRAY['admin']);
  END IF;

  -- Borra el pedido (el trigger BEFORE DELETE restaurará el stock de items y consumos)
  DELETE FROM public.pedidos WHERE id = p_pedido_id;
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

GRANT EXECUTE ON FUNCTION public.delete_pedido_with_stock_rollback(uuid) TO authenticated;
