-- ============================================================
-- Script para limpiar gastos duplicados generados por pedidos
-- ============================================================
-- Estos gastos se creaban erróneamente al hacer un pedido,
-- cuando el gasto real ya se había registrado al comprar stock.
--
-- PASO 1: Revisar cuántos registros se van a eliminar (solo lectura)
SELECT referencia, COUNT(*) AS total, SUM(monto) AS monto_total
FROM gastos
WHERE referencia LIKE 'pedido:%'
   OR referencia LIKE 'pedido_material:%'
GROUP BY referencia
ORDER BY referencia;

-- PASO 2: Si los datos se ven correctos, ejecutar el DELETE
-- (descomenta las líneas de abajo cuando estés listo)
--
DELETE FROM gastos
WHERE referencia LIKE 'pedido:%'
OR referencia LIKE 'pedido_material:%';
