-- =============================================================================
-- Supabase Storage Setup: Archivos adjuntos a pedidos
-- =============================================================================
-- PASO 1: Ejecutar este SQL en Supabase → SQL Editor
-- PASO 2: Crear bucket "pedido-attachments" en Supabase → Storage (público)
-- =============================================================================

-- Tabla para registrar los archivos adjuntos de cada pedido
CREATE TABLE IF NOT EXISTS pedido_archivos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  pedido_id UUID NOT NULL REFERENCES pedidos(id) ON DELETE CASCADE,
  url TEXT NOT NULL,
  nombre_archivo TEXT NOT NULL,
  tipo TEXT,                    -- mime type: image/png, application/pdf, etc.
  tamanio_bytes BIGINT,         -- archivo size in bytes
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Índice para búsquedas rápidas por pedido
CREATE INDEX IF NOT EXISTS idx_pedido_archivos_pedido_id ON pedido_archivos(pedido_id);

-- RLS: permitir a usuarios autenticados CRUD sobre sus archivos
ALTER TABLE pedido_archivos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can read pedido_archivos"
  ON pedido_archivos FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Authenticated users can insert pedido_archivos"
  ON pedido_archivos FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Authenticated users can delete pedido_archivos"
  ON pedido_archivos FOR DELETE
  TO authenticated
  USING (true);

-- =============================================================================
-- Storage RLS Policies (en la tabla storage.objects)
-- Estas policies controlan el acceso al bucket "pedido-attachments".
-- NOTA: Primero crea el bucket en Supabase Dashboard → Storage como PÚBLICO.
-- =============================================================================

-- Permitir a usuarios autenticados subir archivos
CREATE POLICY "Allow authenticated uploads to pedido-attachments"
  ON storage.objects FOR INSERT
  TO authenticated
  WITH CHECK (bucket_id = 'pedido-attachments');

-- Permitir lectura pública (bucket público)
CREATE POLICY "Allow public read of pedido-attachments"
  ON storage.objects FOR SELECT
  TO public
  USING (bucket_id = 'pedido-attachments');

-- Permitir a usuarios autenticados actualizar sus archivos
CREATE POLICY "Allow authenticated updates to pedido-attachments"
  ON storage.objects FOR UPDATE
  TO authenticated
  USING (bucket_id = 'pedido-attachments');

-- Permitir a usuarios autenticados eliminar archivos
CREATE POLICY "Allow authenticated deletes from pedido-attachments"
  ON storage.objects FOR DELETE
  TO authenticated
  USING (bucket_id = 'pedido-attachments');
