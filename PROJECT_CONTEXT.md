# 🧠 Contexto del Proyecto — Sistema de Pedidos para Imprentas

> Última actualización: 2026-08-09 21:56 (hora Pacífico)
> Conversación: Se agregaron/separaron los KPIs en el Dashboard Gerencial para distinguir **Cobrado Hoy** (dinero real ingresado por pagos/anticipos) de **Pedidos Hoy** (monto total de pedidos creados).

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
│   │   │   ├── HomeView.vue       # ⭐ ACTUALIZADO: Dashboard con 5 KPIs (Cobrado Hoy vs Pedidos Hoy)
│   │   │   ├── PedidosView.vue    # Gestión de pedidos (45KB)
│   │   │   ├── NewOrderWizard.vue # Wizard de nuevo pedido (52KB)
│   │   │   ├── CajaView.vue       # Control de caja (19KB)
│   │   │   ├── SettingsView.vue   # Panel de configuración
│   │   │   ├── Sidebar.vue        # Navegación con RBAC + branding dinámico
│   │   │   ├── LoginView.vue      # Auth con email/Google
│   │   │   ├── CotizadorView.vue  # Wrapper del cotizador
│   │   │   ├── QRGeneratorView.vue # Generador QR (26KB)
│   │   │   ├── OrderDetailsModal.vue # Modal detalles + pagos
│   │   │   └── ...otros
│   │   ├── composables/           # 12 composables
│   │   │   ├── useAuth.ts         # Autenticación + RBAC
│   │   │   ├── useBusinessConfig.ts # Config del negocio (BD + env fallback)
│   │   │   ├── usePedidos.ts      # CRUD pedidos + tickets térmicos (20KB)
│   │   │   ├── useReportes.ts     # RPCs de reportes (ventas, ganancias, gastos)
│   │   │   ├── useQuoteStore.ts   # Cotizador + PDF (white-labeled)
│   │   │   ├── useCaja.ts         # Movimientos de caja
│   │   │   ├── useProductos.ts    # Productos + stock
│   │   │   └── ...otros
│   │   ├── lib/
│   │   │   ├── supabase.ts        # Cliente Supabase
│   │   │   ├── costs.ts           # Reglas de costos (data-driven)
│   │   │   └── utils.ts
│   │   ├── types/                 # 8 archivos TypeScript (incluye pagos.ts)
│   │   ├── router/index.ts        # 13 rutas con RBAC (incluye /configuracion)
│   │   ├── main.ts                # Bootstrap + loadConfig()
│   │   └── App.vue                # Shell: sidebar + topbar + router-view
│   ├── .env.local                 # Config de SG Designs
│   ├── .env.example               # Template para nuevos clientes
│   ├── Dockerfile                 # Multi-stage build (12 ARGs)
│   └── docker-compose.yml         # Docker deploy (12 build args)
├── landing/                       # Landing page de venta
│   └── index.html                 # Página standalone de marketing
├── sql/                           # 16 scripts SQL
│   ├── onboarding_complete.sql    # Script único de setup (~600 líneas)
│   ├── create_business_config.sql # Tabla de configuración
│   ├── report_sales_by_day.sql    # Actualizado: usa pagos.monto
│   ├── report_sales_by_week.sql   # Actualizado: usa pagos.monto
│   ├── report_sales_by_month.sql  # Actualizado: usa pagos.monto
│   ├── report_profit_and_expenses.sql       # Actualizado: usa pagos.monto
│   ├── report_profit_and_expenses_weekly.sql # Actualizado: usa pagos.monto
│   ├── report_orders_by_day.sql   # Lista pedidos del día (sin cambio)
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

**Fase 4 — Regla de negocio & KPIs en Dashboard:**
- **5 RPCs SQL actualizadas**: `report_sales_by_day`, `report_sales_by_week`, `report_sales_by_month`, `report_profit_and_expenses`, `report_profit_and_expenses_weekly`.
- **Nuevo KPI "Cobrado Hoy" en `HomeView.vue`**: Muestra `$0.00` si se crea un pedido sin anticipo/pago.
- **KPI "Pedidos Hoy"**: Muestra el valor contratado total de pedidos creados hoy.

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
| **Separación de Cobrado vs Pedidos** | "Cobrado Hoy" mide el flujo real de dinero ingresado (pagos/anticipos). "Pedidos Hoy" mide el monto contratado generado hoy. |

---

## Cómo Continuar

1. **Para vender a un nuevo cliente:**
   - Crear proyecto en Supabase
   - Ejecutar `sql/onboarding_complete.sql` en SQL Editor
   - Copiar `.env.example` → `.env.local` y llenar Supabase URL + key
   - `npm install && npm run dev` o deploy con Docker

2. **Si hay bugs:**
   - `npx vue-tsc --noEmit` para verificar tipos
   - El proyecto compila limpio a la fecha (2026-08-09)
