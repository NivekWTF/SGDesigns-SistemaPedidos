-- ══════════════════════════════════════════════════════════════════
-- 07_funciones_reportes.sql
-- SpaFlow — Views y funciones para dashboard y reportes
-- Ejecutar OCTAVO (último)
-- ══════════════════════════════════════════════════════════════════

-- ── KPIs del Día ─────────────────────────────────────────────────
-- Función principal del dashboard: métricas del día para el spa activo

CREATE OR REPLACE FUNCTION public.get_kpis_dia(
  p_spa_id uuid,
  p_fecha  date DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  citas_agendadas   bigint,
  citas_confirmadas bigint,
  citas_en_curso    bigint,
  citas_completadas bigint,
  citas_canceladas  bigint,
  citas_no_show     bigint,
  total_ingresos    numeric,
  total_anticipos   numeric,
  tasa_ocupacion    numeric   -- porcentaje completadas / (total - canceladas)
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    COUNT(*) FILTER (WHERE estado = 'AGENDADA')    AS citas_agendadas,
    COUNT(*) FILTER (WHERE estado = 'CONFIRMADA')  AS citas_confirmadas,
    COUNT(*) FILTER (WHERE estado = 'EN_CURSO')    AS citas_en_curso,
    COUNT(*) FILTER (WHERE estado = 'COMPLETADA')  AS citas_completadas,
    COUNT(*) FILTER (WHERE estado = 'CANCELADA')   AS citas_canceladas,
    COUNT(*) FILTER (WHERE estado = 'NO_SHOW')     AS citas_no_show,

    COALESCE((
      SELECT SUM(monto) FROM public.pagos_cita pc
      JOIN public.citas c2 ON c2.id = pc.cita_id
      WHERE c2.spa_id = p_spa_id
        AND DATE(pc.creado_en) = p_fecha
    ), 0) AS total_ingresos,

    COALESCE((
      SELECT SUM(monto) FROM public.pagos_cita pc
      JOIN public.citas c2 ON c2.id = pc.cita_id
      WHERE c2.spa_id = p_spa_id
        AND pc.es_anticipo = true
        AND DATE(pc.creado_en) = p_fecha
    ), 0) AS total_anticipos,

    ROUND(
      CASE
        WHEN COUNT(*) FILTER (WHERE estado NOT IN ('CANCELADA')) = 0 THEN 0
        ELSE (
          COUNT(*) FILTER (WHERE estado = 'COMPLETADA')::numeric /
          COUNT(*) FILTER (WHERE estado NOT IN ('CANCELADA'))::numeric * 100
        )
      END, 1
    ) AS tasa_ocupacion

  FROM public.citas
  WHERE spa_id = p_spa_id
    AND DATE(fecha_inicio) = p_fecha;
$$;

-- ── Citas de la próximas N horas ─────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_proximas_citas(
  p_spa_id uuid,
  p_horas  int DEFAULT 3
)
RETURNS TABLE (
  id           uuid,
  folio        text,
  estado       public.estado_cita,
  fecha_inicio timestamptz,
  fecha_fin    timestamptz,
  cliente_nombre text,
  personal_nombre text,
  servicios    text    -- nombres separados por coma
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    c.id,
    c.folio,
    c.estado,
    c.fecha_inicio,
    c.fecha_fin,
    cl.nombre AS cliente_nombre,
    p.nombre  AS personal_nombre,
    STRING_AGG(DISTINCT s.nombre, ', ' ORDER BY s.nombre) AS servicios
  FROM public.citas c
  JOIN public.clientes cl ON cl.id = c.cliente_id
  LEFT JOIN public.personal p ON p.id = c.personal_id
  LEFT JOIN public.cita_items ci ON ci.cita_id = c.id
  LEFT JOIN public.servicios s ON s.id = ci.servicio_id
  WHERE c.spa_id = p_spa_id
    AND c.estado IN ('AGENDADA', 'CONFIRMADA', 'EN_CURSO')
    AND c.fecha_inicio BETWEEN now() AND now() + (p_horas || ' hours')::interval
  GROUP BY c.id, c.folio, c.estado, c.fecha_inicio, c.fecha_fin, cl.nombre, p.nombre
  ORDER BY c.fecha_inicio;
$$;

-- ── Ingresos por período ──────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_ingresos_periodo(
  p_spa_id     uuid,
  p_desde      date,
  p_hasta      date,
  p_agrupacion text DEFAULT 'dia'   -- 'dia' | 'semana' | 'mes'
)
RETURNS TABLE (
  periodo        text,
  total_ingresos numeric,
  num_citas      bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    CASE p_agrupacion
      WHEN 'semana' THEN TO_CHAR(DATE_TRUNC('week', c.fecha_inicio), 'YYYY-IW')
      WHEN 'mes'    THEN TO_CHAR(c.fecha_inicio, 'YYYY-MM')
      ELSE               TO_CHAR(c.fecha_inicio, 'YYYY-MM-DD')
    END AS periodo,
    COALESCE(SUM(pc.monto), 0) AS total_ingresos,
    COUNT(DISTINCT c.id)       AS num_citas
  FROM public.citas c
  LEFT JOIN public.pagos_cita pc ON pc.cita_id = c.id
  WHERE c.spa_id = p_spa_id
    AND DATE(c.fecha_inicio) BETWEEN p_desde AND p_hasta
    AND c.estado = 'COMPLETADA'
  GROUP BY periodo
  ORDER BY periodo;
$$;

-- ── Top servicios del mes ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_top_servicios(
  p_spa_id uuid,
  p_desde  date,
  p_hasta  date,
  p_limit  int DEFAULT 10
)
RETURNS TABLE (
  servicio_id  uuid,
  nombre       text,
  categoria    text,
  num_veces    bigint,
  total_ingreso numeric
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    s.id,
    s.nombre,
    s.categoria,
    COUNT(ci.id)          AS num_veces,
    SUM(ci.subtotal)      AS total_ingreso
  FROM public.cita_items ci
  JOIN public.servicios s ON s.id = ci.servicio_id
  JOIN public.citas c ON c.id = ci.cita_id
  WHERE c.spa_id = p_spa_id
    AND DATE(c.fecha_inicio) BETWEEN p_desde AND p_hasta
    AND c.estado = 'COMPLETADA'
  GROUP BY s.id, s.nombre, s.categoria
  ORDER BY num_veces DESC
  LIMIT p_limit;
$$;

-- ── Productividad por terapeuta ───────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_productividad_personal(
  p_spa_id uuid,
  p_desde  date,
  p_hasta  date
)
RETURNS TABLE (
  personal_id   uuid,
  nombre        text,
  color_agenda  text,
  citas_completadas bigint,
  citas_no_show     bigint,
  total_ingreso     numeric,
  minutos_trabajados bigint
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT
    p.id,
    p.nombre,
    p.color_agenda,
    COUNT(*) FILTER (WHERE c.estado = 'COMPLETADA') AS citas_completadas,
    COUNT(*) FILTER (WHERE c.estado = 'NO_SHOW')    AS citas_no_show,
    COALESCE(SUM(c.total) FILTER (WHERE c.estado = 'COMPLETADA'), 0) AS total_ingreso,
    COALESCE(
      SUM(
        EXTRACT(EPOCH FROM (c.fecha_fin - c.fecha_inicio)) / 60
      ) FILTER (WHERE c.estado = 'COMPLETADA'),
      0
    )::bigint AS minutos_trabajados
  FROM public.personal p
  LEFT JOIN public.citas c ON c.personal_id = p.id
    AND DATE(c.fecha_inicio) BETWEEN p_desde AND p_hasta
  WHERE p.spa_id = p_spa_id
  GROUP BY p.id, p.nombre, p.color_agenda
  ORDER BY total_ingreso DESC;
$$;

-- ── Saldo de caja del día ─────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_resumen_caja_dia(
  p_spa_id uuid,
  p_fecha  date DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  total_entradas numeric,
  total_salidas  numeric,
  saldo_dia      numeric,
  por_metodo     jsonb   -- {"EFECTIVO": 1000, "TRANSFERENCIA": 500, ...}
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  WITH movs AS (
    -- Todos los movimientos del día del tenant
    SELECT metodo_pago, es_entrada, monto
    FROM public.movimientos_caja
    WHERE spa_id = p_spa_id
      AND DATE(created_at) = p_fecha
  ),
  totales AS (
    -- Totales globales de entradas y salidas
    SELECT
      COALESCE(SUM(monto) FILTER (WHERE es_entrada = true),  0) AS total_entradas,
      COALESCE(SUM(monto) FILTER (WHERE es_entrada = false), 0) AS total_salidas
    FROM movs
  ),
  por_metodo_sums AS (
    -- Suma de entradas agrupada por método de pago (sin anidar aggregates)
    SELECT
      metodo_pago,
      COALESCE(SUM(monto) FILTER (WHERE es_entrada = true), 0) AS total_entrada
    FROM movs
    GROUP BY metodo_pago
  ),
  por_metodo_json AS (
    -- Convertir a JSONB ahora que los sums ya están calculados
    SELECT COALESCE(
      JSONB_OBJECT_AGG(metodo_pago, total_entrada),
      '{}'::jsonb
    ) AS por_metodo
    FROM por_metodo_sums
  )
  SELECT
    t.total_entradas,
    t.total_salidas,
    t.total_entradas - t.total_salidas AS saldo_dia,
    pm.por_metodo
  FROM totales t
  CROSS JOIN por_metodo_json pm;
$$;

-- ── Permisos ─────────────────────────────────────────────────────
GRANT EXECUTE ON FUNCTION public.get_kpis_dia(uuid, date)             TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_proximas_citas(uuid, int)         TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_ingresos_periodo(uuid, date, date, text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_top_servicios(uuid, date, date, int)     TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_productividad_personal(uuid, date, date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_resumen_caja_dia(uuid, date)      TO authenticated;

COMMENT ON FUNCTION public.get_kpis_dia IS 'KPIs del dashboard: citas del día, ingresos, tasa de ocupación.';
COMMENT ON FUNCTION public.get_proximas_citas IS 'Próximas N horas de citas activas del spa.';
COMMENT ON FUNCTION public.get_ingresos_periodo IS 'Ingresos agrupados por día/semana/mes para gráficas.';
COMMENT ON FUNCTION public.get_top_servicios IS 'Servicios más vendidos en un período.';
COMMENT ON FUNCTION public.get_productividad_personal IS 'Métricas de desempeño por terapeuta.';
COMMENT ON FUNCTION public.get_resumen_caja_dia IS 'Resumen de entradas/salidas de caja del día.';
