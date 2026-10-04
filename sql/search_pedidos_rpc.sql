-- =============================================================================
-- RPC: search_pedidos  (v4 — multi-palabra + unaccent + correccion tipo enum estado)
-- Permite busqueda completa de pedidos incluyendo:
--   - folio del pedido
--   - notas del pedido
--   - nombre del cliente (tabla clientes)
--   - descripcion_personalizada de los items (tabla pedido_items)
--   - productos.nombre de los items (tabla productos)
--
-- CAMBIOS v4:
--   - FIX CRÍTICO: pe.estado::text = p_status (corrige error 42883 de tipo enum)
--   - Búsqueda multi-palabra: Si buscas "vinil con iman", busca cada palabra
--     en el pedido y sus items/cliente, permitiendo encontrar "Vinil con Imán"
--     aunque haya acentos o palabras intermedias.
--   - unaccent(): No distingue mayúsculas ni tildes ("iman" = "Imán")
--   - SET search_path = public, extensions (evita problemas con schemas)
--   - Permisos concedidos a authenticated y anon
--
-- Ejecutar en: Supabase > SQL Editor
-- Es seguro correrlo varias veces (CREATE OR REPLACE).
-- =============================================================================

-- Habilitar extensiones necesarias (idempotente)
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE EXTENSION IF NOT EXISTS unaccent;

CREATE OR REPLACE FUNCTION search_pedidos(
  p_search      text    DEFAULT '',
  p_status      text    DEFAULT 'ALL',
  p_start_date  text    DEFAULT NULL,
  p_end_date    text    DEFAULT NULL,
  p_only_notes  boolean DEFAULT false,
  p_page        int     DEFAULT 1,
  p_page_size   int     DEFAULT 20,
  OUT result    json,
  OUT total     bigint
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, extensions
AS $$
DECLARE
  v_offset int    := (p_page - 1) * p_page_size;
  v_search text   := LOWER(unaccent(TRIM(COALESCE(p_search, ''))));
  v_words  text[] := array_remove(string_to_array(regexp_replace(v_search, '\s+', ' ', 'g'), ' '), '');
BEGIN

  -- ── Count query ─────────────────────────────────────────────────────────────
  SELECT COUNT(*) INTO total
  FROM pedidos pe
  LEFT JOIN clientes cl ON cl.id = pe.cliente_id
  WHERE
    (p_status = 'ALL' OR pe.estado::text = p_status)
    AND (NULLIF(p_start_date, '') IS NULL OR pe.created_at >= (p_start_date || 'T00:00:00')::timestamptz)
    AND (NULLIF(p_end_date, '')   IS NULL OR pe.created_at <= (p_end_date   || 'T23:59:59')::timestamptz)
    AND (NOT p_only_notes OR (pe.notas IS NOT NULL AND pe.notas <> ''))
    AND (
      array_length(v_words, 1) IS NULL
      OR NOT EXISTS (
        SELECT 1
        FROM unnest(v_words) w
        WHERE NOT (
          LOWER(unaccent(COALESCE(pe.folio, ''))) LIKE '%' || w || '%'
          OR LOWER(unaccent(COALESCE(pe.notas, ''))) LIKE '%' || w || '%'
          OR LOWER(unaccent(COALESCE(cl.nombre, ''))) LIKE '%' || w || '%'
          OR EXISTS (
            SELECT 1
            FROM pedido_items pi
            LEFT JOIN productos pr ON pr.id = pi.producto_id
            WHERE pi.pedido_id = pe.id
              AND (
                LOWER(unaccent(COALESCE(pi.descripcion_personalizada, ''))) LIKE '%' || w || '%'
                OR LOWER(unaccent(COALESCE(pr.nombre, ''))) LIKE '%' || w || '%'
              )
          )
        )
      )
    );

  -- ── Data query ──────────────────────────────────────────────────────────────
  SELECT json_agg(row_to_json(t) ORDER BY (t).created_at DESC) INTO result
  FROM (
    SELECT
      pe.id,
      pe.folio,
      pe.estado,
      pe.notas,
      pe.total,
      pe.created_at,
      pe.cliente_id,

      -- Nested: clientes
      (
        SELECT row_to_json(c)
        FROM (SELECT cl2.nombre FROM clientes cl2 WHERE cl2.id = pe.cliente_id LIMIT 1) c
      ) AS clientes,

      -- Nested: pedido_items con productos.nombre
      (
        SELECT COALESCE(json_agg(row_to_json(it) ORDER BY it.id), '[]'::json)
        FROM (
          SELECT
            pi2.id,
            pi2.producto_id,
            pi2.descripcion_personalizada,
            pi2.cantidad,
            pi2.precio_unitario,
            pi2.subtotal,
            (
              SELECT row_to_json(pr)
              FROM (SELECT pr2.nombre FROM productos pr2 WHERE pr2.id = pi2.producto_id LIMIT 1) pr
            ) AS productos
          FROM pedido_items pi2
          WHERE pi2.pedido_id = pe.id
        ) it
      ) AS pedido_items,

      -- Nested: pagos
      (
        SELECT COALESCE(json_agg(row_to_json(pg) ORDER BY pg.creado_en), '[]'::json)
        FROM (
          SELECT pg2.id, pg2.monto, pg2.metodo, pg2.referencia, pg2.creado_en, pg2.es_anticipo
          FROM pagos pg2
          WHERE pg2.pedido_id = pe.id
        ) pg
      ) AS pagos

    FROM pedidos pe
    LEFT JOIN clientes cl ON cl.id = pe.cliente_id
    WHERE
      (p_status = 'ALL' OR pe.estado::text = p_status)
      AND (NULLIF(p_start_date, '') IS NULL OR pe.created_at >= (p_start_date || 'T00:00:00')::timestamptz)
      AND (NULLIF(p_end_date, '')   IS NULL OR pe.created_at <= (p_end_date   || 'T23:59:59')::timestamptz)
      AND (NOT p_only_notes OR (pe.notas IS NOT NULL AND pe.notas <> ''))
      AND (
        array_length(v_words, 1) IS NULL
        OR NOT EXISTS (
          SELECT 1
          FROM unnest(v_words) w
          WHERE NOT (
            LOWER(unaccent(COALESCE(pe.folio, ''))) LIKE '%' || w || '%'
            OR LOWER(unaccent(COALESCE(pe.notas, ''))) LIKE '%' || w || '%'
            OR LOWER(unaccent(COALESCE(cl.nombre, ''))) LIKE '%' || w || '%'
            OR EXISTS (
              SELECT 1
              FROM pedido_items pi
              LEFT JOIN productos pr ON pr.id = pi.producto_id
              WHERE pi.pedido_id = pe.id
                AND (
                  LOWER(unaccent(COALESCE(pi.descripcion_personalizada, ''))) LIKE '%' || w || '%'
                  OR LOWER(unaccent(COALESCE(pr.nombre, ''))) LIKE '%' || w || '%'
                )
            )
          )
        )
      )
    ORDER BY pe.created_at DESC
    LIMIT  p_page_size
    OFFSET v_offset
  ) t;

  -- Devolver array vacio en lugar de null cuando no hay resultados
  IF result IS NULL THEN
    result := '[]'::json;
  END IF;
END;
$$;

-- Permisos
GRANT EXECUTE ON FUNCTION search_pedidos TO authenticated, anon;

-- =============================================================================
-- Indices GIN trigram para acelerar las busquedas LIKE
-- =============================================================================

CREATE INDEX IF NOT EXISTS idx_pedidos_folio_trgm
  ON pedidos USING gin (folio gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_pedidos_notas_trgm
  ON pedidos USING gin (notas gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_clientes_nombre_trgm
  ON clientes USING gin (nombre gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_pedido_items_desc_trgm
  ON pedido_items USING gin (descripcion_personalizada gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_productos_nombre_trgm
  ON productos USING gin (nombre gin_trgm_ops);

CREATE INDEX IF NOT EXISTS idx_pedido_items_pedido_id
  ON pedido_items (pedido_id);
