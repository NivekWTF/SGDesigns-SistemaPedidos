-- ============================================================
-- BUSINESS CONFIG TABLE — Configuración del negocio in-app
-- ============================================================
-- Permite al admin cambiar nombre, logo, colores, etc.
-- sin necesidad de tocar código o variables de entorno.
-- ============================================================

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
  -- Whitelabel colors
  color_primary text DEFAULT '#0ea5e9',
  color_primary_dark text DEFAULT '#0284c7',
  color_accent text DEFAULT '#38bdf8',
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Only one row should exist; this trigger ensures single-row
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

-- Auto-update timestamp
DROP TRIGGER IF EXISTS set_business_config_updated_at ON public.business_config;
CREATE TRIGGER set_business_config_updated_at
  BEFORE UPDATE ON public.business_config
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- RLS: only admins can read/write
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

-- Seed with defaults (will be overwritten by admin)
INSERT INTO public.business_config (
  business_name, business_rfc, business_email,
  business_address, business_phone, business_logo_url,
  business_socials, business_series, tax_rate,
  color_primary, color_primary_dark, color_accent
) VALUES (
  NULL, NULL, NULL,
  NULL, NULL, NULL,
  NULL, 'COT', 0.16,
  '#0ea5e9', '#0284c7', '#38bdf8'
);
