-- ══════════════════════════════════════════════════════════════════
-- 08_seed_data.sql
-- SpaFlow — Datos de prueba para desarrollo
-- ⚠️  SOLO ejecutar en ambiente de desarrollo/staging, NUNCA en producción
-- ══════════════════════════════════════════════════════════════════

-- ── 1. Crear dos spas de prueba ───────────────────────────────────
INSERT INTO public.spas (id, nombre, slug, color_primario, zona_horaria, plan)
VALUES
  ('a1000000-0000-0000-0000-000000000001', 'Spa Lotus',    'lotus-spa',    '#8b5cf6', 'America/Mexico_City',       'pro'),
  ('a1000000-0000-0000-0000-000000000002', 'Zen Wellness', 'zen-wellness', '#059669', 'America/Monterrey',         'basic')
ON CONFLICT (slug) DO NOTHING;

-- ── 2. Servicios para Spa Lotus ───────────────────────────────────
INSERT INTO public.servicios (spa_id, nombre, categoria, duracion_min, precio, descripcion)
VALUES
  ('a1000000-0000-0000-0000-000000000001', 'Masaje Sueco',             'MASAJE',   60, 850.00,  'Relajación muscular profunda con aceites esenciales'),
  ('a1000000-0000-0000-0000-000000000001', 'Masaje de Piedras Calientes','MASAJE',  90, 1200.00, 'Técnica de termoterapia con basalto volcánico'),
  ('a1000000-0000-0000-0000-000000000001', 'Facial Anti-edad',          'FACIAL',   60, 950.00,  'Limpieza profunda + hidratación + masaje facial'),
  ('a1000000-0000-0000-0000-000000000001', 'Facial Hidratante',         'FACIAL',   45, 650.00,  'Ideal para piel seca y sensible'),
  ('a1000000-0000-0000-0000-000000000001', 'Exfoliación Corporal',      'CORPORAL', 45, 750.00,  'Con sales marinas y aceite de argán'),
  ('a1000000-0000-0000-0000-000000000001', 'Envoltura de Chocolate',    'CORPORAL', 75, 1100.00, 'Antioxidante, reafirmante y nutritiva'),
  ('a1000000-0000-0000-0000-000000000001', 'Manicura Spa',              'UÑAS',     45, 350.00,  'Con hidratación de manos y curación de cutículas'),
  ('a1000000-0000-0000-0000-000000000001', 'Pedicura Spa',              'UÑAS',     60, 450.00,  'Con baño de parafina y masaje de pies'),
  ('a1000000-0000-0000-0000-000000000001', 'Reflexología de Pies',      'MASAJE',   45, 600.00,  'Estimulación de puntos reflejos plantares'),
  ('a1000000-0000-0000-0000-000000000001', 'Aromaterapia',              'OTRO',     60, 700.00,  'Masaje con blend de aceites esenciales personalizados')
ON CONFLICT DO NOTHING;

-- ── 3. Paquete para Spa Lotus ──────────────────────────────────────
INSERT INTO public.paquetes (id, spa_id, nombre, precio, descripcion, vigencia_dias)
VALUES
  ('b1000000-0000-0000-0000-000000000001',
   'a1000000-0000-0000-0000-000000000001',
   'Escapada de Bienestar',
   2200.00,
   'Masaje sueco 60 min + Facial hidratante + Manicura spa',
   NULL)
ON CONFLICT DO NOTHING;

-- ── 4. Personal para Spa Lotus ────────────────────────────────────
INSERT INTO public.personal (id, spa_id, nombre, especialidades, color_agenda)
VALUES
  ('c1000000-0000-0000-0000-000000000001', 'a1000000-0000-0000-0000-000000000001',
   'Sofía Ramírez', ARRAY['MASAJE', 'CORPORAL'],  '#8b5cf6'),
  ('c1000000-0000-0000-0000-000000000002', 'a1000000-0000-0000-0000-000000000001',
   'Ana González',  ARRAY['FACIAL', 'OTRO'],       '#ec4899'),
  ('c1000000-0000-0000-0000-000000000003', 'a1000000-0000-0000-0000-000000000001',
   'Luisa Martínez',ARRAY['UÑAS', 'MASAJE'],       '#f59e0b')
ON CONFLICT DO NOTHING;

-- ── 5. Horarios del personal (Lun–Sáb 9am–7pm, Dom libre) ────────
DO $$
DECLARE
  v_personal_id uuid;
  v_dia int;
BEGIN
  FOR v_personal_id IN
    SELECT unnest(ARRAY[
      'c1000000-0000-0000-0000-000000000001'::uuid,
      'c1000000-0000-0000-0000-000000000002'::uuid,
      'c1000000-0000-0000-0000-000000000003'::uuid
    ])
  LOOP
    FOR v_dia IN 1..6 LOOP  -- 1=Lunes a 6=Sábado
      INSERT INTO public.horarios_personal
        (personal_id, dia_semana, hora_inicio, hora_fin)
      VALUES
        (v_personal_id, v_dia, '09:00', '19:00')
      ON CONFLICT (personal_id, dia_semana) DO NOTHING;
    END LOOP;
  END LOOP;
END $$;

-- ── 6. Clientes de ejemplo para Spa Lotus ────────────────────────
INSERT INTO public.clientes (spa_id, nombre, telefono, correo, genero, notas_preferencias)
VALUES
  ('a1000000-0000-0000-0000-000000000001', 'María García',    '5551234567', 'maria@example.com',    'F', 'Prefiere masaje con poca presión, aromas florales'),
  ('a1000000-0000-0000-0000-000000000001', 'Laura Pérez',     '5559876543', 'laura@example.com',    'F', 'Alérgica a la lavanda, prefiere manzanilla'),
  ('a1000000-0000-0000-0000-000000000001', 'Carlos Torres',   '5554561234', 'carlos@example.com',   'M', 'Prefiere terapeuta femenina'),
  ('a1000000-0000-0000-0000-000000000001', 'Fernanda López',  '5553217890', 'fernanda@example.com', 'F', NULL),
  ('a1000000-0000-0000-0000-000000000001', 'Isabel Hernández','5556540987', 'isabel@example.com',   'F', 'Hipersensibilidad en zona lumbar')
ON CONFLICT DO NOTHING;

-- ── 7. Caja principal para Spa Lotus ─────────────────────────────
INSERT INTO public.cajas (spa_id, nombre, saldo_inicial, abierta)
VALUES ('a1000000-0000-0000-0000-000000000001', 'Caja principal', 500.00, true)
ON CONFLICT DO NOTHING;

-- ── Verificación final ────────────────────────────────────────────
DO $$
DECLARE
  v_spas     int;
  v_servicios int;
  v_personal  int;
  v_clientes  int;
BEGIN
  SELECT COUNT(*) INTO v_spas     FROM public.spas;
  SELECT COUNT(*) INTO v_servicios FROM public.servicios;
  SELECT COUNT(*) INTO v_personal FROM public.personal;
  SELECT COUNT(*) INTO v_clientes FROM public.clientes;

  RAISE NOTICE '✅ Seed completado:';
  RAISE NOTICE '   Spas:      %', v_spas;
  RAISE NOTICE '   Servicios: %', v_servicios;
  RAISE NOTICE '   Personal:  %', v_personal;
  RAISE NOTICE '   Clientes:  %', v_clientes;
END $$;
