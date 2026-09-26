-- ============================================================
-- ANÁLISIS DE PLAYERAS VENDIDAS EN EL AÑO ACTUAL (2026)
-- ============================================================
-- Las tallas y colores se extraen de: pedidos.notas
-- El filtro "es playera" usa:
--   - pedido_items.descripcion_personalizada
--   - productos.nombre
-- Se excluyen pedidos CANCELADOS.
-- Zona horaria: America/Mazatlan
-- ============================================================


-- ============================================================
-- 1. DATOS CRUDOS — ver las notas exactas de cada pedido
--    Ejecuta esto PRIMERO para revisar cómo están escritas
--    las tallas y colores en tus notas reales.
-- ============================================================
SELECT
    p.folio,
    p.created_at::date                                       AS fecha,
    p.estado,
    c.nombre                                                 AS cliente,
    SUM(pi.cantidad)                                         AS total_piezas,
    p.notas                                                  AS notas_pedido,
    STRING_AGG(
        COALESCE(pi.descripcion_personalizada, pr.nombre),
        ' | '
        ORDER BY pi.id
    )                                                        AS items
FROM pedidos p
JOIN pedido_items pi ON pi.pedido_id = p.id
LEFT JOIN productos  pr ON pr.id = pi.producto_id
LEFT JOIN clientes   c  ON c.id  = p.cliente_id
WHERE p.estado <> 'CANCELADO'
  AND EXTRACT(YEAR FROM p.created_at AT TIME ZONE 'America/Mazatlan')
      = EXTRACT(YEAR FROM NOW() AT TIME ZONE 'America/Mazatlan')
  AND (
        LOWER(COALESCE(pi.descripcion_personalizada, '')) LIKE '%player%'
     OR LOWER(COALESCE(pr.nombre, ''))                   LIKE '%player%'
  )
GROUP BY p.id, p.folio, p.created_at, p.estado, p.notas, c.nombre
ORDER BY p.created_at DESC;


-- ============================================================
-- 2. TOTAL GENERAL DE PLAYERAS DEL AÑO
-- ============================================================
SELECT
    COUNT(DISTINCT p.id)    AS num_pedidos,
    SUM(pi.cantidad)        AS total_playeras_vendidas,
    SUM(pi.subtotal)        AS ingresos_totales
FROM pedidos p
JOIN pedido_items pi ON pi.pedido_id = p.id
LEFT JOIN productos pr ON pr.id = pi.producto_id
WHERE p.estado <> 'CANCELADO'
  AND EXTRACT(YEAR FROM p.created_at AT TIME ZONE 'America/Mazatlan')
      = EXTRACT(YEAR FROM NOW() AT TIME ZONE 'America/Mazatlan')
  AND (
        LOWER(COALESCE(pi.descripcion_personalizada, '')) LIKE '%player%'
     OR LOWER(COALESCE(pr.nombre, ''))                   LIKE '%player%'
  );


-- ============================================================
-- 3. RANKING POR TALLA  (leída de pedidos.notas)
--    Detecta: XS, S, M, L, XL, XXL, 3XL/XXXL, 4XL
--    Cada pedido cuenta sus piezas totales bajo la talla detectada.
-- ============================================================
WITH pedidos_playeras AS (
    SELECT
        p.id,
        SUM(pi.cantidad)                                           AS piezas,
        LOWER(COALESCE(p.notas, ''))                               AS notas
    FROM pedidos p
    JOIN pedido_items pi ON pi.pedido_id = p.id
    LEFT JOIN productos pr ON pr.id = pi.producto_id
    WHERE p.estado <> 'CANCELADO'
      AND EXTRACT(YEAR FROM p.created_at AT TIME ZONE 'America/Mazatlan')
          = EXTRACT(YEAR FROM NOW() AT TIME ZONE 'America/Mazatlan')
      AND (
            LOWER(COALESCE(pi.descripcion_personalizada, '')) LIKE '%player%'
         OR LOWER(COALESCE(pr.nombre, ''))                   LIKE '%player%'
      )
    GROUP BY p.id, p.notas
),
tallas AS (
    SELECT
        piezas,
        UNNEST(ARRAY[
            CASE WHEN notas ~* '\m4xl\M|\m4 xl\M'                       THEN '4XL' END,
            CASE WHEN notas ~* '\m3xl\M|\mxxxl\M|\m3 xl\M'             THEN '3XL' END,
            CASE WHEN notas ~* '\mxxl\M|\m2xl\M|\m2 xl\M'             THEN 'XXL' END,
            CASE WHEN notas ~* '\mxl\M'
                  AND notas !~* '\m[234]xl\M|\mxx\M|\mxxxl\M'         THEN 'XL'  END,
            CASE WHEN notas ~* '\bxs\b'                                 THEN 'XS'  END,
            CASE WHEN notas ~* '\b(talla\s*)?s\b'
                  AND notas !~* '\bxs\b|\bxl\b'                        THEN 'S'   END,
            CASE WHEN notas ~* '\b(talla\s*)?m\b'
                  AND notas !~* '\bxl\b|\bxxl\b'                       THEN 'M'   END,
            CASE WHEN notas ~* '\b(talla\s*)?l\b'
                  AND notas !~* '\bxl\b|\bxxl\b'                       THEN 'L'   END,
            -- Variantes escritas en español
            CASE WHEN notas ~* '\b(chico|chica|pequeño|pequeña|ch)\b'  THEN 'S'   END,
            CASE WHEN notas ~* '\b(mediano|mediana|med)\b'              THEN 'M'   END,
            CASE WHEN notas ~* '\b(grande|gran|gde)\b'
                  AND notas !~* '\bextra\b'                             THEN 'L'   END,
            CASE WHEN notas ~* '\b(extra\s*grande|extra\s*gran)\b'     THEN 'XL'  END
        ]) AS talla
    FROM pedidos_playeras
)
SELECT
    talla,
    SUM(piezas) AS total_vendidas
FROM tallas
WHERE talla IS NOT NULL
GROUP BY talla
ORDER BY total_vendidas DESC;


-- ============================================================
-- 4. RANKING POR COLOR  (leído de pedidos.notas)
-- ============================================================
WITH pedidos_playeras AS (
    SELECT
        p.id,
        SUM(pi.cantidad)                                           AS piezas,
        LOWER(COALESCE(p.notas, ''))                               AS notas
    FROM pedidos p
    JOIN pedido_items pi ON pi.pedido_id = p.id
    LEFT JOIN productos pr ON pr.id = pi.producto_id
    WHERE p.estado <> 'CANCELADO'
      AND EXTRACT(YEAR FROM p.created_at AT TIME ZONE 'America/Mazatlan')
          = EXTRACT(YEAR FROM NOW() AT TIME ZONE 'America/Mazatlan')
      AND (
            LOWER(COALESCE(pi.descripcion_personalizada, '')) LIKE '%player%'
         OR LOWER(COALESCE(pr.nombre, ''))                   LIKE '%player%'
      )
    GROUP BY p.id, p.notas
),
colores AS (
    SELECT
        piezas,
        UNNEST(ARRAY[
            CASE WHEN notas LIKE '%blanco%'                               THEN 'Blanco'   END,
            CASE WHEN notas LIKE '%negro%'                                THEN 'Negro'    END,
            CASE WHEN notas LIKE '%rojo%'  OR notas LIKE '%roja%'        THEN 'Rojo'     END,
            CASE WHEN notas LIKE '%marino%'                               THEN 'Marino'   END,
            CASE WHEN notas LIKE '%celest%'                               THEN 'Celeste'  END,
            CASE WHEN notas LIKE '%azul%'
                  AND notas NOT LIKE '%marino%'
                  AND notas NOT LIKE '%celest%'                           THEN 'Azul'     END,
            CASE WHEN notas LIKE '%verde%'                                THEN 'Verde'    END,
            CASE WHEN notas LIKE '%amarill%'                              THEN 'Amarillo' END,
            CASE WHEN notas LIKE '%gris%'  OR notas LIKE '%gray%'
                  OR notas LIKE '%grey%'                                  THEN 'Gris'     END,
            CASE WHEN notas LIKE '%naranj%'OR notas LIKE '%orange%'      THEN 'Naranja'  END,
            CASE WHEN notas LIKE '%rosa%'  OR notas LIKE '%pink%'        THEN 'Rosa'     END,
            CASE WHEN notas LIKE '%morado%'OR notas LIKE '%lila%'
                  OR notas LIKE '%violeta%'OR notas LIKE '%purple%'      THEN 'Morado'   END,
            CASE WHEN notas LIKE '%vino%'  OR notas LIKE '%bordo%'
                  OR notas LIKE '%burdeos%'OR notas LIKE '%burgundy%'    THEN 'Vino'     END,
            CASE WHEN notas LIKE '%cafe%'  OR notas LIKE '%café%'
                  OR notas LIKE '%brown%'  OR notas LIKE '%cafetoso%'    THEN 'Cafe'     END,
            CASE WHEN notas LIKE '%beige%' OR notas LIKE '%crema%'       THEN 'Beige'    END,
            CASE WHEN notas LIKE '%turqu%'                                THEN 'Turquesa' END
        ]) AS color
    FROM pedidos_playeras
)
SELECT
    color,
    SUM(piezas) AS total_vendidas
FROM colores
WHERE color IS NOT NULL
GROUP BY color
ORDER BY total_vendidas DESC;


-- ============================================================
-- 5. COMBINACIÓN TALLA + COLOR — top combinaciones del año
-- ============================================================
WITH pedidos_playeras AS (
    SELECT
        p.id,
        SUM(pi.cantidad)                                           AS piezas,
        LOWER(COALESCE(p.notas, ''))                               AS notas
    FROM pedidos p
    JOIN pedido_items pi ON pi.pedido_id = p.id
    LEFT JOIN productos pr ON pr.id = pi.producto_id
    WHERE p.estado <> 'CANCELADO'
      AND EXTRACT(YEAR FROM p.created_at AT TIME ZONE 'America/Mazatlan')
          = EXTRACT(YEAR FROM NOW() AT TIME ZONE 'America/Mazatlan')
      AND (
            LOWER(COALESCE(pi.descripcion_personalizada, '')) LIKE '%player%'
         OR LOWER(COALESCE(pr.nombre, ''))                   LIKE '%player%'
      )
    GROUP BY p.id, p.notas
),
clasificadas AS (
    SELECT
        piezas,
        notas,
        CASE
            WHEN notas ~* '\m4xl\M|\m4 xl\M'                              THEN '4XL'
            WHEN notas ~* '\m3xl\M|\mxxxl\M|\m3 xl\M'                   THEN '3XL'
            WHEN notas ~* '\mxxl\M|\m2xl\M|\m2 xl\M'                   THEN 'XXL'
            WHEN notas ~* '\mxl\M'
             AND notas !~* '\m[234]xl\M|\mxx\M|\mxxxl\M'               THEN 'XL'
            WHEN notas ~* '\bxs\b'                                        THEN 'XS'
            WHEN notas ~* '\b(talla\s*)?s\b'
             AND notas !~* '\bxs\b|\bxl\b'                               THEN 'S'
            WHEN notas ~* '\b(talla\s*)?m\b'
             AND notas !~* '\bxl\b|\bxxl\b'                              THEN 'M'
            WHEN notas ~* '\b(talla\s*)?l\b'
             AND notas !~* '\bxl\b|\bxxl\b'                              THEN 'L'
            WHEN notas ~* '\b(chico|chica|ch)\b'                         THEN 'S'
            WHEN notas ~* '\b(mediano|mediana|med)\b'                    THEN 'M'
            WHEN notas ~* '\b(extra\s*grande|extra\s*gran)\b'           THEN 'XL'
            WHEN notas ~* '\b(grande|gran|gde)\b'                       THEN 'L'
            ELSE '(sin talla)'
        END AS talla,
        CASE
            WHEN notas LIKE '%blanco%'                                    THEN 'Blanco'
            WHEN notas LIKE '%negro%'                                     THEN 'Negro'
            WHEN notas LIKE '%marino%'                                    THEN 'Marino'
            WHEN notas LIKE '%celest%'                                    THEN 'Celeste'
            WHEN notas LIKE '%azul%'                                      THEN 'Azul'
            WHEN notas LIKE '%rojo%'  OR notas LIKE '%roja%'             THEN 'Rojo'
            WHEN notas LIKE '%verde%'                                     THEN 'Verde'
            WHEN notas LIKE '%amarill%'                                   THEN 'Amarillo'
            WHEN notas LIKE '%gris%'  OR notas LIKE '%gray%'             THEN 'Gris'
            WHEN notas LIKE '%naranj%'                                    THEN 'Naranja'
            WHEN notas LIKE '%rosa%'  OR notas LIKE '%pink%'             THEN 'Rosa'
            WHEN notas LIKE '%morado%'OR notas LIKE '%lila%'             THEN 'Morado'
            WHEN notas LIKE '%vino%'  OR notas LIKE '%bordo%'            THEN 'Vino'
            WHEN notas LIKE '%cafe%'  OR notas LIKE '%café%'
              OR notas LIKE '%brown%'                                     THEN 'Cafe'
            WHEN notas LIKE '%beige%' OR notas LIKE '%crema%'            THEN 'Beige'
            WHEN notas LIKE '%turqu%'                                     THEN 'Turquesa'
            ELSE '(sin color)'
        END AS color
    FROM pedidos_playeras
)
SELECT
    talla,
    color,
    SUM(piezas)  AS total_vendidas,
    COUNT(*)     AS num_pedidos
FROM clasificadas
GROUP BY talla, color
ORDER BY total_vendidas DESC
LIMIT 30;
