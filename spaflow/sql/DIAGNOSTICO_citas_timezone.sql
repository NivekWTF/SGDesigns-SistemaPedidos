-- ══════════════════════════════════════════════════════════════════
-- DIAGNOSTICO: Ver citas con hora local del spa
-- Ejecutar en Supabase SQL Editor para confirmar las horas
-- ══════════════════════════════════════════════════════════════════

-- 1. Ver citas con hora convertida a zona horaria del spa
SELECT
  c.folio,
  c.estado,
  -- Hora tal como está guardada (UTC)
  c.fecha_inicio AS utc_inicio,
  -- Hora convertida a México (así debe mostrarse al usuario)
  (c.fecha_inicio AT TIME ZONE 'America/Mexico_City') AS hora_mexico,
  cl.nombre AS cliente,
  p.nombre  AS terapeuta
FROM public.citas c
LEFT JOIN public.clientes cl ON cl.id = c.cliente_id
LEFT JOIN public.personal p  ON p.id  = c.personal_id
ORDER BY c.fecha_inicio DESC
LIMIT 10;

-- 2. Probar get_disponibilidad con el timezone fix aplicado
-- (Reemplaza el UUID con el de un terapeuta real)
-- SELECT
--   slot_inicio AT TIME ZONE 'America/Mexico_City' AS hora_local,
--   slot_fin    AT TIME ZONE 'America/Mexico_City' AS hora_fin_local
-- FROM get_disponibilidad(
--   (SELECT id FROM public.personal LIMIT 1),
--   CURRENT_DATE + 1,
--   60
-- );
