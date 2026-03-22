-- Fix: Allow decimal quantities in pedido_items
-- The 'cantidad' column was likely defined as integer, which truncates
-- decimal values like 1.2 → 1 on insert.
-- This migration changes it to numeric to preserve decimals.

ALTER TABLE pedido_items
  ALTER COLUMN cantidad TYPE numeric USING cantidad::numeric;

-- Also update the subtotal trigger/default if it exists, to recalculate with decimals
-- (The subtotal column should already be numeric, but let's make sure)
ALTER TABLE pedido_items
  ALTER COLUMN subtotal TYPE numeric USING subtotal::numeric;
