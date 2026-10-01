-- =============================================================================
-- Índices para optimizar la paginación server-side en la tabla `pedidos`
-- Ejecutar en: Supabase > SQL Editor
-- Es seguro correrlo varias veces (IF NOT EXISTS).
-- =============================================================================

-- 1. Extensión pg_trgm (necesaria para índices GIN en ILIKE con wildcard inicial)
--    Supabase la incluye por defecto; este comando es idempotente.
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- 2. Índice en created_at (ORDER BY y filtros de rango de fecha)
--    Descendente porque la query siempre ordena ORDER BY created_at DESC.
CREATE INDEX IF NOT EXISTS idx_pedidos_created_at_desc
  ON pedidos (created_at DESC);

-- 3. Índice en estado (filtro de status)
CREATE INDEX IF NOT EXISTS idx_pedidos_estado
  ON pedidos (estado);

-- 4. Índice GIN trigram en folio (búsqueda ILIKE '%texto%')
CREATE INDEX IF NOT EXISTS idx_pedidos_folio_trgm
  ON pedidos USING gin (folio gin_trgm_ops);

-- 5. Índice GIN trigram en notas (búsqueda ILIKE '%texto%')
CREATE INDEX IF NOT EXISTS idx_pedidos_notas_trgm
  ON pedidos USING gin (notas gin_trgm_ops);

-- 6. Índice compuesto (estado, created_at) — útil cuando se filtra por estado
--    Y se ordena por fecha al mismo tiempo (caso más frecuente).
CREATE INDEX IF NOT EXISTS idx_pedidos_estado_created_at
  ON pedidos (estado, created_at DESC);

-- =============================================================================
-- Verificar índices creados:
-- SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'pedidos';
-- =============================================================================
