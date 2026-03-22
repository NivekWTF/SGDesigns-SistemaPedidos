/*
Caja y movimientos de caja.
Ejecuta este script en Supabase SQL editor.
*/

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_type WHERE typname = 'tipo_movimiento_caja'
  ) THEN
    CREATE TYPE tipo_movimiento_caja AS ENUM (
      'VENTA',
      'ANTICIPO',
      'ABONO',
      'GASTO_NEGOCIO',
      'GASTO_PERSONAL',
      'RETIRO_DUENO',
      'COMPRA_MATERIAL',
      'AJUSTE_ENTRADA',
      'AJUSTE_SALIDA',
      'PAGO_SERVICIO',
      'PRESTAMO_RECIBIDO'
    );
  END IF;
END
$$;

CREATE TABLE IF NOT EXISTS cajas (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre text NOT NULL DEFAULT 'Caja principal',
  saldo_inicial numeric(10,2) NOT NULL DEFAULT 0,
  abierta boolean NOT NULL DEFAULT true,
  fecha_apertura timestamptz NOT NULL DEFAULT now(),
  fecha_cierre timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS movimientos_caja (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  caja_id uuid NOT NULL REFERENCES cajas(id) ON DELETE CASCADE,
  pedido_id uuid REFERENCES pedidos(id) ON DELETE SET NULL,
  tipo tipo_movimiento_caja NOT NULL,
  concepto text NOT NULL,
  categoria text,
  metodo_pago text NOT NULL DEFAULT 'EFECTIVO',
  es_entrada boolean NOT NULL,
  monto numeric(10,2) NOT NULL CHECK (monto > 0),
  notas text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_movimientos_caja_created_at ON movimientos_caja (created_at);
CREATE INDEX IF NOT EXISTS idx_movimientos_caja_caja_id ON movimientos_caja (caja_id);
CREATE INDEX IF NOT EXISTS idx_movimientos_caja_tipo ON movimientos_caja (tipo);
CREATE INDEX IF NOT EXISTS idx_movimientos_caja_metodo ON movimientos_caja (metodo_pago);

CREATE OR REPLACE FUNCTION public.get_caja_principal_id()
RETURNS uuid
LANGUAGE plpgsql
AS $$
DECLARE
  caja_uuid uuid;
BEGIN
  SELECT id INTO caja_uuid
  FROM cajas
  WHERE abierta = true
  ORDER BY fecha_apertura DESC
  LIMIT 1;

  IF caja_uuid IS NULL THEN
    INSERT INTO cajas (nombre, saldo_inicial, abierta)
    VALUES ('Caja principal', 0, true)
    RETURNING id INTO caja_uuid;
  END IF;

  RETURN caja_uuid;
END;
$$;

CREATE OR REPLACE FUNCTION public.normalize_metodo_pago(input text)
RETURNS text
LANGUAGE sql
AS $$
  SELECT CASE
    WHEN input IS NULL OR btrim(input) = '' THEN 'EFECTIVO'
    ELSE upper(input)
  END;
$$;

CREATE OR REPLACE FUNCTION public.handle_pago_movimiento_caja()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  caja_uuid uuid;
BEGIN
  caja_uuid := public.get_caja_principal_id();

  INSERT INTO movimientos_caja (
    caja_id,
    pedido_id,
    tipo,
    concepto,
    categoria,
    metodo_pago,
    es_entrada,
    monto,
    notas,
    created_at
  ) VALUES (
    caja_uuid,
    NEW.pedido_id,
    CASE
      WHEN NEW.es_anticipo THEN 'ANTICIPO'::tipo_movimiento_caja
      ELSE 'ABONO'::tipo_movimiento_caja
    END,
    CASE WHEN NEW.es_anticipo THEN 'Anticipo de pedido' ELSE 'Pago de pedido' END,
    'PEDIDOS',
    public.normalize_metodo_pago(NEW.metodo),
    true,
    NEW.monto,
    NEW.referencia,
    COALESCE(NEW.creado_en, now())
  );

  RETURN NEW;
END;
$$;

DO $$
BEGIN
  IF to_regclass('public.pagos') IS NOT NULL THEN
    EXECUTE 'DROP TRIGGER IF EXISTS pagos_to_movimientos_caja ON public.pagos';
    EXECUTE 'CREATE TRIGGER pagos_to_movimientos_caja AFTER INSERT ON public.pagos FOR EACH ROW EXECUTE FUNCTION public.handle_pago_movimiento_caja()';
  END IF;
END
$$;
