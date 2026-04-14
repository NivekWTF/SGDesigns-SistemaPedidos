-- ══════════════════════════════════════════════════════════════════
-- 04_citas.sql
-- SpaFlow — Citas (core del sistema), items y pagos
-- Ejecutar QUINTO
-- ══════════════════════════════════════════════════════════════════

-- ── TIPO ENUM estado_cita ─────────────────────────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estado_cita') THEN
    CREATE TYPE public.estado_cita AS ENUM (
      'AGENDADA',
      'CONFIRMADA',
      'EN_CURSO',
      'COMPLETADA',
      'CANCELADA',
      'NO_SHOW'
    );
  END IF;
END $$;

-- ── CITAS ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.citas (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  spa_id          uuid NOT NULL REFERENCES public.spas(id) ON DELETE CASCADE,
  folio           text,                         -- SPA-2026-0001 (único por tenant)
  cliente_id      uuid NOT NULL REFERENCES public.clientes(id) ON DELETE RESTRICT,
  personal_id     uuid REFERENCES public.personal(id) ON DELETE SET NULL,
  estado          public.estado_cita NOT NULL DEFAULT 'AGENDADA',
  fecha_inicio    timestamptz NOT NULL,
  fecha_fin       timestamptz NOT NULL,
  notas           text,                         -- notas visibles para el cliente
  notas_internas  text,                         -- notas solo para staff
  total           numeric(10,2) NOT NULL DEFAULT 0 CHECK (total >= 0),
  anticipo        numeric(10,2) NOT NULL DEFAULT 0 CHECK (anticipo >= 0),
  created_by      uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now(),
  -- Restricciones
  CONSTRAINT cita_fechas_validas CHECK (fecha_fin > fecha_inicio),
  CONSTRAINT cita_anticipo_valido CHECK (anticipo <= total),
  UNIQUE NULLS NOT DISTINCT (spa_id, folio)    -- folio único por tenant
);

CREATE INDEX IF NOT EXISTS idx_citas_spa_fecha   ON public.citas (spa_id, fecha_inicio);
CREATE INDEX IF NOT EXISTS idx_citas_spa_estado  ON public.citas (spa_id, estado);
CREATE INDEX IF NOT EXISTS idx_citas_cliente     ON public.citas (cliente_id);
CREATE INDEX IF NOT EXISTS idx_citas_personal    ON public.citas (personal_id);
CREATE INDEX IF NOT EXISTS idx_citas_created_at  ON public.citas (spa_id, created_at DESC);

DROP TRIGGER IF EXISTS set_citas_updated_at ON public.citas;
CREATE TRIGGER set_citas_updated_at
BEFORE UPDATE ON public.citas
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ── FOLIO AUTOMÁTICO por tenant ──────────────────────────────────
CREATE OR REPLACE FUNCTION public.generate_cita_folio()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  year_part text := to_char(now(), 'YYYY');
  seq       int;
BEGIN
  -- Contar citas del mismo tenant y año para generar secuencial
  SELECT COUNT(*) + 1 INTO seq
  FROM public.citas
  WHERE spa_id = NEW.spa_id
    AND EXTRACT(YEAR FROM created_at) = EXTRACT(YEAR FROM now());

  NEW.folio := 'SPA-' || year_part || '-' || lpad(seq::text, 4, '0');
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS set_cita_folio ON public.citas;
CREATE TRIGGER set_cita_folio
BEFORE INSERT ON public.citas
FOR EACH ROW
WHEN (NEW.folio IS NULL)
EXECUTE FUNCTION public.generate_cita_folio();

-- ── Trigger: actualizar fecha_ultima_visita en cliente ────────────
CREATE OR REPLACE FUNCTION public.update_cliente_ultima_visita()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.estado = 'COMPLETADA' AND (OLD IS NULL OR OLD.estado <> 'COMPLETADA') THEN
    UPDATE public.clientes
    SET fecha_ultima_visita = now()
    WHERE id = NEW.cliente_id;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS cita_completada_update_cliente ON public.citas;
CREATE TRIGGER cita_completada_update_cliente
AFTER INSERT OR UPDATE OF estado ON public.citas
FOR EACH ROW EXECUTE FUNCTION public.update_cliente_ultima_visita();

-- ── CITA_ITEMS ───────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.cita_items (
  id                        uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cita_id                   uuid NOT NULL REFERENCES public.citas(id) ON DELETE CASCADE,
  servicio_id               uuid REFERENCES public.servicios(id) ON DELETE SET NULL,
  producto_id               uuid REFERENCES public.productos(id) ON DELETE SET NULL,
  descripcion_personalizada text,
  cantidad                  int NOT NULL DEFAULT 1 CHECK (cantidad > 0),
  precio_unitario           numeric(10,2) NOT NULL CHECK (precio_unitario >= 0),
  subtotal numeric(10,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
  -- Un item es: servicio, producto, o descripción manual (solo uno)
  CONSTRAINT cita_item_solo_un_tipo CHECK (
    (servicio_id IS NOT NULL)::int +
    (producto_id IS NOT NULL)::int +
    (descripcion_personalizada IS NOT NULL)::int = 1
  )
);

CREATE INDEX IF NOT EXISTS idx_cita_items_cita_id ON public.cita_items (cita_id);

-- ── PAGOS de citas ───────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.pagos_cita (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cita_id     uuid NOT NULL REFERENCES public.citas(id) ON DELETE CASCADE,
  monto       numeric(10,2) NOT NULL CHECK (monto > 0),
  metodo      text NOT NULL DEFAULT 'EFECTIVO'
              CHECK (metodo IN ('EFECTIVO', 'TRANSFERENCIA', 'TARJETA', 'OTRO')),
  es_anticipo boolean NOT NULL DEFAULT false,
  referencia  text,
  creado_en   timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pagos_cita_cita_id  ON public.pagos_cita (cita_id);
CREATE INDEX IF NOT EXISTS idx_pagos_cita_fecha     ON public.pagos_cita (creado_en);

-- ── RLS — CITAS ──────────────────────────────────────────────────
ALTER TABLE public.citas ENABLE ROW LEVEL SECURITY;

-- admin_spa y recepcionista: todas las citas del spa
DROP POLICY IF EXISTS "citas_staff_all" ON public.citas;
CREATE POLICY "citas_staff_all"
ON public.citas FOR ALL TO authenticated
USING (
  spa_id = public.current_spa_id()
  AND public.has_app_role(ARRAY['admin_spa', 'recepcionista'])
  AND public.tenant_is_active()
)
WITH CHECK (
  spa_id = public.current_spa_id()
  AND public.has_app_role(ARRAY['admin_spa', 'recepcionista'])
  AND public.tenant_is_active()
);

-- terapeuta: solo sus propias citas
DROP POLICY IF EXISTS "citas_terapeuta_own" ON public.citas;
CREATE POLICY "citas_terapeuta_own"
ON public.citas FOR SELECT TO authenticated
USING (
  spa_id = public.current_spa_id()
  AND public.current_app_role() = 'terapeuta'
  AND public.tenant_is_active()
  AND personal_id IN (
    SELECT id FROM public.personal WHERE profile_id = auth.uid()
  )
);

-- terapeuta: puede actualizar estado de sus citas (EN_CURSO, COMPLETADA, notas)
DROP POLICY IF EXISTS "citas_terapeuta_update_estado" ON public.citas;
CREATE POLICY "citas_terapeuta_update_estado"
ON public.citas FOR UPDATE TO authenticated
USING (
  spa_id = public.current_spa_id()
  AND public.current_app_role() = 'terapeuta'
  AND public.tenant_is_active()
  AND personal_id IN (
    SELECT id FROM public.personal WHERE profile_id = auth.uid()
  )
)
WITH CHECK (
  spa_id = public.current_spa_id()
  AND public.current_app_role() = 'terapeuta'
  AND public.tenant_is_active()
  AND personal_id IN (
    SELECT id FROM public.personal WHERE profile_id = auth.uid()
  )
);

-- ── RLS — CITA_ITEMS ─────────────────────────────────────────────
ALTER TABLE public.cita_items ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "cita_items_tenant" ON public.cita_items;
CREATE POLICY "cita_items_tenant"
ON public.cita_items FOR ALL TO authenticated
USING (
  cita_id IN (
    SELECT id FROM public.citas WHERE spa_id = public.current_spa_id()
  )
  AND public.has_app_role(ARRAY['admin_spa', 'recepcionista', 'terapeuta'])
)
WITH CHECK (
  cita_id IN (
    SELECT id FROM public.citas WHERE spa_id = public.current_spa_id()
  )
  AND public.has_app_role(ARRAY['admin_spa', 'recepcionista'])
);

-- ── RLS — PAGOS_CITA ─────────────────────────────────────────────
ALTER TABLE public.pagos_cita ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "pagos_cita_staff" ON public.pagos_cita;
CREATE POLICY "pagos_cita_staff"
ON public.pagos_cita FOR ALL TO authenticated
USING (
  cita_id IN (
    SELECT id FROM public.citas WHERE spa_id = public.current_spa_id()
  )
  AND public.has_app_role(ARRAY['admin_spa', 'recepcionista'])
  AND public.tenant_is_active()
)
WITH CHECK (
  cita_id IN (
    SELECT id FROM public.citas WHERE spa_id = public.current_spa_id()
  )
  AND public.has_app_role(ARRAY['admin_spa', 'recepcionista'])
  AND public.tenant_is_active()
);

-- Terapeutas: solo pueden ver los pagos de sus citas
DROP POLICY IF EXISTS "pagos_cita_terapeuta_select" ON public.pagos_cita;
CREATE POLICY "pagos_cita_terapeuta_select"
ON public.pagos_cita FOR SELECT TO authenticated
USING (
  public.current_app_role() = 'terapeuta'
  AND cita_id IN (
    SELECT c.id FROM public.citas c
    JOIN public.personal p ON p.id = c.personal_id
    WHERE p.profile_id = auth.uid()
      AND c.spa_id = public.current_spa_id()
  )
);

-- ── Permisos ─────────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON public.citas TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.cita_items TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.pagos_cita TO authenticated;

COMMENT ON TABLE public.citas IS 'Core del sistema: registro de cada visita/cita al spa.';
COMMENT ON COLUMN public.citas.folio IS 'Folio único por tenant/año: SPA-2026-0001.';
COMMENT ON COLUMN public.citas.notas_internas IS 'Notas de sesión solo visibles para el staff.';
COMMENT ON TABLE public.cita_items IS 'Servicios y productos incluidos en cada cita.';
COMMENT ON TABLE public.pagos_cita IS 'Pagos registrados por cita (anticipos + saldos).';
