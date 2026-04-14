-- ══════════════════════════════════════════════════════════════════
-- 05_caja_gastos.sql
-- SpaFlow — Caja, movimientos y gastos multi-tenant
-- Ejecutar SEXTO
-- ══════════════════════════════════════════════════════════════════

-- ── ENUM tipo_movimiento_caja ─────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipo_movimiento_caja') THEN
    CREATE TYPE public.tipo_movimiento_caja AS ENUM (
      'VENTA',
      'ANTICIPO',
      'ABONO',
      'GASTO_NEGOCIO',
      'GASTO_PERSONAL',
      'RETIRO_DUENO',
      'COMPRA_MATERIAL',
      'AJUSTE_ENTRADA',
      'AJUSTE_SALIDA',
      'PAGO_SERVICIO',
      'PRESTAMO_RECIBIDO'
    );
  END IF;
END $$;

-- ── CAJAS ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.cajas (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  spa_id          uuid NOT NULL REFERENCES public.spas(id) ON DELETE CASCADE,
  nombre          text NOT NULL DEFAULT 'Caja principal',
  saldo_inicial   numeric(10,2) NOT NULL DEFAULT 0,
  abierta         boolean NOT NULL DEFAULT true,
  fecha_apertura  timestamptz NOT NULL DEFAULT now(),
  fecha_cierre    timestamptz,
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_cajas_spa_id  ON public.cajas (spa_id);
CREATE INDEX IF NOT EXISTS idx_cajas_abierta ON public.cajas (spa_id, abierta);

-- ── MOVIMIENTOS_CAJA ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.movimientos_caja (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  spa_id      uuid NOT NULL REFERENCES public.spas(id) ON DELETE CASCADE,
  caja_id     uuid NOT NULL REFERENCES public.cajas(id) ON DELETE CASCADE,
  cita_id     uuid REFERENCES public.citas(id) ON DELETE SET NULL,
  tipo        public.tipo_movimiento_caja NOT NULL,
  concepto    text NOT NULL,
  categoria   text,
  metodo_pago text NOT NULL DEFAULT 'EFECTIVO',
  es_entrada  boolean NOT NULL,
  monto       numeric(10,2) NOT NULL CHECK (monto > 0),
  notas       text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_movimientos_spa_fecha  ON public.movimientos_caja (spa_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_movimientos_caja_id    ON public.movimientos_caja (caja_id);
CREATE INDEX IF NOT EXISTS idx_movimientos_tipo       ON public.movimientos_caja (spa_id, tipo);
CREATE INDEX IF NOT EXISTS idx_movimientos_metodo     ON public.movimientos_caja (spa_id, metodo_pago);

-- ── GASTOS ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.gastos (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  spa_id      uuid NOT NULL REFERENCES public.spas(id) ON DELETE CASCADE,
  concepto    text NOT NULL,
  monto       numeric(10,2) NOT NULL CHECK (monto > 0),
  categoria   text,
  metodo_pago text NOT NULL DEFAULT 'EFECTIVO',
  fecha       date NOT NULL DEFAULT CURRENT_DATE,
  notas       text,
  created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_gastos_spa_fecha ON public.gastos (spa_id, fecha DESC);

-- ── Función: obtener caja principal del tenant activo ─────────────
CREATE OR REPLACE FUNCTION public.get_caja_principal_id()
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  caja_uuid uuid;
  tenant_id uuid := public.current_spa_id();
BEGIN
  SELECT id INTO caja_uuid
  FROM public.cajas
  WHERE spa_id = tenant_id AND abierta = true
  ORDER BY fecha_apertura DESC
  LIMIT 1;

  IF caja_uuid IS NULL THEN
    INSERT INTO public.cajas (spa_id, nombre, saldo_inicial, abierta)
    VALUES (tenant_id, 'Caja principal', 0, true)
    RETURNING id INTO caja_uuid;
  END IF;

  RETURN caja_uuid;
END;
$$;

-- ── Normalizar método de pago ─────────────────────────────────────
CREATE OR REPLACE FUNCTION public.normalize_metodo_pago(input text)
RETURNS text
LANGUAGE sql
AS $$
  SELECT CASE
    WHEN input IS NULL OR btrim(input) = '' THEN 'EFECTIVO'
    ELSE upper(input)
  END;
$$;

-- ── Trigger: pagos_cita → movimientos_caja ───────────────────────
-- Cada pago registrado en una cita genera un movimiento de caja automáticamente
CREATE OR REPLACE FUNCTION public.handle_pago_cita_movimiento_caja()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  caja_uuid uuid;
  tenant_id uuid;
BEGIN
  -- Obtener el spa_id de la cita
  SELECT spa_id INTO tenant_id FROM public.citas WHERE id = NEW.cita_id;

  -- Obtener (o crear) la caja principal del tenant
  SELECT id INTO caja_uuid
  FROM public.cajas
  WHERE spa_id = tenant_id AND abierta = true
  ORDER BY fecha_apertura DESC
  LIMIT 1;

  IF caja_uuid IS NULL THEN
    INSERT INTO public.cajas (spa_id, nombre, saldo_inicial, abierta)
    VALUES (tenant_id, 'Caja principal', 0, true)
    RETURNING id INTO caja_uuid;
  END IF;

  INSERT INTO public.movimientos_caja (
    spa_id,
    caja_id,
    cita_id,
    tipo,
    concepto,
    metodo_pago,
    es_entrada,
    monto,
    notas,
    created_at
  ) VALUES (
    tenant_id,
    caja_uuid,
    NEW.cita_id,
    CASE
      WHEN NEW.es_anticipo THEN 'ANTICIPO'::public.tipo_movimiento_caja
      ELSE 'ABONO'::public.tipo_movimiento_caja
    END,
    CASE
      WHEN NEW.es_anticipo THEN 'Anticipo de cita'
      ELSE 'Pago de cita'
    END,
    public.normalize_metodo_pago(NEW.metodo),
    true,
    NEW.monto,
    NEW.referencia,
    COALESCE(NEW.creado_en, now())
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS pagos_cita_to_movimientos_caja ON public.pagos_cita;
CREATE TRIGGER pagos_cita_to_movimientos_caja
AFTER INSERT ON public.pagos_cita
FOR EACH ROW EXECUTE FUNCTION public.handle_pago_cita_movimiento_caja();

-- ── Trigger: gastos → movimientos_caja ───────────────────────────
CREATE OR REPLACE FUNCTION public.handle_gasto_movimiento_caja()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  caja_uuid uuid;
BEGIN
  SELECT id INTO caja_uuid
  FROM public.cajas
  WHERE spa_id = NEW.spa_id AND abierta = true
  ORDER BY fecha_apertura DESC
  LIMIT 1;

  IF caja_uuid IS NULL THEN
    INSERT INTO public.cajas (spa_id, nombre, saldo_inicial, abierta)
    VALUES (NEW.spa_id, 'Caja principal', 0, true)
    RETURNING id INTO caja_uuid;
  END IF;

  INSERT INTO public.movimientos_caja (
    spa_id, caja_id, tipo, concepto, categoria,
    metodo_pago, es_entrada, monto, notas, created_at
  ) VALUES (
    NEW.spa_id,
    caja_uuid,
    'GASTO_NEGOCIO'::public.tipo_movimiento_caja,
    NEW.concepto,
    NEW.categoria,
    public.normalize_metodo_pago(NEW.metodo_pago),
    false,      -- es salida de caja
    NEW.monto,
    NEW.notas,
    now()
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS gasto_to_movimiento_caja ON public.gastos;
CREATE TRIGGER gasto_to_movimiento_caja
AFTER INSERT ON public.gastos
FOR EACH ROW EXECUTE FUNCTION public.handle_gasto_movimiento_caja();

-- ── RLS — CAJAS ──────────────────────────────────────────────────
ALTER TABLE public.cajas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "cajas_tenant_admin" ON public.cajas;
CREATE POLICY "cajas_tenant_admin"
ON public.cajas FOR ALL TO authenticated
USING (
  spa_id = public.current_spa_id()
  AND public.has_app_role(ARRAY['admin_spa', 'recepcionista'])
)
WITH CHECK (
  spa_id = public.current_spa_id()
  AND public.current_app_role() = 'admin_spa'
);

-- ── RLS — MOVIMIENTOS_CAJA ────────────────────────────────────────
ALTER TABLE public.movimientos_caja ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "movimientos_tenant_admin" ON public.movimientos_caja;
CREATE POLICY "movimientos_tenant_admin"
ON public.movimientos_caja FOR ALL TO authenticated
USING (
  spa_id = public.current_spa_id()
  AND public.has_app_role(ARRAY['admin_spa', 'recepcionista'])
)
WITH CHECK (
  spa_id = public.current_spa_id()
  AND public.current_app_role() = 'admin_spa'
);

-- ── RLS — GASTOS ─────────────────────────────────────────────────
ALTER TABLE public.gastos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "gastos_tenant_admin_only" ON public.gastos;
CREATE POLICY "gastos_tenant_admin_only"
ON public.gastos FOR ALL TO authenticated
USING (
  spa_id = public.current_spa_id()
  AND public.current_app_role() = 'admin_spa'
  AND public.tenant_is_active()
)
WITH CHECK (
  spa_id = public.current_spa_id()
  AND public.current_app_role() = 'admin_spa'
  AND public.tenant_is_active()
);

-- ── Permisos ─────────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON public.cajas TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.movimientos_caja TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.gastos TO authenticated;

COMMENT ON TABLE public.cajas IS 'Cajas registradoras del spa con saldo y estado de apertura.';
COMMENT ON TABLE public.movimientos_caja IS 'Registro de entradas y salidas de caja. Se alimenta via triggers.';
COMMENT ON TABLE public.gastos IS 'Gastos operativos del spa, generan movimiento de salida en caja automáticamente.';
