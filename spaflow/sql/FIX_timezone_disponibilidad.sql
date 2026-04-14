-- ══════════════════════════════════════════════════════════════════
-- FIX: timezone_disponibilidad.sql
-- Corrige el bug de doble conversión de zona horaria en get_disponibilidad
-- EJECUTAR EN SUPABASE SQL EDITOR
-- ══════════════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.get_disponibilidad(
  p_personal_id  uuid,
  p_fecha        date,
  p_duracion_min int,
  p_spa_id       uuid DEFAULT NULL
)
RETURNS TABLE (
  slot_inicio timestamptz,
  slot_fin    timestamptz
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_tz           text;
  v_dia_semana   int;
  v_hora_inicio  time;
  v_hora_fin     time;
  v_slot_inicio  timestamptz;
  v_slot_fin     timestamptz;
  v_dia_inicio   timestamptz;
  v_dia_fin      timestamptz;
  v_intervalo    interval;
BEGIN
  -- Validar tenant
  IF p_spa_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.personal
      WHERE id = p_personal_id AND spa_id = p_spa_id AND activo = true
    ) THEN
      RETURN;
    END IF;
  END IF;

  -- Obtener zona horaria del spa
  SELECT s.zona_horaria INTO v_tz
  FROM public.personal p
  JOIN public.spas s ON s.id = p.spa_id
  WHERE p.id = p_personal_id;

  IF v_tz IS NULL THEN
    v_tz := 'America/Mexico_City';
  END IF;

  -- Día de la semana (0=Dom, 1=Lun, ...)
  v_dia_semana := EXTRACT(DOW FROM p_fecha)::int;

  -- Obtener horario del terapeuta para ese día
  SELECT hp.hora_inicio, hp.hora_fin
  INTO v_hora_inicio, v_hora_fin
  FROM public.horarios_personal hp
  WHERE hp.personal_id = p_personal_id
    AND hp.dia_semana = v_dia_semana
    AND hp.activo = true;

  IF NOT FOUND THEN
    RETURN;
  END IF;

  -- ── CORRECCIÓN TIMEZONE ──────────────────────────────────────────
  -- timezone(tz, local_ts) interpreta local_ts como hora LOCAL en tz
  -- y retorna el timestamptz UTC equivalente.
  --
  -- ❌ Bug anterior: (fecha || hora)::timestamptz AT TIME ZONE tz
  --    PostgreSQL primero convierte a UTC (asumiendo UTC del servidor),
  --    luego AT TIME ZONE lo desplaza de nuevo → doble conversión.
  --
  -- ✅ Fix: timezone() hace UNA sola conversión local→UTC.
  -- ────────────────────────────────────────────────────────────────
  v_dia_inicio := timezone(v_tz, (p_fecha::text || ' ' || v_hora_inicio::text)::timestamp);
  v_dia_fin    := timezone(v_tz, (p_fecha::text || ' ' || v_hora_fin::text)::timestamp);
  v_intervalo  := (p_duracion_min || ' minutes')::interval;

  v_slot_inicio := v_dia_inicio;

  WHILE v_slot_inicio + v_intervalo <= v_dia_fin LOOP
    v_slot_fin := v_slot_inicio + v_intervalo;

    IF NOT EXISTS (
      SELECT 1 FROM public.citas c
      WHERE c.personal_id = p_personal_id
        AND c.estado IN ('AGENDADA', 'CONFIRMADA', 'EN_CURSO')
        AND c.fecha_inicio < v_slot_fin
        AND c.fecha_fin    > v_slot_inicio
    )
    AND NOT EXISTS (
      SELECT 1 FROM public.bloqueos_agenda b
      WHERE (b.personal_id = p_personal_id OR b.personal_id IS NULL)
        AND b.spa_id = (SELECT spa_id FROM public.personal WHERE id = p_personal_id)
        AND b.fecha_inicio < v_slot_fin
        AND b.fecha_fin    > v_slot_inicio
    )
    THEN
      slot_inicio := v_slot_inicio;
      slot_fin    := v_slot_fin;
      RETURN NEXT;
    END IF;

    v_slot_inicio := v_slot_inicio + v_intervalo;
  END LOOP;

  RETURN;
END;
$$;

-- ── Verificación rápida ───────────────────────────────────────────
-- Descomenta y ajusta el UUID para probar:
-- SELECT
--   slot_inicio AT TIME ZONE 'America/Mexico_City' AS hora_local,
--   slot_fin    AT TIME ZONE 'America/Mexico_City' AS hora_fin_local
-- FROM get_disponibilidad(
--   'UUID-DEL-TERAPEUTA'::uuid,
--   CURRENT_DATE,
--   60
-- );

SELECT 'Fix aplicado ✅ — recarga la app y vuelve a buscar slots' AS resultado;
