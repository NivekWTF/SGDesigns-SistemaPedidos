# 🧠 Contexto del Proyecto — Sistema de Pedidos para Imprentas

> Última actualización: 2026-08-09 09:46 (hora Pacífico)
> Conversación: Se completaron las 3 fases de comercialización — white-label, scripts, panel de config, colores y landing page.

---

## Stack Tecnológico

| Capa | Tecnología | Versión |
|------|------------|---------|
| Frontend | Vue 3 + TypeScript | `vue@3.5.24` |
| Build | Vite | `vite@7.2.4` |
| Estilos | TailwindCSS v4 | `tailwindcss@4.1.18` |
| UI Components | Lucide Vue, Reka UI | `lucide-vue-next@0.562.0`, `reka-ui@2.7.0` |
| Backend | Supabase (PostgreSQL + Auth + Storage + Realtime) | `@supabase/supabase-js@2.36.0` |
| PDF | jsPDF + jspdf-autotable | `jspdf@4.2.1` |
| QR | qrcode | `qrcode@1.5.4` |
| Deploy | Docker + Nginx | `node:20-bullseye-slim` → `nginx:stable-alpine` |

---

## Arquitectura

```
SGDesigns-SistemaPedidos/
├── sg-pedidos/                    # ⭐ App principal (Vue 3 + Vite)
│   ├── src/
│   │   ├── components/            # 21 componentes Vue
│   │   │   ├── HomeView.vue       # Dashboard con gráficas (31KB)
│   │   │   ├── PedidosView.vue    # Gestión de pedidos (45KB)
│   │   │   ├── NewOrderWizard.vue # Wizard de nuevo pedido (52KB)
│   │   │   ├── CajaView.vue       # Control de caja (19KB)
│   │   │   ├── SettingsView.vue   # ⭐ NUEVO: Panel de configuración
│   │   │   ├── Sidebar.vue        # Navegación con RBAC + branding dinámico
│   │   │   ├── LoginView.vue      # Auth con email/Google
│   │   │   ├── CotizadorView.vue  # Wrapper del cotizador
│   │   │   ├── QRGeneratorView.vue # Generador QR (26KB)
│   │   │   └── ...otros
│   │   ├── composables/           # 12 composables
│   │   │   ├── useAuth.ts         # Autenticación + RBAC
│   │   │   ├── useBusinessConfig.ts # ⭐ NUEVO: Config del negocio (BD + env fallback)
│   │   │   ├── usePedidos.ts      # CRUD pedidos + tickets térmicos (20KB)
│   │   │   ├── useQuoteStore.ts   # Cotizador + PDF (white-labeled)
│   │   │   ├── useCaja.ts         # Movimientos de caja
│   │   │   ├── useProductos.ts    # Productos + stock
│   │   │   └── ...otros
│   │   ├── lib/
│   │   │   ├── supabase.ts        # Cliente Supabase
│   │   │   ├── costs.ts           # Reglas de costos (data-driven)
│   │   │   └── utils.ts
│   │   ├── types/                 # 8 archivos TypeScript
│   │   ├── router/index.ts        # 13 rutas con RBAC (incluye /configuracion)
│   │   ├── main.ts                # Bootstrap + loadConfig()
│   │   └── App.vue                # Shell: sidebar + topbar + router-view
│   ├── .env.local                 # Config de SG Designs
│   ├── .env.example               # Template para nuevos clientes
│   ├── Dockerfile                 # Multi-stage build (12 ARGs)
│   └── docker-compose.yml         # Docker deploy (12 build args)
├── landing/                       # ⭐ NUEVO: Landing page de venta
│   └── index.html                 # Página standalone de marketing
├── sql/                           # 16 scripts SQL
│   ├── onboarding_complete.sql    # Script único de setup (con business_config)
│   ├── create_business_config.sql # ⭐ NUEVO: Tabla de configuración
│   └── ...otros
├── supabase/functions/            # Edge functions
├── .agents/skills/save-context/   # Skill de guardar contexto
├── PROJECT_CONTEXT.md             # ← Este archivo
└── README.md                      # Documentación de deploy
```

---

## Estado Actual

### ✅ Todo Completado

**Fase 1 — White-label del código:**
- `useQuoteStore.ts`: Funciones `buildDefaultHeader()` / `buildDefaultState()` con env vars
- `Sidebar.vue`: Nombre e iniciales dinámicos desde `useBusinessConfig()`
- `costs.ts`: Reglas como arrays data-driven
- 4 nuevas variables de entorno

**Fase 2 — Scripts y documentación:**
- `onboarding_complete.sql`: Script único de setup (con `business_config`)
- `.env.example`: Template documentado
- `README.md`: Guía completa de deploy
- Dockerfile + docker-compose: 12 variables de build

**Fase 3 — Panel de config + colores + landing:**
- `SettingsView.vue`: Panel completo (datos, logo, cotizador, colores)
- `useBusinessConfig.ts`: Estado reactivo singleton con BD + env fallback + CSS vars
- `create_business_config.sql`: Tabla single-row con RLS
- 8 paletas de colores predefinidas + pickers + preview en vivo
- `landing/index.html`: Página de marketing responsive
- Ruta `/configuracion` + enlace ⚙️ en sidebar
- CSS variables dinámicas (`--brand-primary`, `--brand-accent`, etc.)
- TypeScript: 0 errores

### 📋 Ideas Futuras (no bloqueantes)

- 🟢 Notificaciones WhatsApp cuando pedido está listo
- 🟢 Portal público para que clientes vean status de su pedido
- 🟢 Backup automático de BD
- 🟢 Migrar reglas de costos de `costs.ts` a tabla BD
- 🟢 Subir logo a Supabase Storage en vez de base64/URL

---

## Decisiones de Diseño

| Decisión | Razón |
|----------|-------|
| Instancia separada por cliente | Datos 100% aislados, sin refactor de multi-tenant |
| Config en BD + env fallback | El admin cambia desde la app; env vars para setup inicial |
| Single-row `business_config` | Trigger previene múltiples rows; simple de consultar |
| CSS vars para colores | Se aplican en runtime sin rebuild; funciona con dark mode |
| Reglas de costos como arrays | Más rápido que migrar a BD; futuro: tabla `material_rules` |
| Landing page standalone HTML | No necesita framework; se puede hostear en cualquier lado |

---

## Variables de Entorno

| Variable | Obligatoria | Default |
|----------|-------------|---------|
| `VITE_SUPABASE_URL` | ✅ | — |
| `VITE_SUPABASE_ANON_KEY` | ✅ | — |
| `VITE_BUSINESS_NAME` | ❌ | "Mi Imprenta" |
| `VITE_BUSINESS_RFC` | ❌ | "" |
| `VITE_BUSINESS_EMAIL` | ❌ | "" |
| `VITE_BUSINESS_ADDRESS` | ❌ | "" |
| `VITE_BUSINESS_PHONE` | ❌ | "" |
| `VITE_BUSINESS_LOGO_URL` | ❌ | "/logo.png" |
| `VITE_BUSINESS_SOCIALS` | ❌ | "" |
| `VITE_BUSINESS_SERIES` | ❌ | "COT" |
| `VITE_BUSINESS_TAX_RATE` | ❌ | "0.16" |

**Nota:** Estas son solo los defaults iniciales. Una vez que el admin guarda desde Configuración, los valores de BD prevalecen.

---

## Tabla `business_config` (BD)

| Columna | Tipo | Default |
|---------|------|---------|
| `business_name` | text | NULL |
| `business_rfc` | text | NULL |
| `business_email` | text | NULL |
| `business_address` | text | NULL |
| `business_phone` | text | NULL |
| `business_logo_url` | text | NULL |
| `business_socials` | text | NULL |
| `business_series` | text | 'COT' |
| `tax_rate` | numeric(5,4) | 0.16 |
| `color_primary` | text | '#0ea5e9' |
| `color_primary_dark` | text | '#0284c7' |
| `color_accent` | text | '#38bdf8' |

---

## Archivos Clave

| Archivo | Qué hace |
|---------|----------|
| `composables/useBusinessConfig.ts` | Config reactiva: BD → env fallback → CSS vars |
| `composables/usePedidos.ts` | CRUD pedidos + tickets térmicos + RPC stock |
| `composables/useQuoteStore.ts` | Cotizador + PDF (white-labeled) |
| `composables/useAuth.ts` | Auth con roles admin/empleado |
| `components/SettingsView.vue` | Panel de configuración completo |
| `components/NewOrderWizard.vue` | Wizard multi-step para pedidos (52KB) |
| `components/PedidosView.vue` | Vista principal de pedidos (45KB) |
| `router/index.ts` | 13 rutas con RBAC guard |
| `lib/costs.ts` | Reglas de costos data-driven |
| `sql/onboarding_complete.sql` | Script único de setup (~600 líneas) |
| `landing/index.html` | Landing page de venta |

---

## Cómo Continuar

1. **Para vender a un nuevo cliente:**
   - Crear proyecto en Supabase
   - Ejecutar `sql/onboarding_complete.sql` en SQL Editor
   - Copiar `.env.example` → `.env.local` y llenar Supabase URL + key
   - `npm install && npm run dev` o deploy con Docker
   - Primer usuario registrado = admin automáticamente
   - El admin configura todo desde ⚙️ Configuración

2. **Para la landing page:**
   - Abrir `landing/index.html` en un navegador
   - Personalizar precios, textos y WhatsApp link
   - Hostear en cualquier servidor estático (Netlify, GitHub Pages, etc.)

3. **Si hay bugs:**
   - `npx vue-tsc --noEmit` para verificar tipos
   - El proyecto compila limpio a la fecha (2026-08-09)
