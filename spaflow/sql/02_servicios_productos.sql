-- ══════════════════════════════════════════════════════════════════
-- 02_servicios_productos.sql
-- SpaFlow — Catálogo de servicios, productos y paquetes
-- Ejecutar TERCERO
-- ══════════════════════════════════════════════════════════════════

-- ── SERVICIOS ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.servicios (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  spa_id        uuid NOT NULL REFERENCES public.spas(id) ON DELETE CASCADE,
  nombre        text NOT NULL,
  descripcion   text,
  categoria     text NOT NULL DEFAULT 'OTRO'
                CHECK (categoria IN ('MASAJE', 'FACIAL', 'CORPORAL', 'UÑAS', 'CABELLO', 'OTRO')),
  duracion_min  int NOT NULL CHECK (duracion_min > 0),
  precio        numeric(10,2) NOT NULL CHECK (precio >= 0),
  activo        boolean NOT NULL DEFAULT true,
  imagen_url    text,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_servicios_spa_id   ON public.servicios (spa_id);
CREATE INDEX IF NOT EXISTS idx_servicios_categoria ON public.servicios (spa_id, categoria);
CREATE INDEX IF NOT EXISTS idx_servicios_activo    ON public.servicios (spa_id, activo);

-- Trigger updated_at
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at := now(); RETURN NEW; END;
$$;

DROP TRIGGER IF EXISTS set_servicios_updated_at ON public.servicios;
CREATE TRIGGER set_servicios_updated_at
BEFORE UPDATE ON public.servicios
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ── PRODUCTOS (venta en mostrador) ──────────────────────────────
CREATE TABLE IF NOT EXISTS public.productos (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  spa_id        uuid NOT NULL REFERENCES public.spas(id) ON DELETE CASCADE,
  nombre        text NOT NULL,
  descripcion   text,
  categoria     text,
  precio_venta  numeric(10,2) NOT NULL CHECK (precio_venta >= 0),
  stock         int NOT NULL DEFAULT 0 CHECK (stock >= 0),
  activo        boolean NOT NULL DEFAULT true,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_productos_spa_id ON public.productos (spa_id);
CREATE INDEX IF NOT EXISTS idx_productos_activo  ON public.productos (spa_id, activo);

DROP TRIGGER IF EXISTS set_productos_updated_at ON public.productos;
CREATE TRIGGER set_productos_updated_at
BEFORE UPDATE ON public.productos
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ── PAQUETES ────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.paquetes (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  spa_id          uuid NOT NULL REFERENCES public.spas(id) ON DELETE CASCADE,
  nombre          text NOT NULL,
  descripcion     text,
  precio          numeric(10,2) NOT NULL CHECK (precio >= 0),
  activo          boolean NOT NULL DEFAULT true,
  vigencia_dias   int CHECK (vigencia_dias IS NULL OR vigencia_dias > 0),
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_paquetes_spa_id ON public.paquetes (spa_id);

DROP TRIGGER IF EXISTS set_paquetes_updated_at ON public.paquetes;
CREATE TRIGGER set_paquetes_updated_at
BEFORE UPDATE ON public.paquetes
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ── PAQUETE_SERVICIOS (relación muchos-a-muchos) ─────────────────
CREATE TABLE IF NOT EXISTS public.paquete_servicios (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  paquete_id      uuid NOT NULL REFERENCES public.paquetes(id) ON DELETE CASCADE,
  servicio_id     uuid NOT NULL REFERENCES public.servicios(id) ON DELETE CASCADE,
  cantidad        int NOT NULL DEFAULT 1 CHECK (cantidad > 0),
  UNIQUE (paquete_id, servicio_id)
);

CREATE INDEX IF NOT EXISTS idx_paquete_servicios_paquete  ON public.paquete_servicios (paquete_id);
CREATE INDEX IF NOT EXISTS idx_paquete_servicios_servicio ON public.paquete_servicios (servicio_id);

-- ── RLS — SERVICIOS ──────────────────────────────────────────────
ALTER TABLE public.servicios ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "servicios_tenant_select" ON public.servicios;
CREATE POLICY "servicios_tenant_select"
ON public.servicios FOR SELECT TO authenticated
USING (
  spa_id = public.current_spa_id()
  AND public.has_app_role(ARRAY['admin_spa', 'recepcionista', 'terapeuta'])
);

DROP POLICY IF EXISTS "servicios_tenant_write" ON public.servicios;
CREATE POLICY "servicios_tenant_write"
ON public.servicios FOR ALL TO authenticated
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

-- ── RLS — PRODUCTOS ──────────────────────────────────────────────
ALTER TABLE public.productos ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "productos_tenant_select" ON public.productos;
CREATE POLICY "productos_tenant_select"
ON public.productos FOR SELECT TO authenticated
USING (
  spa_id = public.current_spa_id()
  AND public.has_app_role(ARRAY['admin_spa', 'recepcionista', 'terapeuta'])
);

DROP POLICY IF EXISTS "productos_tenant_write" ON public.productos;
CREATE POLICY "productos_tenant_write"
ON public.productos FOR ALL TO authenticated
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

-- ── RLS — PAQUETES ───────────────────────────────────────────────
ALTER TABLE public.paquetes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.paquete_servicios ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "paquetes_tenant_select" ON public.paquetes;
CREATE POLICY "paquetes_tenant_select"
ON public.paquetes FOR SELECT TO authenticated
USING (
  spa_id = public.current_spa_id()
  AND public.has_app_role(ARRAY['admin_spa', 'recepcionista', 'terapeuta'])
);

DROP POLICY IF EXISTS "paquetes_tenant_write" ON public.paquetes;
CREATE POLICY "paquetes_tenant_write"
ON public.paquetes FOR ALL TO authenticated
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

DROP POLICY IF EXISTS "paquete_servicios_tenant" ON public.paquete_servicios;
CREATE POLICY "paquete_servicios_tenant"
ON public.paquete_servicios FOR ALL TO authenticated
USING (
  paquete_id IN (
    SELECT id FROM public.paquetes WHERE spa_id = public.current_spa_id()
  )
  AND public.has_app_role(ARRAY['admin_spa', 'recepcionista', 'terapeuta'])
)
WITH CHECK (
  paquete_id IN (
    SELECT id FROM public.paquetes WHERE spa_id = public.current_spa_id()
  )
  AND public.current_app_role() = 'admin_spa'
);

-- ── Permisos ─────────────────────────────────────────────────────
GRANT SELECT, INSERT, UPDATE, DELETE ON public.servicios TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.productos TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.paquetes TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.paquete_servicios TO authenticated;

COMMENT ON TABLE public.servicios IS 'Catálogo de servicios del spa (masajes, faciales, etc.).';
COMMENT ON TABLE public.productos IS 'Productos físicos de venta en mostrador.';
COMMENT ON TABLE public.paquetes IS 'Paquetes/combos de múltiples servicios con precio especial.';
COMMENT ON TABLE public.paquete_servicios IS 'Relación servicios incluidos en cada paquete.';
