-- Add costo_material column to productos (run in Supabase SQL editor)
alter table if exists public.productos
add column if not exists costo_material numeric default 0;

-- Optional: backfill existing products with a sensible default (uncomment to run)
-- update public.productos set costo_material = 0 where costo_material is null;
