-- ============================================================
-- 🎬 DEMO SEED — Datos ficticios para demostración
-- ============================================================
-- Ejecutar DESPUÉS de onboarding_complete.sql
-- Crea datos realistas de una imprenta ficticia para demostrar
-- todas las funcionalidades del sistema a clientes potenciales.
--
-- Imprenta ficticia: "Imprenta López & Hijos"
-- Ciudad: Culiacán, Sinaloa
-- ============================================================

-- =====================
-- 1. BUSINESS CONFIG (branding demo)
-- =====================
UPDATE public.business_config SET
  business_name     = 'Imprenta López & Hijos',
  business_rfc      = 'LOHJ8503152K4',
  business_email    = 'contacto@imprentalopez.com',
  business_address  = 'Blvd. Emiliano Zapata #456, Col. Las Quintas, Culiacán, Sinaloa',
  business_phone    = '(667) 713 4567',
  business_socials  = 'FB: Imprenta López • IG: @imprenta.lopez',
  business_series   = 'IL',
  tax_rate          = 0.16,
  color_primary     = '#8b5cf6',
  color_primary_dark= '#7c3aed',
  color_accent      = '#a78bfa'
WHERE id = (SELECT id FROM public.business_config LIMIT 1);

-- =====================
-- 2. CLIENTES (15 clientes ficticios)
-- =====================
INSERT INTO public.clientes (id, nombre, telefono, email, direccion, notas, created_at) VALUES
  ('d0000001-0000-0000-0000-000000000001', 'Tacos El Güero',           '(667) 234-5678', 'contacto@tacoselguero.com',   'Av. Álvaro Obregón #123, Centro, Culiacán',          'Cliente frecuente. Pide menús y volantes cada mes.',  now() - interval '4 months'),
  ('d0000001-0000-0000-0000-000000000002', 'Papelería La Escolar',     '(667) 345-6789', 'papeleria@gmail.com',          'Calle Ángel Flores #456, Col. Centro',               'Compra tarjetas de presentación para reventa.',       now() - interval '3 months'),
  ('d0000001-0000-0000-0000-000000000003', 'Restaurante Casa Grande',  '(667) 456-7890', 'reservas@casagrande.mx',       'Blvd. Niños Héroes #789, Col. Guadalupe',            'Menús laminados cada temporada.',                     now() - interval '3 months'),
  ('d0000001-0000-0000-0000-000000000004', 'Dra. María Fernández',     '(667) 567-8901', 'dra.fernandez@outlook.com',    'Hospital Ángeles, Consultorio 205',                  'Recetas médicas y tarjetas.',                         now() - interval '2 months'),
  ('d0000001-0000-0000-0000-000000000005', 'Ferretería Don Pepe',      '(667) 678-9012', NULL,                           'Mercado Rafael Buelna, Local 34',                    '',                                                    now() - interval '2 months'),
  ('d0000001-0000-0000-0000-000000000006', 'Boutique Eleganza',        '(667) 789-0123', 'eleganza@hotmail.com',          'Plaza Galerías, Local A-12',                         'Etiquetas para ropa y bolsas impresas.',              now() - interval '6 weeks'),
  ('d0000001-0000-0000-0000-000000000007', 'Arq. Roberto Sánchez',     '(667) 890-1234', 'arq.sanchez@gmail.com',         'Col. Las Quintas, Culiacán',                         'Planos y renders de proyectos.',                      now() - interval '5 weeks'),
  ('d0000001-0000-0000-0000-000000000008', 'Taller Mecánico Ramírez',  '(667) 901-2345', NULL,                           'Av. Insurgentes #1020, Col. 6 de Enero',             'Facturas y notas de servicio.',                       now() - interval '4 weeks'),
  ('d0000001-0000-0000-0000-000000000009', 'Escuela Primaria Juárez',  '(667) 012-3456', 'direccion@primariajuarez.edu',  'Calle Benito Juárez #200, Col. Centro',              'Diplomas y reconocimientos fin de curso.',             now() - interval '3 weeks'),
  ('d0000001-0000-0000-0000-000000000010', 'Café La Molienda',         '(667) 123-4567', 'lamolienda@gmail.com',          'Av. Aquiles Serdán #567, Col. Centro',               'Menús, stickers y vasos personalizados.',             now() - interval '3 weeks'),
  ('d0000001-0000-0000-0000-000000000011', 'Gimnasio PowerFit',        '(667) 234-5679', 'info@powerfit.mx',              'Blvd. Zapata #890, Plaza Fitness',                   'Playeras, lonas y volantes promocionales.',           now() - interval '2 weeks'),
  ('d0000001-0000-0000-0000-000000000012', 'Lic. Carlos Mendoza',      '(667) 345-6780', 'cmendoza.abogado@gmail.com',    'Torre Jurídica, Piso 3, Oficina 301',                'Papelería legal membretada.',                         now() - interval '10 days'),
  ('d0000001-0000-0000-0000-000000000013', 'Carnicería San Juan',      '(667) 456-7891', NULL,                           'Mercado Garmendia, Local 15',                        'Volantes de ofertas semanales.',                      now() - interval '8 days'),
  ('d0000001-0000-0000-0000-000000000014', 'Inmobiliaria Pacífico',    '(667) 567-8902', 'ventas@inmopacifico.mx',        'Col. Chapultepec, Culiacán',                         'Lonas de "Se Vende" y folletos de propiedades.',      now() - interval '5 days'),
  ('d0000001-0000-0000-0000-000000000015', 'Eventos Luna Azul',        '(667) 678-9013', 'contacto@lunaazul.mx',          'Col. Las Quintas, Culiacán',                         'Invitaciones, recuerdos y material para fiestas.',    now() - interval '2 days');

-- =====================
-- 3. PRODUCTOS (20 productos típicos de imprenta)
-- =====================
INSERT INTO public.productos (id, nombre, descripcion, unidad, precio_base, costo_material, stock, activo, created_at) VALUES
  ('e0000001-0000-0000-0000-000000000001', 'Volante media carta',          'Impresión a color en couché 150g',               'pieza',    1.50,   0.40,  2000,  true,  now() - interval '4 months'),
  ('e0000001-0000-0000-0000-000000000002', 'Volante carta completa',       'Impresión a color ambos lados, couché 150g',     'pieza',    2.50,   0.80,  1500,  true,  now() - interval '4 months'),
  ('e0000001-0000-0000-0000-000000000003', 'Tarjeta de presentación',      'Millar, couché 300g, laminado mate',             'millar',  350.00,  80.00,   45,  true,  now() - interval '4 months'),
  ('e0000001-0000-0000-0000-000000000004', 'Lona front 13oz',              'Impresión gran formato, incluye ojillos',        'metro²',   85.00,  25.00,  120,  true,  now() - interval '3 months'),
  ('e0000001-0000-0000-0000-000000000005', 'Lona back 13oz',               'Impresión retroiluminada para bastidores',       'metro²',  110.00,  35.00,   80,  true,  now() - interval '3 months'),
  ('e0000001-0000-0000-0000-000000000006', 'Vinil adhesivo',               'Para rotulación, corte incluido',                'metro²',  120.00,  30.00,  200,  true,  now() - interval '3 months'),
  ('e0000001-0000-0000-0000-000000000007', 'Sticker troquelado',           'Vinil adhesivo con corte a forma',               'pieza',     5.00,   1.50,  3000, true,  now() - interval '3 months'),
  ('e0000001-0000-0000-0000-000000000008', 'Menú restaurante laminado',    'Tabloide doblado, couché 300g, laminado',        'pieza',    18.00,   5.00,   300,  true,  now() - interval '2 months'),
  ('e0000001-0000-0000-0000-000000000009', 'Folleto tríptico',             'Carta, couché 150g, doblado en 3',               'pieza',     4.50,   1.20,  1000, true,  now() - interval '2 months'),
  ('e0000001-0000-0000-0000-000000000010', 'Invitación evento',            'Media carta, cartulina opalina, acabado luxury',  'pieza',    12.00,   3.50,   500,  true,  now() - interval '2 months'),
  ('e0000001-0000-0000-0000-000000000011', 'Receta médica membretada',     'Media carta, papel bond 75g, block 100 hojas',   'block',    45.00,  12.00,    60,  true,  now() - interval '6 weeks'),
  ('e0000001-0000-0000-0000-000000000012', 'Nota de venta foliada',        'Media carta, autocopiable 2 tantos, block 50',   'block',    65.00,  18.00,    40,  true,  now() - interval '6 weeks'),
  ('e0000001-0000-0000-0000-000000000013', 'Diploma / Reconocimiento',     'Carta, opalina gruesa, diseño personalizado',    'pieza',    15.00,   4.00,   200,  true,  now() - interval '5 weeks'),
  ('e0000001-0000-0000-0000-000000000014', 'Etiqueta para producto',       'Vinil adhesivo con información del producto',    'pieza',     3.00,   0.80,  5000, true,  now() - interval '5 weeks'),
  ('e0000001-0000-0000-0000-000000000015', 'Banner roll-up',               '80x200cm, incluye estructura y bolsa',           'pieza',   650.00, 180.00,    10,  true,  now() - interval '4 weeks'),
  ('e0000001-0000-0000-0000-000000000016', 'Playera sublimada',            'Poliéster, sublimación completa frente',         'pieza',    95.00,  35.00,    50,  true,  now() - interval '3 weeks'),
  ('e0000001-0000-0000-0000-000000000017', 'Taza personalizada',           'Cerámica 11oz, sublimación',                     'pieza',    75.00,  25.00,    80,  true,  now() - interval '3 weeks'),
  ('e0000001-0000-0000-0000-000000000018', 'Poster tabloide',              'Impresión a color, couché 150g',                 'pieza',     8.00,   2.50,   400,  true,  now() - interval '2 weeks'),
  ('e0000001-0000-0000-0000-000000000019', 'Carpeta corporativa',          'Carta, couché 300g, con bolsillo interior',      'pieza',    35.00,  10.00,   100,  true,  now() - interval '2 weeks'),
  ('e0000001-0000-0000-0000-000000000020', 'Sello de goma personalizado',  'Base madera, tinta incluida',                    'pieza',   180.00,  45.00,    25,  true,  now() - interval '1 week');

-- =====================
-- 4. PEDIDOS (25 pedidos con diferentes estados y fechas)
-- =====================

-- == ENTREGADOS (hace semanas — llenan las gráficas históricas) ==
INSERT INTO public.pedidos (id, folio, cliente_id, estado, total, notas, fecha_entrega, created_at, updated_at) VALUES
  ('f0000001-0000-0000-0000-000000000001', 'IL-001', 'd0000001-0000-0000-0000-000000000001', 'ENTREGADO',  750.00, 'Volantes para promoción de verano',         (now() - interval '45 days')::date, now() - interval '50 days',  now() - interval '45 days'),
  ('f0000001-0000-0000-0000-000000000002', 'IL-002', 'd0000001-0000-0000-0000-000000000003', 'ENTREGADO', 1260.00, '70 menús laminados nuevos',                 (now() - interval '40 days')::date, now() - interval '45 days',  now() - interval '40 days'),
  ('f0000001-0000-0000-0000-000000000003', 'IL-003', 'd0000001-0000-0000-0000-000000000002', 'ENTREGADO', 1750.00, '5 millares de tarjetas de presentación',    (now() - interval '38 days')::date, now() - interval '42 days',  now() - interval '38 days'),
  ('f0000001-0000-0000-0000-000000000004', 'IL-004', 'd0000001-0000-0000-0000-000000000004', 'ENTREGADO',  360.00, '8 blocks de recetas membretadas',            (now() - interval '35 days')::date, now() - interval '38 days',  now() - interval '35 days'),
  ('f0000001-0000-0000-0000-000000000005', 'IL-005', 'd0000001-0000-0000-0000-000000000005', 'ENTREGADO',  520.00, '8 blocks de notas de servicio',              (now() - interval '32 days')::date, now() - interval '35 days',  now() - interval '32 days'),
  ('f0000001-0000-0000-0000-000000000006', 'IL-006', 'd0000001-0000-0000-0000-000000000006', 'ENTREGADO', 1500.00, '500 etiquetas troqueladas para ropa',        (now() - interval '28 days')::date, now() - interval '32 days',  now() - interval '28 days'),
  ('f0000001-0000-0000-0000-000000000007', 'IL-007', 'd0000001-0000-0000-0000-000000000007', 'ENTREGADO', 2550.00, 'Lona 6x3m para obra + 100 tarjetas',        (now() - interval '25 days')::date, now() - interval '28 days',  now() - interval '25 days'),
  ('f0000001-0000-0000-0000-000000000008', 'IL-008', 'd0000001-0000-0000-0000-000000000010', 'ENTREGADO', 1850.00, 'Menús + stickers para vasos + volantes',     (now() - interval '21 days')::date, now() - interval '25 days',  now() - interval '21 days'),
  ('f0000001-0000-0000-0000-000000000009', 'IL-009', 'd0000001-0000-0000-0000-000000000008', 'ENTREGADO',  390.00, '6 blocks de facturas autocopiables',         (now() - interval '18 days')::date, now() - interval '21 days',  now() - interval '18 days'),
  ('f0000001-0000-0000-0000-000000000010', 'IL-010', 'd0000001-0000-0000-0000-000000000001', 'ENTREGADO', 1125.00, '750 volantes oferta de septiembre',          (now() - interval '14 days')::date, now() - interval '18 days',  now() - interval '14 days'),
  ('f0000001-0000-0000-0000-000000000011', 'IL-011', 'd0000001-0000-0000-0000-000000000011', 'ENTREGADO', 3800.00, '40 playeras sublimadas + lona 4x2m',        (now() - interval '10 days')::date, now() - interval '14 days',  now() - interval '10 days'),
  ('f0000001-0000-0000-0000-000000000012', 'IL-012', 'd0000001-0000-0000-0000-000000000009', 'ENTREGADO', 1500.00, '100 diplomas fin de curso + 200 programas',  (now() - interval '8 days')::date,  now() - interval '12 days',  now() - interval '8 days'),

-- == TERMINADOS (listos para recoger) ==
  ('f0000001-0000-0000-0000-000000000013', 'IL-013', 'd0000001-0000-0000-0000-000000000012', 'TERMINADO',  980.00, 'Papelería legal completa: hojas, sobres, tarjetas', (now() + interval '1 day')::date,  now() - interval '5 days',  now() - interval '1 day'),
  ('f0000001-0000-0000-0000-000000000014', 'IL-014', 'd0000001-0000-0000-0000-000000000013', 'TERMINADO',  600.00, '400 volantes de ofertas semanales',                  (now())::date,                     now() - interval '3 days',  now() - interval '6 hours'),
  ('f0000001-0000-0000-0000-000000000015', 'IL-015', 'd0000001-0000-0000-0000-000000000014', 'TERMINADO', 2380.00, '4 lonas "Se Vende" + 200 folletos propiedades',      (now() + interval '1 day')::date,  now() - interval '4 days',  now() - interval '12 hours'),

-- == EN PRODUCCIÓN ==
  ('f0000001-0000-0000-0000-000000000016', 'IL-016', 'd0000001-0000-0000-0000-000000000015', 'EN_PRODUCCION', 3600.00, '200 invitaciones boda + 100 recuerdos + menús',  (now() + interval '3 days')::date,  now() - interval '2 days',  now() - interval '1 day'),
  ('f0000001-0000-0000-0000-000000000017', 'IL-017', 'd0000001-0000-0000-0000-000000000003', 'EN_PRODUCCION', 1440.00, '80 menús temporada otoño laminados',             (now() + interval '2 days')::date,  now() - interval '2 days',  now() - interval '8 hours'),
  ('f0000001-0000-0000-0000-000000000018', 'IL-018', 'd0000001-0000-0000-0000-000000000011', 'EN_PRODUCCION', 1950.00, '2 roll-ups + 500 volantes inauguración nueva sucursal', (now() + interval '4 days')::date, now() - interval '1 day', now() - interval '4 hours'),

-- == PENDIENTES (recién entrados) ==
  ('f0000001-0000-0000-0000-000000000019', 'IL-019', 'd0000001-0000-0000-0000-000000000010', 'PENDIENTE', 2250.00, 'Stickers nuevos + actualización de menús diciembre',     (now() + interval '5 days')::date,  now() - interval '6 hours', now() - interval '6 hours'),
  ('f0000001-0000-0000-0000-000000000020', 'IL-020', 'd0000001-0000-0000-0000-000000000002', 'PENDIENTE', 1050.00, '3 millares de tarjetas, modelos variados',                (now() + interval '4 days')::date,  now() - interval '3 hours', now() - interval '3 hours'),
  ('f0000001-0000-0000-0000-000000000021', 'IL-021', 'd0000001-0000-0000-0000-000000000006', 'PENDIENTE',  900.00, '300 etiquetas nuevas para colección invierno',             (now() + interval '6 days')::date,  now() - interval '2 hours', now() - interval '2 hours'),
  ('f0000001-0000-0000-0000-000000000022', 'IL-022', 'd0000001-0000-0000-0000-000000000004', 'PENDIENTE',  225.00, '5 blocks recetas + 1 sello personalizado',                (now() + interval '3 days')::date,  now() - interval '1 hour',  now() - interval '1 hour'),
  ('f0000001-0000-0000-0000-000000000023', 'IL-023', 'd0000001-0000-0000-0000-000000000007', 'PENDIENTE', 1700.00, 'Lona 8x3m para fachada de nuevo proyecto',                (now() + interval '7 days')::date,  now() - interval '30 minutes', now() - interval '30 minutes'),

-- == CANCELADO ==
  ('f0000001-0000-0000-0000-000000000024', 'IL-024', 'd0000001-0000-0000-0000-000000000005', 'CANCELADO',  325.00, 'Cliente canceló. Ya no necesita las notas.',               NULL,                               now() - interval '20 days', now() - interval '18 days'),
  ('f0000001-0000-0000-0000-000000000025', 'IL-025', 'd0000001-0000-0000-0000-000000000008', 'CANCELADO',  780.00, 'Cambió de diseño. Se hará pedido nuevo.',                  NULL,                               now() - interval '15 days', now() - interval '14 days');

-- =====================
-- 5. PEDIDO ITEMS (artículos de cada pedido)
-- =====================
INSERT INTO public.pedido_items (pedido_id, producto_id, descripcion_personalizada, cantidad, precio_unitario) VALUES
  -- IL-001: Volantes promo verano
  ('f0000001-0000-0000-0000-000000000001', 'e0000001-0000-0000-0000-000000000001', NULL, 500, 1.50),
  -- IL-002: Menús laminados
  ('f0000001-0000-0000-0000-000000000002', 'e0000001-0000-0000-0000-000000000008', NULL, 70, 18.00),
  -- IL-003: 5 millares tarjetas
  ('f0000001-0000-0000-0000-000000000003', 'e0000001-0000-0000-0000-000000000003', NULL, 5, 350.00),
  -- IL-004: Recetas membretadas
  ('f0000001-0000-0000-0000-000000000004', 'e0000001-0000-0000-0000-000000000011', NULL, 8, 45.00),
  -- IL-005: Notas de servicio
  ('f0000001-0000-0000-0000-000000000005', 'e0000001-0000-0000-0000-000000000012', NULL, 8, 65.00),
  -- IL-006: Etiquetas ropa
  ('f0000001-0000-0000-0000-000000000006', 'e0000001-0000-0000-0000-000000000014', NULL, 500, 3.00),
  -- IL-007: Lona + tarjetas arquitecto
  ('f0000001-0000-0000-0000-000000000007', 'e0000001-0000-0000-0000-000000000004', 'Lona 6x3m con diseño de proyecto residencial', 18, 85.00),
  ('f0000001-0000-0000-0000-000000000007', 'e0000001-0000-0000-0000-000000000003', 'Tarjetas con render del proyecto', 2.5, 350.00),
  -- IL-008: Café - menús + stickers + volantes
  ('f0000001-0000-0000-0000-000000000008', 'e0000001-0000-0000-0000-000000000008', 'Menú otoño con nuevas bebidas', 30, 18.00),
  ('f0000001-0000-0000-0000-000000000008', 'e0000001-0000-0000-0000-000000000007', 'Sticker logo para vasos', 200, 5.00),
  ('f0000001-0000-0000-0000-000000000008', 'e0000001-0000-0000-0000-000000000001', 'Volantes happy hour', 200, 1.50),
  -- IL-009: Facturas autocopiables
  ('f0000001-0000-0000-0000-000000000009', 'e0000001-0000-0000-0000-000000000012', NULL, 6, 65.00),
  -- IL-010: Volantes septiembre
  ('f0000001-0000-0000-0000-000000000010', 'e0000001-0000-0000-0000-000000000001', NULL, 750, 1.50),
  -- IL-011: Playeras + lona gimnasio
  ('f0000001-0000-0000-0000-000000000011', 'e0000001-0000-0000-0000-000000000016', 'Playera sublimada logo PowerFit', 40, 95.00),
  -- IL-012: Diplomas + programas escuela
  ('f0000001-0000-0000-0000-000000000012', 'e0000001-0000-0000-0000-000000000013', NULL, 100, 15.00),
  -- IL-013: Papelería legal
  ('f0000001-0000-0000-0000-000000000013', 'e0000001-0000-0000-0000-000000000003', 'Tarjetas abogado', 1, 350.00),
  ('f0000001-0000-0000-0000-000000000013', 'e0000001-0000-0000-0000-000000000012', 'Notas membretadas despacho', 5, 65.00),
  ('f0000001-0000-0000-0000-000000000013', 'e0000001-0000-0000-0000-000000000019', 'Carpetas corporativas con logo', 8, 35.00),
  -- IL-014: Volantes carnicería
  ('f0000001-0000-0000-0000-000000000014', 'e0000001-0000-0000-0000-000000000002', 'Volantes carta con ofertas semanales', 240, 2.50),
  -- IL-015: Lonas + folletos inmobiliaria
  ('f0000001-0000-0000-0000-000000000015', 'e0000001-0000-0000-0000-000000000004', 'Lona "Se Vende / Renta" 2x1m', 8, 85.00),
  ('f0000001-0000-0000-0000-000000000015', 'e0000001-0000-0000-0000-000000000009', 'Folleto tríptico con 3 propiedades', 200, 4.50),
  ('f0000001-0000-0000-0000-000000000015', 'e0000001-0000-0000-0000-000000000003', 'Tarjetas vendedores', 2, 350.00),
  -- IL-016: Boda completa
  ('f0000001-0000-0000-0000-000000000016', 'e0000001-0000-0000-0000-000000000010', 'Invitación elegante con sobre dorado', 200, 12.00),
  ('f0000001-0000-0000-0000-000000000016', 'e0000001-0000-0000-0000-000000000017', 'Taza recuerdo con foto de novios', 100, 75.00),
  -- IL-017: Menús restaurante
  ('f0000001-0000-0000-0000-000000000017', 'e0000001-0000-0000-0000-000000000008', 'Menú otoño laminado doble carta', 80, 18.00),
  -- IL-018: Gym nueva sucursal
  ('f0000001-0000-0000-0000-000000000018', 'e0000001-0000-0000-0000-000000000015', 'Roll-up promoción inscripción', 2, 650.00),
  ('f0000001-0000-0000-0000-000000000018', 'e0000001-0000-0000-0000-000000000001', 'Volantes inauguración A5', 500, 1.30),
  -- IL-019: Café actualización
  ('f0000001-0000-0000-0000-000000000019', 'e0000001-0000-0000-0000-000000000007', 'Stickers navideños para vasos', 300, 5.00),
  ('f0000001-0000-0000-0000-000000000019', 'e0000001-0000-0000-0000-000000000008', 'Menú navideño especial', 50, 15.00),
  -- IL-020: Tarjetas papelería
  ('f0000001-0000-0000-0000-000000000020', 'e0000001-0000-0000-0000-000000000003', NULL, 3, 350.00),
  -- IL-021: Etiquetas boutique
  ('f0000001-0000-0000-0000-000000000021', 'e0000001-0000-0000-0000-000000000014', 'Etiquetas colección invierno', 300, 3.00),
  -- IL-022: Doctora
  ('f0000001-0000-0000-0000-000000000022', 'e0000001-0000-0000-0000-000000000011', NULL, 5, 45.00),
  -- IL-023: Lona arquitecto
  ('f0000001-0000-0000-0000-000000000023', 'e0000001-0000-0000-0000-000000000004', 'Lona 8x3m fachada proyecto comercial', 24, 70.83),
  -- Cancelados
  ('f0000001-0000-0000-0000-000000000024', 'e0000001-0000-0000-0000-000000000012', NULL, 5, 65.00),
  ('f0000001-0000-0000-0000-000000000025', 'e0000001-0000-0000-0000-000000000012', NULL, 12, 65.00);

-- =====================
-- 6. PAGOS (mezcla de anticipos y pagos completos)
-- =====================
-- Nota: el trigger pagos_to_movimientos_caja crea movimientos de caja automáticamente

INSERT INTO public.pagos (pedido_id, monto, metodo, referencia, es_anticipo, creado_en) VALUES
  -- Entregados (pagados completamente)
  ('f0000001-0000-0000-0000-000000000001', 400.00,  'EFECTIVO',      NULL,                true,   now() - interval '50 days'),
  ('f0000001-0000-0000-0000-000000000001', 350.00,  'EFECTIVO',      NULL,                false,  now() - interval '45 days'),
  ('f0000001-0000-0000-0000-000000000002', 600.00,  'TRANSFERENCIA', 'BBVA ref 4521',     true,   now() - interval '45 days'),
  ('f0000001-0000-0000-0000-000000000002', 660.00,  'TRANSFERENCIA', 'BBVA ref 4589',     false,  now() - interval '40 days'),
  ('f0000001-0000-0000-0000-000000000003', 1750.00, 'EFECTIVO',      NULL,                false,  now() - interval '38 days'),
  ('f0000001-0000-0000-0000-000000000004', 360.00,  'EFECTIVO',      NULL,                false,  now() - interval '35 days'),
  ('f0000001-0000-0000-0000-000000000005', 520.00,  'TRANSFERENCIA', 'Banorte ref 7823',  false,  now() - interval '32 days'),
  ('f0000001-0000-0000-0000-000000000006', 750.00,  'EFECTIVO',      NULL,                true,   now() - interval '32 days'),
  ('f0000001-0000-0000-0000-000000000006', 750.00,  'EFECTIVO',      NULL,                false,  now() - interval '28 days'),
  ('f0000001-0000-0000-0000-000000000007', 1000.00, 'TRANSFERENCIA', 'HSBC ref 3341',     true,   now() - interval '28 days'),
  ('f0000001-0000-0000-0000-000000000007', 1550.00, 'EFECTIVO',      NULL,                false,  now() - interval '25 days'),
  ('f0000001-0000-0000-0000-000000000008', 1850.00, 'EFECTIVO',      NULL,                false,  now() - interval '21 days'),
  ('f0000001-0000-0000-0000-000000000009', 390.00,  'EFECTIVO',      NULL,                false,  now() - interval '18 days'),
  ('f0000001-0000-0000-0000-000000000010', 500.00,  'EFECTIVO',      NULL,                true,   now() - interval '18 days'),
  ('f0000001-0000-0000-0000-000000000010', 625.00,  'EFECTIVO',      NULL,                false,  now() - interval '14 days'),
  ('f0000001-0000-0000-0000-000000000011', 2000.00, 'TRANSFERENCIA', 'BBVA ref 9012',     true,   now() - interval '14 days'),
  ('f0000001-0000-0000-0000-000000000011', 1800.00, 'EFECTIVO',      NULL,                false,  now() - interval '10 days'),
  ('f0000001-0000-0000-0000-000000000012', 1500.00, 'EFECTIVO',      NULL,                false,  now() - interval '8 days'),

  -- Terminados (parcialmente pagados)
  ('f0000001-0000-0000-0000-000000000013', 500.00,  'TRANSFERENCIA', 'Santander ref 1122', true,  now() - interval '5 days'),
  ('f0000001-0000-0000-0000-000000000014', 300.00,  'EFECTIVO',      NULL,                true,   now() - interval '3 days'),
  ('f0000001-0000-0000-0000-000000000015', 1200.00, 'TRANSFERENCIA', 'BBVA ref 5567',     true,   now() - interval '4 days'),

  -- En producción (con anticipos)
  ('f0000001-0000-0000-0000-000000000016', 1800.00, 'EFECTIVO',      NULL,                true,   now() - interval '2 days'),
  ('f0000001-0000-0000-0000-000000000017', 700.00,  'TRANSFERENCIA', 'Banorte ref 8834',  true,   now() - interval '2 days'),
  ('f0000001-0000-0000-0000-000000000018', 1000.00, 'EFECTIVO',      NULL,                true,   now() - interval '1 day'),

  -- Pendientes (algunos con anticipo, otros sin)
  ('f0000001-0000-0000-0000-000000000019', 1000.00, 'EFECTIVO',      NULL,                true,   now() - interval '6 hours'),
  ('f0000001-0000-0000-0000-000000000022', 225.00,  'EFECTIVO',      NULL,                false,  now() - interval '1 hour');

-- =====================
-- 7. GASTOS (variados y realistas)
-- =====================
INSERT INTO public.gastos (concepto, monto, categoria, notas, created_at) VALUES
  ('Compra papel couché 150g (10 resmas)',      1200.00, 'MATERIAL',        'Proveedor: Papeles del Norte',                now() - interval '48 days'),
  ('Compra tinta pigmentada Epson (4 colores)',  850.00, 'MATERIAL',        'Kit CMYK para plotter',                       now() - interval '45 days'),
  ('Renta del local agosto',                    4500.00, 'RENTA',           'Depósito + mensualidad',                      now() - interval '42 days'),
  ('Recibo de luz agosto',                       780.00, 'SERVICIOS',       'CFE periodo ago-sep',                         now() - interval '38 days'),
  ('Mantenimiento plotter Roland',               650.00, 'MANTENIMIENTO',   'Limpieza cabezales + calibración',            now() - interval '35 days'),
  ('Compra vinil adhesivo (20m²)',               600.00, 'MATERIAL',        'Vinil blanco brillante Oracal 651',           now() - interval '30 days'),
  ('Internet y teléfono septiembre',             450.00, 'SERVICIOS',       'Telmex fibra óptica',                         now() - interval '28 days'),
  ('Compra cartulina opalina (5 resmas)',         350.00, 'MATERIAL',        'Para invitaciones y diplomas',                now() - interval '25 days'),
  ('Gasolina camioneta entregas',                500.00, 'GASOLINA',        'Semana del 10 al 16',                         now() - interval '22 days'),
  ('Compra lona front 13oz (30m²)',              750.00, 'MATERIAL',        'Rollo 1.60m de ancho',                        now() - interval '20 days'),
  ('Sueldo empleado Juan (quincena)',           3500.00, 'NÓMINA',          'Primera quincena septiembre',                 now() - interval '18 days'),
  ('Renta del local septiembre',                4500.00, 'RENTA',           'Mensualidad septiembre',                      now() - interval '15 days'),
  ('Compra papel sublimación (2 rollos)',         480.00, 'MATERIAL',        'Para playeras y tazas',                       now() - interval '12 days'),
  ('Recibo de luz septiembre',                   820.00, 'SERVICIOS',       'CFE periodo sep-oct',                         now() - interval '10 days'),
  ('Gasolina camioneta entregas',                450.00, 'GASOLINA',        'Semana del 24 al 30',                         now() - interval '7 days'),
  ('Sueldo empleado Juan (quincena)',           3500.00, 'NÓMINA',          'Segunda quincena septiembre',                 now() - interval '5 days'),
  ('Compra tinta eco-solvente',                  950.00, 'MATERIAL',        'Para impresora de lonas',                     now() - interval '3 days'),
  ('Caja de ojillos y herramienta',              180.00, 'MATERIAL',        'Ojillos metálicos para lonas',                now() - interval '2 days'),
  ('Internet y teléfono octubre',                450.00, 'SERVICIOS',       'Telmex fibra óptica',                         now() - interval '1 day');

-- ============================================================
-- ✅ DEMO SEED COMPLETE
-- ============================================================
-- Resumen de datos cargados:
--   • 15 clientes ficticios (negocios locales de Culiacán)
--   • 20 productos típicos de imprenta
--   • 25 pedidos (12 entregados, 3 terminados, 3 en producción, 5 pendientes, 2 cancelados)
--   • 26 pagos (mezcla de anticipos y pagos completos)
--   • 19 gastos (materiales, renta, servicios, nómina, gasolina)
--   • Config del negocio: "Imprenta López & Hijos" con tema violeta
--
-- El dashboard mostrará:
--   - Gráficas con datos de los últimos ~50 días
--   - Pedidos en todos los estados del flujo
--   - Mezcla de clientes frecuentes y nuevos
--   - Gastos vs ingresos reales
-- ============================================================
