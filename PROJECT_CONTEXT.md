# 🧠 Contexto del Proyecto — Sistema de Pedidos para Imprentas

> Última actualización: 2026-10-03 20:05 (hora Pacífico)
> Conversación: Diagnóstico y solución del buscador de pedidos:
> 1. Se identificó el error exacto que causaba que la RPC fallara en Supabase: `operator does not exist: estado_pedido = text` (PostgreSQL 42883) al comparar el enum `pe.estado` con `p_status`.
> 2. Se actualizó la RPC `search_pedidos` a v4 en `sql/search_pedidos_rpc.sql` corrigiendo `pe.estado::text = p_status`, agregando búsqueda multi-palabra con `unnest` y `NOT EXISTS`, soporte con `unaccent` y `search_path = public, extensions`.
> 3. Se mejoró `_fetchPedidosFallback` en `usePedidos.ts` para que soporte búsqueda multi-palabra, busque tanto en `descripcion_personalizada` como en `productos.nombre`, amplíe el rango de búsqueda a 300 pedidos e implemente paginación local limpia.

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
| Dominio activo | `https://pedidos.sgdesigns.site` | Traefik + Dokploy + Let's Encrypt |

---

## Arquitectura

```
SGDesigns-SistemaPedidos/
├── sg-pedidos/                    # ⭐ App principal (Vue 3 + Vite)
│   ├── src/
│   │   ├── components/            # 21 componentes Vue
│   │   │   ├── HomeView.vue       # Dashboard con 5 KPIs (Cobrado Hoy vs Pedidos Hoy)
│   │   │   ├── PedidosView.vue    # ⭐ ACTUALIZADO: Usa paginación server-side (doFetch)
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
│   │   │   ├── usePedidos.ts      # ⭐ ACTUALIZADO: fetchPedidosPaginated + server-side filters
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
├── sql/                           # 20 scripts SQL
│   ├── onboarding_complete.sql    # Script único de setup (~600 líneas)
│   ├── add_pagination_indexes.sql # ⭐ NUEVO: Índices GIN + B-tree para paginación
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

**Fase 4 — Regla de negocio & KPIs en Dashboard:**
- **5 RPCs SQL actualizadas**: `report_sales_by_day`, `report_sales_by_week`, `report_sales_by_month`, `report_profit_and_expenses`, `report_profit_and_expenses_weekly`.
- **Nuevo KPI "Cobrado Hoy"**: Muestra `$0.00` si se crea un pedido sin anticipo/pago.
- **KPI "Pedidos Hoy"**: Muestra el valor contratado total de pedidos creados hoy.

**Fase 5 — Paginación server-side: ✅ COMPLETADO (2026-10-01)**
- `usePedidos.ts`: Nueva función `fetchPedidosPaginated(FetchPedidosParams)` con filtros en BD
- `PedidosView.vue`: Migrado a `doFetch()` que llama la función paginada
- `sql/add_pagination_indexes.sql`: Índices GIN trigram + B-tree creados

**Fase 6 — Buscador mejorado: ✅ COMPLETADO (2026-10-03)**
- `sql/search_pedidos_rpc.sql`: RPC PostgreSQL que hace JOIN pedidos+clientes+pedido_items para búsqueda full-text en BD (cliente nombre, folio, notas, descripción ítems)
- `usePedidos.ts`: `fetchPedidosPaginated()` ahora usa la RPC cuando hay texto de búsqueda, con fallback a folio/notas si la RPC no está desplegada
- `PedidosView.vue`: Debounce de 400ms en el buscador, corregido bug `onlyWithAnticipo` no se enviaba al servidor, botón ✕ para limpiar búsqueda, icono 🔍
- `sql/search_pedidos_rpc.sql`: Incluye índices GIN trigram en `clientes.nombre` y `pedido_items.descripcion_personalizada`

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
| **Separación de Cobrado vs Pedidos** | "Cobrado Hoy" mide el flujo real de dinero ingresado. "Pedidos Hoy" mide el monto contratado generado hoy. |
| **Paginación server-side con .range()** | Evita traer todos los pedidos a memoria. Filtros de estado/fecha/notas van en la query de Supabase. Búsqueda por nombre de cliente/ítems se hace localmente sobre la página ya traída (PostgREST no puede filtrar en tablas relacionadas sin vista). |
| **fetchPedidos() interno limitado a 50** | Mutations (crearPedido, actualizarPedidoCompleto) llaman fetchPedidos() internamente. Se limitó a 50 para no revertir la mejora de rendimiento. PedidosView siempre usa doFetch(). |

---

## Archivos Clave

| Archivo | Qué hace |
|---------|----------|
| `sg-pedidos/src/composables/usePedidos.ts` | ⭐ CRUD pedidos. `fetchPedidosPaginated()` es la fn principal de carga. `fetchPedidos()` solo para uso interno en mutaciones. |
| `sg-pedidos/src/components/PedidosView.vue` | Vista de pedidos. `doFetch()` construye params y llama fetchPedidosPaginated. Watchers en filtros + página disparan doFetch(). |
| `sql/add_pagination_indexes.sql` | Índices para optimizar paginación. Ejecutar en Supabase SQL Editor. Incluye pg_trgm para ILIKE. |
| `sg-pedidos/src/composables/useBusinessConfig.ts` | Singleton con config del negocio desde BD. Aplica CSS vars dinámicas. |
| `sg-pedidos/src/components/SettingsView.vue` | Panel admin de configuración. Colores, logo, datos negocio. |
| `sg-pedidos/src/components/HomeView.vue` | Dashboard con KPIs: Cobrado Hoy, Pedidos Hoy, Pendientes, etc. |
| `sql/onboarding_complete.sql` | Setup completo para nuevo cliente (ejecutar una sola vez). |
| `sg-pedidos/Dockerfile` | Multi-stage build con 12 ARGs para white-labeling. |

---

## Patrón de Paginación Server-Side (snippet clave)

```typescript
// En usePedidos.ts — Cómo funciona fetchPedidosPaginated
export interface FetchPedidosParams {
  page: number
  pageSize: number
  search?: string
  status?: string          // 'ALL' | EstadoPedido
  startDate?: string | null
  endDate?: string | null
  onlyWithAnticipo?: boolean
  onlyWithNotes?: boolean
}

// Filtros aplicados en la query:
// - status: .eq('estado', status)
// - startDate/endDate: .gte/.lte('created_at', ...)
// - onlyWithNotes: .not('notas', 'is', null).neq('notas', '')
// - search: .or(`folio.ilike.%q%,notas.ilike.%q%`)
// - paginación: .range(from, to)
// - count exacto: select(SELECT, { count: 'exact' })

// En PedidosView.vue — Cómo se llama
function doFetch() {
  return fetchPedidosPaginated({
    page: currentPage.value,
    pageSize: PAGE_SIZE, // 20
    search: searchTerm.value || '',
    status: statusFilter.value,
    startDate: startDate.value,
    endDate: endDate.value,
    onlyWithNotes: onlyWithNotes.value,
  })
}
// Watchers en filtros y currentPage llaman doFetch()
// onNewCreated() y onPaymentUpdated() también llaman doFetch()
```

> ✅ **Resuelto (Fase 6)**: La búsqueda por nombre de cliente (`clientes.nombre`) y descripciones de ítems (`pedido_items.descripcion_personalizada`) ahora funciona via la RPC `search_pedidos` que hace el JOIN en el servidor PostgreSQL. Ejecutar `sql/search_pedidos_rpc.sql` en Supabase SQL Editor para activarla.

---

## Variables de Entorno

```env
# sg-pedidos/.env.local
VITE_SUPABASE_URL=https://xxx.supabase.co
VITE_SUPABASE_ANON_KEY=xxx

VITE_BUSINESS_NAME=SG Designs
VITE_BUSINESS_ADDRESS=Dirección física
VITE_BUSINESS_PHONE=Teléfono
VITE_BUSINESS_SOCIALS=FB: @sgdesigns
VITE_BUSINESS_LOGO_URL=/logo.png
VITE_DEFAULT_BRAND_COLOR=#059669
```

---

## Pendiente / Ideas futuras

- ✅ **Buscador completo por cliente**: Resuelto con RPC `search_pedidos` — ejecutar `sql/search_pedidos_rpc.sql`
- 🟡 **Ejecutar `search_pedidos_rpc.sql`** en Supabase SQL Editor (incluye índices GIN para clientes y pedido_items)
- 🟡 **Ejecutar `add_pagination_indexes.sql`** en Supabase SQL Editor del cliente (aún no confirmado).
- 🟢 **Exportar pedidos filtrados a CSV/Excel**.
- 🟢 **Notificaciones push / Realtime** cuando llega un pedido nuevo.

---

## Cómo Continuar

1. **Ejecutar índices en producción:**
   - Supabase → SQL Editor → pegar contenido de `sql/add_pagination_indexes.sql`
   - Verificar: `SELECT indexname FROM pg_indexes WHERE tablename = 'pedidos';`

2. **Para vender a un nuevo cliente:**
   - Crear proyecto en Supabase
   - Ejecutar `sql/onboarding_complete.sql` en SQL Editor
   - Copiar `.env.example` → `.env.local` y llenar Supabase URL + key
   - `npm install && npm run dev` o deploy con Docker

3. **Si hay bugs:**
   - `npx vue-tsc --noEmit` para verificar tipos (compila limpio al 2026-10-01)
   - El proyecto corre con `npm run dev` en `sg-pedidos/`
