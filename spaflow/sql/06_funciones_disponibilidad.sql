-- ══════════════════════════════════════════════════════════════════
-- 06_funciones_disponibilidad.sql
-- SpaFlow — Función de disponibilidad de terapeutas
-- Ejecutar SÉPTIMO
-- ══════════════════════════════════════════════════════════════════

-- ── get_disponibilidad ────────────────────────────────────────────
-- Retorna los slots de tiempo libres de un terapeuta en una fecha dada,
-- excluyendo citas activas y bloqueos de agenda.
--
-- Parámetros:
--   p_personal_id  → UUID del terapeuta
--   p_fecha        → Fecha a consultar (date)
--   p_duracion_min → Duración requerida en minutos
--   p_spa_id       → UUID del spa (validación de tenant)
--
-- Retorna: tabla con (slot_inicio timestamptz, slot_fin timestamptz)

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
  -- Zona horaria del spa
  v_tz           text;
  -- Variables de horario del terapeuta para ese día
  v_dia_semana   int;
  v_hora_inicio  time;
  v_hora_fin     time;
  -- Iteración de slots
  v_slot_inicio  timestamptz;
  v_slot_fin     timestamptz;
  v_dia_inicio   timestamptz;
  v_dia_fin      timestamptz;
  -- Tamaño del slot en intervalo
  v_intervalo    interval;
BEGIN
  -- Validar tenant
  IF p_spa_id IS NOT NULL THEN
    IF NOT EXISTS (
      SELECT 1 FROM public.personal
      WHERE id = p_personal_id AND spa_id = p_spa_id AND activo = true
    ) THEN
      RETURN; -- Terapeuta no pertenece a este spa
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

  -- Día de la semana del período solicitado (0=Dom, 1=Lun, ...)
  v_dia_semana := EXTRACT(DOW FROM p_fecha)::int;

  -- Obtener horario del terapeuta para ese día
  SELECT hp.hora_inicio, hp.hora_fin
  INTO v_hora_inicio, v_hora_fin
  FROM public.horarios_personal hp
  WHERE hp.personal_id = p_personal_id
    AND hp.dia_semana = v_dia_semana
    AND hp.activo = true;

  -- Si no tiene horario ese día, no hay slots disponibles
  IF NOT FOUND THEN
    RETURN;
  END IF;

  -- Calcular timestamps de inicio y fin del día laboral EN la zona horaria del spa.
  -- CORRECTO: timezone(tz, timestamp_sin_tz) interpreta el timestamp como hora LOCAL del spa
  -- y devuelve un timestamptz (valor absoluto UTC) equivalente.
  -- ❌ NO usar: (fecha || ' ' || hora)::timestamptz AT TIME ZONE tz  → doble conversión
  v_dia_inicio := timezone(v_tz, (p_fecha::text || ' ' || v_hora_inicio::text)::timestamp);
  v_dia_fin    := timezone(v_tz, (p_fecha::text || ' ' || v_hora_fin::text)::timestamp);
  v_intervalo  := (p_duracion_min || ' minutes')::interval;

  -- Iterar slots de p_duracion_min minutos dentro del horario laboral
  v_slot_inicio := v_dia_inicio;

  WHILE v_slot_inicio + v_intervalo <= v_dia_fin LOOP
    v_slot_fin := v_slot_inicio + v_intervalo;

    -- Verificar que el slot NO se traslape con:
    -- 1. Citas activas del terapeuta (AGENDADA, CONFIRMADA, EN_CURSO)
    -- 2. Bloqueos de agenda del terapeuta o del spa
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
        AND b.spa_id = (
          SELECT spa_id FROM public.personal WHERE id = p_personal_id
        )
        AND b.fecha_inicio < v_slot_fin
        AND b.fecha_fin    > v_slot_inicio
    )
    THEN
      -- Slot disponible
      slot_inicio := v_slot_inicio;
      slot_fin    := v_slot_fin;
      RETURN NEXT;
    END IF;

    v_slot_inicio := v_slot_inicio + v_intervalo;
  END LOOP;

  RETURN;
END;
$$;

-- ── get_disponibilidad_dia ────────────────────────────────────────
-- Vista simplificada: todos los terapeutas activos de un spa
-- y sus slots libres en una fecha dada para una duración dada.

CREATE OR REPLACE FUNCTION public.get_disponibilidad_spa(
  p_spa_id       uuid,
  p_fecha        date,
  p_duracion_min int
)
RETURNS TABLE (
  personal_id   uuid,
  nombre        text,
  color_agenda  text,
  slot_inicio   timestamptz,
  slot_fin      timestamptz
)
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  RETURN QUERY
  SELECT
    p.id,
    p.nombre,
    p.color_agenda,
    d.slot_inicio,
    d.slot_fin
  FROM public.personal p
  CROSS JOIN LATERAL public.get_disponibilidad(p.id, p_fecha, p_duracion_min, p_spa_id) d
  WHERE p.spa_id = p_spa_id
    AND p.activo = true
  ORDER BY p.nombre, d.slot_inicio;
END;
$$;

-- ── Permisos ─────────────────────────────────────────────────────
GRANT EXECUTE ON FUNCTION public.get_disponibilidad(uuid, date, int, uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_disponibilidad_spa(uuid, date, int) TO authenticated;

COMMENT ON FUNCTION public.get_disponibilidad IS
  'Retorna slots de tiempo disponibles de un terapeuta en una fecha dada, '
  'excluyendo citas activas y bloqueos. El paso del slot es p_duracion_min minutos.';

COMMENT ON FUNCTION public.get_disponibilidad_spa IS
  'Retorna todos los slots disponibles de todos los terapeutas activos del spa en una fecha.';
