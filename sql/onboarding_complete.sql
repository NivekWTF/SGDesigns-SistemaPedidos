-- ============================================================
-- SCRIPT DE ONBOARDING - Sistema de Pedidos para Imprentas
-- ============================================================
-- Ejecuta este script completo en el SQL Editor de Supabase
-- para configurar una nueva instancia del sistema.
--
-- Orden de ejecución:
-- 1. Tablas base (clientes, productos, pedidos, pedido_items, pagos)
-- 2. Perfiles y RBAC
-- 3. Tabla de gastos
-- 4. Tablas de caja y movimientos
-- 5. Stock groups
-- 6. Funciones de reportes
-- ============================================================

-- =====================
-- 1. TABLAS BASE
-- =====================

CREATE TABLE IF NOT EXISTS public.clientes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre text NOT NULL,
  telefono text,
  email text,
  direccion text,
  notas text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.productos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre text NOT NULL,
  descripcion text,
  unidad text DEFAULT 'pieza',
  precio_base numeric(10,2) NOT NULL DEFAULT 0,
  costo_material numeric(10,2),
  stock numeric(10,2),
  stock_group_id uuid,
  activo boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.pedidos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  folio text,
  cliente_id uuid REFERENCES public.clientes(id) ON DELETE SET NULL,
  estado text NOT NULL DEFAULT 'PENDIENTE' CHECK (estado IN ('PENDIENTE','EN_PRODUCCION','TERMINADO','ENTREGADO','CANCELADO')),
  total numeric(10,2) NOT NULL DEFAULT 0,
  notas text,
  fecha_entrega date,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.pedido_items (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pedido_id uuid NOT NULL REFERENCES public.pedidos(id) ON DELETE CASCADE,
  producto_id uuid REFERENCES public.productos(id) ON DELETE SET NULL,
  descripcion_personalizada text,
  cantidad numeric(10,2) NOT NULL DEFAULT 1,
  precio_unitario numeric(10,2) NOT NULL DEFAULT 0,
  subtotal numeric(10,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED
);

CREATE TABLE IF NOT EXISTS public.pagos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pedido_id uuid NOT NULL REFERENCES public.pedidos(id) ON DELETE CASCADE,
  monto numeric(10,2) NOT NULL DEFAULT 0,
  metodo text NOT NULL DEFAULT 'EFECTIVO',
  referencia text,
  es_anticipo boolean NOT NULL DEFAULT false,
  creado_en timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.pedido_archivos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  pedido_id uuid NOT NULL REFERENCES public.pedidos(id) ON DELETE CASCADE,
  url text NOT NULL,
  nombre_archivo text NOT NULL,
  tipo text,
  tamanio_bytes bigint,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- =====================
-- 2. GASTOS
-- =====================

CREATE TABLE IF NOT EXISTS public.gastos (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  concepto text NOT NULL,
  monto numeric(10,2) NOT NULL,
  categoria text,
  notas text,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- =====================
-- 3. STOCK GROUPS
-- =====================

CREATE TABLE IF NOT EXISTS public.stock_groups (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Add FK for stock_group_id if not already there
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE constraint_name = 'productos_stock_group_id_fkey'
  ) THEN
    ALTER TABLE public.productos
      ADD CONSTRAINT productos_stock_group_id_fkey
      FOREIGN KEY (stock_group_id) REFERENCES public.stock_groups(id) ON DELETE SET NULL;
  END IF;
END $$;

-- =====================
-- 4. PROFILES & RBAC
-- =====================

CREATE TABLE IF NOT EXISTS public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  email text,
  full_name text,
  role text NOT NULL DEFAULT 'empleado' CHECK (role IN ('admin', 'empleado')),
  created_at timestamptz NOT NULL DEFAULT timezone('utc', now()),
  updated_at timestamptz NOT NULL DEFAULT timezone('utc', now())
);

-- Auto-update updated_at
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  new.updated_at := timezone('utc', now());
  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS set_profiles_updated_at ON public.profiles;
CREATE TRIGGER set_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- Prevent removing the last admin
CREATE OR REPLACE FUNCTION public.prevent_last_admin_removal()
RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF tg_op = 'UPDATE' THEN
    IF old.role = 'admin' AND new.role <> 'admin'
      AND NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id <> old.id AND p.role = 'admin')
    THEN
      RAISE EXCEPTION 'Debe existir al menos un administrador activo';
    END IF;
    RETURN new;
  END IF;
  IF tg_op = 'DELETE' THEN
    IF old.role = 'admin'
      AND NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id <> old.id AND p.role = 'admin')
    THEN
      RAISE EXCEPTION 'No puedes eliminar al ultimo administrador';
    END IF;
    RETURN old;
  END IF;
  RETURN coalesce(new, old);
END;
$$;

DROP TRIGGER IF EXISTS prevent_last_admin_role_update ON public.profiles;
CREATE TRIGGER prevent_last_admin_role_update
  BEFORE UPDATE OF role ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.prevent_last_admin_removal();

DROP TRIGGER IF EXISTS prevent_last_admin_delete ON public.profiles;
CREATE TRIGGER prevent_last_admin_delete
  BEFORE DELETE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.prevent_last_admin_removal();

-- Auto-create profile on user signup (first user becomes admin)
CREATE OR REPLACE FUNCTION public.handle_new_user_profile()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  bootstrap_role text := 'empleado';
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.profiles) THEN
    bootstrap_role := 'admin';
  END IF;
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    new.id, new.email,
    coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'),
    bootstrap_role
  )
  ON CONFLICT (id) DO UPDATE
  SET email = excluded.email,
      full_name = coalesce(excluded.full_name, public.profiles.full_name);
  RETURN new;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created_create_profile ON auth.users;
CREATE TRIGGER on_auth_user_created_create_profile
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_profile();

-- Backfill existing users
WITH ranked_users AS (
  SELECT u.id, u.email,
    coalesce(u.raw_user_meta_data ->> 'full_name', u.raw_user_meta_data ->> 'name') AS full_name,
    row_number() OVER (ORDER BY u.created_at, u.id) AS rn
  FROM auth.users u
)
INSERT INTO public.profiles (id, email, full_name, role)
SELECT ru.id, ru.email, ru.full_name,
  CASE WHEN NOT EXISTS (SELECT 1 FROM public.profiles) AND ru.rn = 1 THEN 'admin' ELSE 'empleado' END
FROM ranked_users ru
WHERE NOT EXISTS (SELECT 1 FROM public.profiles p WHERE p.id = ru.id);

-- RBAC helper functions
CREATE OR REPLACE FUNCTION public.current_app_role()
RETURNS text LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT p.role FROM public.profiles p WHERE p.id = auth.uid();
$$;

CREATE OR REPLACE FUNCTION public.has_app_role(allowed_roles text[])
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public AS $$
  SELECT auth.role() = 'authenticated'
    AND coalesce(public.current_app_role() = ANY (allowed_roles), false);
$$;

CREATE OR REPLACE FUNCTION public.require_app_role(allowed_roles text[])
RETURNS void LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public AS $$
BEGIN
  IF NOT public.has_app_role(allowed_roles) THEN
    RAISE EXCEPTION 'Permisos insuficientes para esta operación';
  END IF;
END;
$$;

GRANT SELECT, UPDATE ON public.profiles TO authenticated;

-- =====================
-- 5. ROW LEVEL SECURITY
-- =====================

ALTER TABLE IF EXISTS public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.productos ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.pedidos ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.pedido_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.pagos ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.gastos ENABLE ROW LEVEL SECURITY;

-- Profiles
DROP POLICY IF EXISTS "profiles_select_self_or_admin" ON public.profiles;
CREATE POLICY "profiles_select_self_or_admin" ON public.profiles FOR SELECT TO authenticated
  USING (id = auth.uid() OR public.has_app_role(array['admin']));

DROP POLICY IF EXISTS "profiles_update_admin_only" ON public.profiles;
CREATE POLICY "profiles_update_admin_only" ON public.profiles FOR UPDATE TO authenticated
  USING (public.has_app_role(array['admin'])) WITH CHECK (public.has_app_role(array['admin']));

-- Clientes
DROP POLICY IF EXISTS "clientes_select_authenticated" ON public.clientes;
CREATE POLICY "clientes_select_authenticated" ON public.clientes FOR SELECT TO authenticated
  USING (public.has_app_role(array['admin', 'empleado']));

DROP POLICY IF EXISTS "clientes_write_admin_only" ON public.clientes;
CREATE POLICY "clientes_write_admin_only" ON public.clientes FOR ALL TO authenticated
  USING (public.has_app_role(array['admin'])) WITH CHECK (public.has_app_role(array['admin']));

-- Productos
DROP POLICY IF EXISTS "productos_select_authenticated" ON public.productos;
CREATE POLICY "productos_select_authenticated" ON public.productos FOR SELECT TO authenticated
  USING (public.has_app_role(array['admin', 'empleado']));

DROP POLICY IF EXISTS "productos_write_admin_only" ON public.productos;
CREATE POLICY "productos_write_admin_only" ON public.productos FOR ALL TO authenticated
  USING (public.has_app_role(array['admin'])) WITH CHECK (public.has_app_role(array['admin']));

-- Pedidos
DROP POLICY IF EXISTS "pedidos_select_authenticated" ON public.pedidos;
CREATE POLICY "pedidos_select_authenticated" ON public.pedidos FOR SELECT TO authenticated
  USING (public.has_app_role(array['admin', 'empleado']));

DROP POLICY IF EXISTS "pedidos_insert_authenticated" ON public.pedidos;
CREATE POLICY "pedidos_insert_authenticated" ON public.pedidos FOR INSERT TO authenticated
  WITH CHECK (public.has_app_role(array['admin', 'empleado']));

DROP POLICY IF EXISTS "pedidos_update_authenticated" ON public.pedidos;
CREATE POLICY "pedidos_update_authenticated" ON public.pedidos FOR UPDATE TO authenticated
  USING (public.has_app_role(array['admin', 'empleado']))
  WITH CHECK (public.has_app_role(array['admin', 'empleado']));

DROP POLICY IF EXISTS "pedidos_delete_admin_only" ON public.pedidos;
CREATE POLICY "pedidos_delete_admin_only" ON public.pedidos FOR DELETE TO authenticated
  USING (public.has_app_role(array['admin']));

-- Pedido items
DROP POLICY IF EXISTS "pedido_items_select_authenticated" ON public.pedido_items;
CREATE POLICY "pedido_items_select_authenticated" ON public.pedido_items FOR SELECT TO authenticated
  USING (public.has_app_role(array['admin', 'empleado']));

DROP POLICY IF EXISTS "pedido_items_insert_authenticated" ON public.pedido_items;
CREATE POLICY "pedido_items_insert_authenticated" ON public.pedido_items FOR INSERT TO authenticated
  WITH CHECK (public.has_app_role(array['admin', 'empleado']));

DROP POLICY IF EXISTS "pedido_items_update_authenticated" ON public.pedido_items;
CREATE POLICY "pedido_items_update_authenticated" ON public.pedido_items FOR UPDATE TO authenticated
  USING (public.has_app_role(array['admin', 'empleado']))
  WITH CHECK (public.has_app_role(array['admin', 'empleado']));

DROP POLICY IF EXISTS "pedido_items_delete_authenticated" ON public.pedido_items;
CREATE POLICY "pedido_items_delete_authenticated" ON public.pedido_items FOR DELETE TO authenticated
  USING (public.has_app_role(array['admin', 'empleado']));

-- Pagos
DROP POLICY IF EXISTS "pagos_select_authenticated" ON public.pagos;
CREATE POLICY "pagos_select_authenticated" ON public.pagos FOR SELECT TO authenticated
  USING (public.has_app_role(array['admin', 'empleado']));

DROP POLICY IF EXISTS "pagos_insert_authenticated" ON public.pagos;
CREATE POLICY "pagos_insert_authenticated" ON public.pagos FOR INSERT TO authenticated
  WITH CHECK (public.has_app_role(array['admin', 'empleado']));

DROP POLICY IF EXISTS "pagos_update_admin_only" ON public.pagos;
CREATE POLICY "pagos_update_admin_only" ON public.pagos FOR UPDATE TO authenticated
  USING (public.has_app_role(array['admin'])) WITH CHECK (public.has_app_role(array['admin']));

DROP POLICY IF EXISTS "pagos_delete_admin_only" ON public.pagos;
CREATE POLICY "pagos_delete_admin_only" ON public.pagos FOR DELETE TO authenticated
  USING (public.has_app_role(array['admin']));

-- Gastos
DROP POLICY IF EXISTS "gastos_admin_only" ON public.gastos;
CREATE POLICY "gastos_admin_only" ON public.gastos FOR ALL TO authenticated
  USING (public.has_app_role(array['admin'])) WITH CHECK (public.has_app_role(array['admin']));

-- =====================
-- 6. CAJA Y MOVIMIENTOS
-- =====================

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipo_movimiento_caja') THEN
    CREATE TYPE tipo_movimiento_caja AS ENUM (
      'VENTA', 'ANTICIPO', 'ABONO', 'GASTO_NEGOCIO', 'GASTO_PERSONAL',
      'RETIRO_DUENO', 'COMPRA_MATERIAL', 'AJUSTE_ENTRADA', 'AJUSTE_SALIDA',
      'PAGO_SERVICIO', 'PRESTAMO_RECIBIDO'
    );
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS public.cajas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre text NOT NULL DEFAULT 'Caja principal',
  saldo_inicial numeric(10,2) NOT NULL DEFAULT 0,
  abierta boolean NOT NULL DEFAULT true,
  fecha_apertura timestamptz NOT NULL DEFAULT now(),
  fecha_cierre timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.movimientos_caja (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  caja_id uuid NOT NULL REFERENCES cajas(id) ON DELETE CASCADE,
  pedido_id uuid REFERENCES pedidos(id) ON DELETE SET NULL,
  tipo tipo_movimiento_caja NOT NULL,
  concepto text NOT NULL,
  categoria text,
  metodo_pago text NOT NULL DEFAULT 'EFECTIVO',
  es_entrada boolean NOT NULL,
  monto numeric(10,2) NOT NULL CHECK (monto > 0),
  notas text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_movimientos_caja_created_at ON movimientos_caja (created_at);
CREATE INDEX IF NOT EXISTS idx_movimientos_caja_caja_id ON movimientos_caja (caja_id);
CREATE INDEX IF NOT EXISTS idx_movimientos_caja_tipo ON movimientos_caja (tipo);
CREATE INDEX IF NOT EXISTS idx_movimientos_caja_metodo ON movimientos_caja (metodo_pago);

CREATE OR REPLACE FUNCTION public.get_caja_principal_id()
RETURNS uuid LANGUAGE plpgsql AS $$
DECLARE caja_uuid uuid;
BEGIN
  SELECT id INTO caja_uuid FROM cajas WHERE abierta = true ORDER BY fecha_apertura DESC LIMIT 1;
  IF caja_uuid IS NULL THEN
    INSERT INTO cajas (nombre, saldo_inicial, abierta) VALUES ('Caja principal', 0, true)
      RETURNING id INTO caja_uuid;
  END IF;
  RETURN caja_uuid;
END;
$$;

CREATE OR REPLACE FUNCTION public.normalize_metodo_pago(input text)
RETURNS text LANGUAGE sql AS $$
  SELECT CASE WHEN input IS NULL OR btrim(input) = '' THEN 'EFECTIVO' ELSE upper(input) END;
$$;

CREATE OR REPLACE FUNCTION public.handle_pago_movimiento_caja()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE caja_uuid uuid;
BEGIN
  caja_uuid := public.get_caja_principal_id();
  INSERT INTO movimientos_caja (caja_id, pedido_id, tipo, concepto, categoria, metodo_pago, es_entrada, monto, notas, created_at)
  VALUES (
    caja_uuid, NEW.pedido_id,
    CASE WHEN NEW.es_anticipo THEN 'ANTICIPO'::tipo_movimiento_caja ELSE 'ABONO'::tipo_movimiento_caja END,
    CASE WHEN NEW.es_anticipo THEN 'Anticipo de pedido' ELSE 'Pago de pedido' END,
    'PEDIDOS', public.normalize_metodo_pago(NEW.metodo), true, NEW.monto, NEW.referencia,
    COALESCE(NEW.creado_en, now())
  );
  RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF to_regclass('public.pagos') IS NOT NULL THEN
    EXECUTE 'DROP TRIGGER IF EXISTS pagos_to_movimientos_caja ON public.pagos';
    EXECUTE 'CREATE TRIGGER pagos_to_movimientos_caja AFTER INSERT ON public.pagos FOR EACH ROW EXECUTE FUNCTION public.handle_pago_movimiento_caja()';
  END IF;
END $$;

-- =====================
-- 7. REPORT FUNCTIONS
-- =====================

-- Sales by day
CREATE OR REPLACE FUNCTION public.report_sales_by_day(days integer DEFAULT 30, tz text DEFAULT 'America/Mazatlan')
RETURNS TABLE(period text, total numeric) LANGUAGE plpgsql AS $$
BEGIN
  PERFORM public.require_app_role(array['admin']);
  RETURN QUERY
  WITH date_range AS (
    SELECT generate_series(
      (timezone(tz, now())::date - (days-1)),
      timezone(tz, now())::date,
      interval '1 day'
    )::date AS d
  ), daily_sales AS (
    SELECT (timezone(tz, created_at))::date AS d, SUM(p.total) AS total
    FROM pedidos p GROUP BY 1
  )
  SELECT to_char(dr.d, 'YYYY-MM-DD') AS period, COALESCE(ds.total, 0)::numeric AS total
  FROM date_range dr LEFT JOIN daily_sales ds ON ds.d = dr.d ORDER BY dr.d;
END;
$$;

REVOKE ALL ON FUNCTION public.report_sales_by_day(integer, text) FROM public;
GRANT EXECUTE ON FUNCTION public.report_sales_by_day(integer, text) TO authenticated;

-- Profit and expenses (monthly)
CREATE OR REPLACE FUNCTION public.report_profit_and_expenses(periods integer DEFAULT 12, tz text DEFAULT 'America/Mazatlan')
RETURNS TABLE(period text, ingresos numeric, gastos numeric, profit numeric) LANGUAGE plpgsql AS $$
BEGIN
  PERFORM public.require_app_role(array['admin']);
  IF to_regclass('public.gastos') IS NULL THEN
    RETURN QUERY
    WITH months AS (
      SELECT generate_series(
        date_trunc('month', timezone(tz, now())) - (periods-1)*interval '1 month',
        date_trunc('month', timezone(tz, now())), interval '1 month'
      ) AS d
    ), sales AS (
      SELECT date_trunc('month', timezone(tz, created_at)) AS m, sum(total) AS ingresos FROM pedidos GROUP BY m
    )
    SELECT to_char(m.d::date, 'YYYY-MM'), coalesce(s.ingresos,0)::numeric, 0::numeric, coalesce(s.ingresos,0)::numeric
    FROM months m LEFT JOIN sales s ON s.m = m.d ORDER BY m.d DESC;
  ELSE
    RETURN QUERY
    WITH months AS (
      SELECT generate_series(
        date_trunc('month', timezone(tz, now())) - (periods-1)*interval '1 month',
        date_trunc('month', timezone(tz, now())), interval '1 month'
      ) AS d
    ), sales AS (
      SELECT date_trunc('month', timezone(tz, created_at)) AS m, sum(total) AS ingresos FROM pedidos GROUP BY m
    ), expenses AS (
      SELECT date_trunc('month', timezone(tz, created_at)) AS m, sum(monto) AS gastos FROM gastos GROUP BY m
    )
    SELECT to_char(m.d::date, 'YYYY-MM'), coalesce(s.ingresos,0)::numeric, coalesce(e.gastos,0)::numeric,
      (coalesce(s.ingresos,0)-coalesce(e.gastos,0))::numeric
    FROM months m LEFT JOIN sales s ON s.m = m.d LEFT JOIN expenses e ON e.m = m.d ORDER BY m.d DESC;
  END IF;
END;
$$;

REVOKE ALL ON FUNCTION public.report_profit_and_expenses(integer, text) FROM public;
GRANT EXECUTE ON FUNCTION public.report_profit_and_expenses(integer, text) TO authenticated;

-- Product sales report
CREATE OR REPLACE FUNCTION public.report_product_sales(
  days integer DEFAULT 30,
  tz text DEFAULT 'America/Mazatlan'
)
RETURNS TABLE(
  producto_id uuid,
  producto_nombre text,
  cantidad_total numeric,
  ingreso_total numeric
) LANGUAGE plpgsql AS $$
BEGIN
  PERFORM public.require_app_role(array['admin']);
  RETURN QUERY
  SELECT
    pi.producto_id,
    COALESCE(pr.nombre, pi.descripcion_personalizada, 'Sin nombre') AS producto_nombre,
    SUM(pi.cantidad)::numeric AS cantidad_total,
    SUM(pi.subtotal)::numeric AS ingreso_total
  FROM pedido_items pi
  JOIN pedidos p ON p.id = pi.pedido_id
  LEFT JOIN productos pr ON pr.id = pi.producto_id
  WHERE p.created_at >= (timezone(tz, now()) - (days || ' days')::interval)
  GROUP BY pi.producto_id, producto_nombre
  ORDER BY ingreso_total DESC;
END;
$$;

REVOKE ALL ON FUNCTION public.report_product_sales(integer, text) FROM public;
GRANT EXECUTE ON FUNCTION public.report_product_sales(integer, text) TO authenticated;

-- =====================
-- 8. SUPABASE STORAGE
-- =====================
-- Create a storage bucket for order files (run this manually if needed):
-- INSERT INTO storage.buckets (id, name, public) VALUES ('pedido-archivos', 'pedido-archivos', false);

-- =====================
-- 9. BUSINESS CONFIG (White-label settings)
-- =====================

CREATE TABLE IF NOT EXISTS public.business_config (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_name text,
  business_rfc text,
  business_email text,
  business_address text,
  business_phone text,
  business_logo_url text,
  business_socials text,
  business_series text DEFAULT 'COT',
  tax_rate numeric(5,4) DEFAULT 0.16,
  color_primary text DEFAULT '#0ea5e9',
  color_primary_dark text DEFAULT '#0284c7',
  color_accent text DEFAULT '#38bdf8',
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Enforce single row
CREATE OR REPLACE FUNCTION public.enforce_single_config_row()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF (SELECT count(*) FROM public.business_config) >= 1 THEN
    RAISE EXCEPTION 'Solo puede existir una fila de configuración. Usa UPDATE en lugar de INSERT.';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS enforce_single_config ON public.business_config;
CREATE TRIGGER enforce_single_config
  BEFORE INSERT ON public.business_config
  FOR EACH ROW EXECUTE FUNCTION public.enforce_single_config_row();

DROP TRIGGER IF EXISTS set_business_config_updated_at ON public.business_config;
CREATE TRIGGER set_business_config_updated_at
  BEFORE UPDATE ON public.business_config
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

ALTER TABLE public.business_config ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "business_config_select_authenticated" ON public.business_config;
CREATE POLICY "business_config_select_authenticated"
  ON public.business_config FOR SELECT TO authenticated
  USING (public.has_app_role(array['admin', 'empleado']));

DROP POLICY IF EXISTS "business_config_write_admin" ON public.business_config;
CREATE POLICY "business_config_write_admin"
  ON public.business_config FOR ALL TO authenticated
  USING (public.has_app_role(array['admin']))
  WITH CHECK (public.has_app_role(array['admin']));

-- Seed with defaults
INSERT INTO public.business_config (
  business_name, business_series, tax_rate,
  color_primary, color_primary_dark, color_accent
) VALUES (
  NULL, 'COT', 0.16,
  '#0ea5e9', '#0284c7', '#38bdf8'
);

-- ============================================================
-- ✅ ONBOARDING COMPLETE
-- El primer usuario que se registre será automáticamente ADMIN.
-- El admin puede personalizar el sistema desde Configuración.
-- ============================================================
