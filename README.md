# 🖨️ Sistema de Gestión de Pedidos para Imprentas
### Vue 3 + Supabase | White-Label Ready

Sistema web completo para gestionar pedidos, clientes, productos, caja, gastos y reportes de una imprenta.
Diseñado para ser desplegado como instancia independiente para cada negocio.

---

## 🚀 Tecnologías

| Capa | Tecnología |
|------|------------|
| Frontend | Vue 3 + TypeScript + Vite |
| Estado | Composables reactivos (Vue 3 Composition API) |
| Estilos | TailwindCSS v4 |
| Backend | Supabase (PostgreSQL + Auth + Storage + Realtime) |
| Deploy | Docker + Nginx / Vercel |

---

## 📦 Módulos del Sistema

- 📊 **Dashboard** — Gráficas de ingresos, gastos y ganancias
- 📦 **Pedidos** — Crear, editar, flujo de estados, tickets térmicos
- 👥 **Clientes** — Alta y gestión
- 🛒 **Productos** — Catálogo con precios, costos y stock
- 💰 **Caja** — Control de flujo de efectivo
- 💸 **Gastos** — Registro de egresos
- 📈 **Reportes** — Ventas por producto, rentabilidad mensual
- 🧾 **Cotizador** — Generación de cotizaciones PDF
- 🏷️ **QR Generator** — Códigos QR personalizados
- 👤 **Usuarios** — RBAC con roles admin/empleado
- 🖨️ **Tickets** — Impresión térmica automática (58mm)

---

## ⚡ Inicio Rápido (Nueva Instancia)

### 1. Crear proyecto en Supabase

1. Ve a [supabase.com](https://supabase.com) y crea un proyecto nuevo
2. Abre el **SQL Editor** y ejecuta el archivo: `sql/onboarding_complete.sql`
3. Copia la **URL del proyecto** y la **anon key** desde Settings > API

### 2. Configurar variables de entorno

```bash
cd sg-pedidos
cp .env.example .env.local
```

Edita `.env.local` con los datos del negocio:

```env
# Supabase (obligatorio)
VITE_SUPABASE_URL=https://tu-proyecto.supabase.co
VITE_SUPABASE_ANON_KEY=tu-anon-key

# Datos del negocio
VITE_BUSINESS_NAME="Imprenta López"
VITE_BUSINESS_RFC="XXXX000000XXX"
VITE_BUSINESS_EMAIL="contacto@imprentalopez.com"
VITE_BUSINESS_ADDRESS="Calle Ejemplo #123, Ciudad"
VITE_BUSINESS_PHONE="(123) 456 7890"
VITE_BUSINESS_LOGO_URL="./logo.png"
VITE_BUSINESS_SOCIALS="FB: @imprentaLopez • IG: @imprentalopez"

# Cotizador
VITE_BUSINESS_SERIES="IL"
VITE_BUSINESS_TAX_RATE="0.16"
```

### 3. Instalar y ejecutar

```bash
cd sg-pedidos
npm install
npm run dev
```

### 4. Primer usuario = Administrador

El primer usuario que se registre se convierte automáticamente en **Administrador**.
Los siguientes usuarios serán **Empleados** (el admin puede cambiarles el rol).

---

## 🐳 Deploy con Docker

```bash
cd sg-pedidos
docker-compose up -d --build
```

Las variables se leen del archivo `.env.local` automáticamente.

---

## 📁 Estructura del Proyecto

```
sg-pedidos/
├── src/
│   ├── components/     # Vistas y componentes Vue
│   ├── composables/    # Lógica de negocio (useAuth, usePedidos, etc.)
│   ├── lib/            # Supabase client, costos, utilidades
│   ├── router/         # Rutas con RBAC
│   ├── types/          # TypeScript interfaces
│   └── App.vue         # Shell con sidebar + router-view
├── sql/                # Migraciones SQL
│   └── onboarding_complete.sql  # ⭐ Script único de setup
├── .env.example        # Plantilla de configuración
├── Dockerfile          # Build de producción
└── docker-compose.yml  # Deploy con Docker
```

---

## 🔒 Seguridad

- **Row Level Security (RLS)** en todas las tablas
- Roles: `admin` (acceso completo) y `empleado` (solo pedidos y cotizador)
- Protección contra eliminación del último admin
- Auth via Supabase (email/password + Google OAuth)

---

## 📄 Licencia

Proyecto privado. No distribuir sin autorización.