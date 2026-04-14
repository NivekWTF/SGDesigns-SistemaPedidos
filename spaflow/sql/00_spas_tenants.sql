-- ══════════════════════════════════════════════════════════════════
-- 00_spas_tenants.sql
-- SpaFlow — Tablas base: profiles + spas + funciones RBAC helpers
-- Ejecutar PRIMERO en un proyecto Supabase completamente nuevo
-- ══════════════════════════════════════════════════════════════════

-- ── 1. Tabla SPAS (va primero porque profiles la referencia) ──────
CREATE TABLE IF NOT EXISTS public.spas (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre          text NOT NULL,
  slug            text UNIQUE NOT NULL,
  logo_url        text,
  color_primario  text NOT NULL DEFAULT '#8b5cf6',
  zona_horaria    text NOT NULL DEFAULT 'America/Mexico_City',
  plan            text NOT NULL DEFAULT 'basic'
                  CHECK (plan IN ('basic', 'pro', 'enterprise')),
  activo          boolean NOT NULL DEFAULT true,
  trial_hasta     date,
  created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_spas_slug   ON public.spas (slug);
CREATE INDEX IF NOT EXISTS idx_spas_activo ON public.spas (activo);

-- ── 2. Tabla PROFILES (con spa_id desde el inicio) ────────────────
-- En Supabase nuevo no existe; la creamos nosotros.
-- Ya incluye spa_id para que current_spa_id() funcione de inmediato.

CREATE TABLE IF NOT EXISTS public.profiles (
  id          uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email       text,
  full_name   text,
  role        text NOT NULL DEFAULT 'admin_spa',
  spa_id      uuid REFERENCES public.spas(id) ON DELETE SET NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_profiles_spa_id ON public.profiles (spa_id);

-- Trigger updated_at reutilizable
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at := now(); RETURN NEW; END;
$$;

DROP TRIGGER IF EXISTS set_profiles_updated_at ON public.profiles;
CREATE TRIGGER set_profiles_updated_at
BEFORE UPDATE ON public.profiles
FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ── 3. Funciones RBAC helpers ──────────────────────────────────────

-- Rol actual del usuario autenticado
CREATE OR REPLACE FUNCTION public.current_app_role()
RETURNS text
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

-- spa_id del usuario autenticado
CREATE OR REPLACE FUNCTION public.current_spa_id()
RETURNS uuid
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT spa_id FROM public.profiles WHERE id = auth.uid();
$$;

-- ¿Tiene el usuario alguno de los roles indicados?
CREATE OR REPLACE FUNCTION public.has_app_role(allowed_roles text[])
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT auth.role() = 'authenticated'
    AND COALESCE(public.current_app_role() = ANY(allowed_roles), false);
$$;

-- ¿Es superadmin?
CREATE OR REPLACE FUNCTION public.is_superadmin()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT public.current_app_role() = 'superadmin';
$$;

-- ¿El spa del usuario está activo?
CREATE OR REPLACE FUNCTION public.tenant_is_active()
RETURNS boolean
LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT COALESCE(
    (SELECT activo FROM public.spas WHERE id = public.current_spa_id()),
    false
  );
$$;

-- ── 4. Trigger: crear profile al registrar usuario en auth ────────
-- Si no se pasa spa_id en los metadatos → rol superadmin (primer usuario del SaaS)
-- Si se pasa spa_id pero no role → admin_spa del tenant
CREATE OR REPLACE FUNCTION public.handle_new_user_profile()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE
  v_spa_id uuid;
  v_role   text;
BEGIN
  v_spa_id := (NEW.raw_user_meta_data->>'spa_id')::uuid;
  v_role   := NEW.raw_user_meta_data->>'role';

  IF v_role IS NULL THEN
    v_role := CASE WHEN v_spa_id IS NULL THEN 'superadmin' ELSE 'admin_spa' END;
  END IF;

  INSERT INTO public.profiles (id, email, full_name, role, spa_id)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name'),
    v_role,
    v_spa_id
  )
  ON CONFLICT (id) DO UPDATE SET
    email     = EXCLUDED.email,
    full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS on_auth_user_created_create_profile ON auth.users;
CREATE TRIGGER on_auth_user_created_create_profile
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_profile();

-- ── 5. RLS — PROFILES ─────────────────────────────────────────────
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "profiles_select_self_or_admin" ON public.profiles;
CREATE POLICY "profiles_select_self_or_admin"
ON public.profiles FOR SELECT TO authenticated
USING (
  id = auth.uid()
  OR public.is_superadmin()
  OR (public.current_app_role() = 'admin_spa'
      AND spa_id = public.current_spa_id())
);

DROP POLICY IF EXISTS "profiles_update_admin_only" ON public.profiles;
CREATE POLICY "profiles_update_admin_only"
ON public.profiles FOR UPDATE TO authenticated
USING (
  public.is_superadmin()
  OR (public.current_app_role() = 'admin_spa' AND spa_id = public.current_spa_id())
)
WITH CHECK (
  public.is_superadmin()
  OR (public.current_app_role() = 'admin_spa' AND spa_id = public.current_spa_id())
);

GRANT SELECT, UPDATE ON public.profiles TO authenticated;

-- ── 6. RLS — SPAS ────────────────────────────────────────────────
ALTER TABLE public.spas ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "spas_superadmin_all" ON public.spas;
CREATE POLICY "spas_superadmin_all"
ON public.spas FOR ALL TO authenticated
USING (public.is_superadmin())
WITH CHECK (public.is_superadmin());

DROP POLICY IF EXISTS "spas_own_tenant_select" ON public.spas;
CREATE POLICY "spas_own_tenant_select"
ON public.spas FOR SELECT TO authenticated
USING (
  id = public.current_spa_id()
  AND public.has_app_role(ARRAY['admin_spa', 'recepcionista', 'terapeuta'])
);

DROP POLICY IF EXISTS "spas_own_tenant_update" ON public.spas;
CREATE POLICY "spas_own_tenant_update"
ON public.spas FOR UPDATE TO authenticated
USING (id = public.current_spa_id() AND public.current_app_role() = 'admin_spa')
WITH CHECK (id = public.current_spa_id() AND public.current_app_role() = 'admin_spa');

GRANT SELECT, UPDATE ON public.spas TO authenticated;

COMMENT ON TABLE public.profiles IS 'Perfiles de usuario con rol y spa_id (tenant).';
COMMENT ON TABLE public.spas IS 'Tenants del SaaS SpaFlow. Cada fila es un spa cliente.';
COMMENT ON FUNCTION public.current_spa_id IS 'Retorna el spa_id del usuario autenticado.';
COMMENT ON FUNCTION public.current_app_role IS 'Retorna el rol del usuario autenticado.';
