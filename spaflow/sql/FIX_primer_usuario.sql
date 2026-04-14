-- ══════════════════════════════════════════════════════════════════
-- FIX: primer_usuario.sql
-- SpaFlow — Corregir trigger y crear primer superadmin
-- Ejecutar en Supabase SQL Editor ANTES de registrar el primer usuario
-- ══════════════════════════════════════════════════════════════════

-- ── 1. Corregir el trigger de new_user ────────────────────────────
-- Problema: sin spa_id en metadata, el trigger inserta role='admin_spa'
-- con spa_id=NULL, violando el constraint de consistencia.
-- Fix: si no viene spa_id, asignar role='superadmin' automáticamente.

CREATE OR REPLACE FUNCTION public.handle_new_user_profile()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_spa_id uuid;
  v_role   text;
BEGIN
  -- Obtener spa_id y role de los metadatos del usuario
  v_spa_id := (NEW.raw_user_meta_data->>'spa_id')::uuid;
  v_role   := NEW.raw_user_meta_data->>'role';

  -- Si no hay spa_id ni role explícito → es el primero = superadmin
  -- Si hay spa_id pero no role → admin_spa del tenant
  IF v_role IS NULL THEN
    v_role := CASE WHEN v_spa_id IS NULL THEN 'superadmin' ELSE 'admin_spa' END;
  END IF;

  INSERT INTO public.profiles (id, email, full_name, role, spa_id)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(
      NEW.raw_user_meta_data->>'full_name',
      NEW.raw_user_meta_data->>'name'
    ),
    v_role,
    v_spa_id
  )
  ON CONFLICT (id) DO UPDATE SET
    email     = EXCLUDED.email,
    full_name = COALESCE(EXCLUDED.full_name, public.profiles.full_name);

  RETURN NEW;
END;
$$;

-- ── 2. Verificar que el trigger sigue activo ──────────────────────
DROP TRIGGER IF EXISTS on_auth_user_created_create_profile ON auth.users;
CREATE TRIGGER on_auth_user_created_create_profile
AFTER INSERT ON auth.users
FOR EACH ROW EXECUTE FUNCTION public.handle_new_user_profile();

-- ── 3. Si ya intentaste registrarte y fallaste: ───────────────────
-- Puede que el profile quedó a medias. Este SELECT te dirá si hay
-- usuarios en auth.users sin profile válido:
--
-- SELECT au.id, au.email, p.role, p.spa_id
-- FROM auth.users au
-- LEFT JOIN public.profiles p ON p.id = au.id;
--
-- Si hay filas con role=NULL o spa_id incorrecto, corre:
--
-- UPDATE public.profiles
-- SET role = 'superadmin', spa_id = NULL
-- WHERE email = 'TU_EMAIL@ejemplo.com';

SELECT 'Trigger corregido ✅ — Ahora ve a registrarte en la app' AS resultado;
