-- ══════════════════════════════════════════════════════════════════
-- 01_schema_base.sql
-- SpaFlow — Ampliar profiles con spa_id + tabla clientes
-- Ejecutar SEGUNDO (después de 00_spas_tenants.sql)
-- ══════════════════════════════════════════════════════════════════

-- ── 1. Agregar spa_id a profiles (ya existe, creada en el script 00) ─
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS spa_id uuid REFERENCES public.spas(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_profiles_spa_id ON public.profiles (spa_id);

-- ── 2. Agregar constraints de roles y consistencia de tenant ──────
ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_role_check;
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_role_check
  CHECK (role IN ('superadmin', 'admin_spa', 'recepcionista', 'terapeuta'));

-- superadmin sin spa_id; los demás con spa_id
ALTER TABLE public.profiles
  DROP CONSTRAINT IF EXISTS profiles_tenant_consistency;
ALTER TABLE public.profiles
  ADD CONSTRAINT profiles_tenant_consistency CHECK (
    (role = 'superadmin' AND spa_id IS NULL) OR
    (role != 'superadmin' AND spa_id IS NOT NULL)
  );

-- ── 3. Trigger: impedir eliminar el último admin_spa de un spa ────
CREATE OR REPLACE FUNCTION public.prevent_last_admin_spa_removal()
RETURNS trigger LANGUAGE plpgsql SET search_path = public AS $$
BEGIN
  IF TG_OP = 'UPDATE' THEN
    IF OLD.role = 'admin_spa' AND NEW.role <> 'admin_spa'
      AND NOT EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id <> OLD.id AND p.role = 'admin_spa' AND p.spa_id = OLD.spa_id
      ) THEN
      RAISE EXCEPTION 'Debe existir al menos un admin_spa activo por spa.';
    END IF;
    RETURN NEW;
  END IF;

  IF TG_OP = 'DELETE' THEN
    IF OLD.role = 'admin_spa'
      AND NOT EXISTS (
        SELECT 1 FROM public.profiles p
        WHERE p.id <> OLD.id AND p.role = 'admin_spa' AND p.spa_id = OLD.spa_id
      ) THEN
      RAISE EXCEPTION 'No puedes eliminar al último admin_spa del spa.';
    END IF;
    RETURN OLD;
  END IF;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS prevent_last_admin_spa_update ON public.profiles;
CREATE TRIGGER prevent_last_admin_spa_update
BEFORE UPDATE OF role ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.prevent_last_admin_spa_removal();

DROP TRIGGER IF EXISTS prevent_last_admin_spa_delete ON public.profiles;
CREATE TRIGGER prevent_last_admin_spa_delete
BEFORE DELETE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.prevent_last_admin_spa_removal();

-- ── 4. Tabla CLIENTES ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.clientes (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  spa_id              uuid NOT NULL REFERENCES public.spas(id) ON DELETE CASCADE,
  nombre              text NOT NULL,
  telefono            text,
  correo              text,
  fecha_nacimiento    date,
  genero              text CHECK (genero IN ('F', 'M', 'O')),
  alergias            text,
  notas_preferencias  text,
  fecha_ultima_visita timestamptz,
  created_at          timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_clientes_spa_id  ON public.clientes (spa_id);
CREATE INDEX IF NOT EXISTS idx_clientes_nombre  ON public.clientes (spa_id, nombre);
CREATE INDEX IF NOT EXISTS idx_clientes_telefono ON public.clientes (spa_id, telefono);

-- ── 5. RLS — CLIENTES ────────────────────────────────────────────
ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;

-- admin_spa y recepcionista: todos los clientes del spa
DROP POLICY IF EXISTS "clientes_tenant_staff" ON public.clientes;
CREATE POLICY "clientes_tenant_staff"
ON public.clientes FOR ALL TO authenticated
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

-- terapeutas: solo ven clientes de sus citas (FK circular resuelta con subquery diferida)
DROP POLICY IF EXISTS "clientes_terapeuta_view" ON public.clientes;
CREATE POLICY "clientes_terapeuta_view"
ON public.clientes FOR SELECT TO authenticated
USING (
  spa_id = public.current_spa_id()
  AND public.current_app_role() = 'terapeuta'
  AND public.tenant_is_active()
);

GRANT SELECT, INSERT, UPDATE, DELETE ON public.clientes TO authenticated;

COMMENT ON TABLE public.clientes IS 'Clientes del spa. Aislados por spa_id (tenant).';
COMMENT ON COLUMN public.clientes.alergias IS 'Contraindicaciones o alergias médicas.';
COMMENT ON COLUMN public.clientes.notas_preferencias IS 'Preferencias: terapeuta, intensidad, aromas, etc.';

-- ── Promover primer superadmin (ejecutar manualmente después) ──────
-- UPDATE public.profiles SET role = 'superadmin', spa_id = NULL
-- WHERE email = 'tu@email.com';
