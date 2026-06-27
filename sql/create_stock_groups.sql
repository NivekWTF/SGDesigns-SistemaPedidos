-- ============================================================
-- Stock Groups: allow products to share the same physical stock
-- ============================================================
-- When products belong to the same stock_group, updating the
-- stock of one product automatically updates all siblings.
--
-- Run this script in Supabase SQL Editor.
-- ============================================================

-- 1) Create the stock_groups table
CREATE TABLE IF NOT EXISTS public.stock_groups (
  id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  nombre text NOT NULL,
  created_at timestamptz DEFAULT now()
);

-- 2) Add stock_group_id column to productos
ALTER TABLE public.productos
ADD COLUMN IF NOT EXISTS stock_group_id uuid REFERENCES public.stock_groups(id) ON DELETE SET NULL;

-- 3) Create index for fast lookups
CREATE INDEX IF NOT EXISTS idx_productos_stock_group_id ON public.productos(stock_group_id);

-- 4) Trigger function: sync stock across all products in the same group
CREATE OR REPLACE FUNCTION public.sync_stock_group()
RETURNS trigger AS $$
BEGIN
  -- Skip if no stock_group_id or stock didn't change
  IF NEW.stock_group_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF OLD.stock IS NOT DISTINCT FROM NEW.stock THEN
    RETURN NEW;
  END IF;

  -- Prevent infinite recursion: if we're already syncing, skip
  IF current_setting('app.syncing_stock_group', true) = 'true' THEN
    RETURN NEW;
  END IF;

  -- Set the guard flag
  PERFORM set_config('app.syncing_stock_group', 'true', true);

  -- Update all sibling products in the same group
  UPDATE public.productos
  SET stock = NEW.stock
  WHERE stock_group_id = NEW.stock_group_id
    AND id != NEW.id;

  -- Reset the guard flag
  PERFORM set_config('app.syncing_stock_group', 'false', true);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 5) Attach the trigger to productos
DROP TRIGGER IF EXISTS trg_sync_stock_group ON public.productos;
CREATE TRIGGER trg_sync_stock_group
  AFTER UPDATE OF stock ON public.productos
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_stock_group();

-- 6) Trigger for when a product JOINS a stock group (stock_group_id changes)
--    It should inherit the stock from existing group members.
CREATE OR REPLACE FUNCTION public.sync_stock_group_on_join()
RETURNS trigger AS $$
DECLARE
  group_stock numeric;
BEGIN
  -- Only act when stock_group_id changed to a non-null value
  IF NEW.stock_group_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF OLD.stock_group_id IS NOT DISTINCT FROM NEW.stock_group_id THEN
    RETURN NEW;
  END IF;

  -- Prevent recursion
  IF current_setting('app.syncing_stock_group', true) = 'true' THEN
    RETURN NEW;
  END IF;

  -- Get stock from an existing member of the group
  SELECT p.stock INTO group_stock
  FROM public.productos p
  WHERE p.stock_group_id = NEW.stock_group_id
    AND p.id != NEW.id
  LIMIT 1;

  -- If group already has members, adopt their stock
  IF group_stock IS NOT NULL THEN
    NEW.stock := group_stock;
  ELSE
    -- First member of the group: propagate nothing (it keeps its own stock)
    NULL;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trg_sync_stock_group_on_join ON public.productos;
CREATE TRIGGER trg_sync_stock_group_on_join
  BEFORE UPDATE OF stock_group_id ON public.productos
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_stock_group_on_join();

-- 7) RLS for stock_groups
ALTER TABLE public.stock_groups ENABLE ROW LEVEL SECURITY;

-- Admin: full access
CREATE POLICY stock_groups_admin_all ON public.stock_groups
  FOR ALL
  USING (public.has_app_role(array['admin']))
  WITH CHECK (public.has_app_role(array['admin']));

-- Empleado: read-only
CREATE POLICY stock_groups_empleado_select ON public.stock_groups
  FOR SELECT
  USING (public.has_app_role(array['admin', 'empleado']));
