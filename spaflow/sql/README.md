# SpaFlow — Instrucciones de Migración SQL

## Orden de Ejecución

Ejecuta los scripts **uno por uno** en el SQL Editor de Supabase, en este orden exacto:

| # | Archivo | Contenido | Duración estimada |
|---|---|---|---|
| 1 | `00_spas_tenants.sql` | Tabla `profiles` (nueva), tabla `spas`, funciones RBAC (`current_spa_id`, `current_app_role`, etc.), trigger new user, RLS profiles+spas | ~10 seg |
| 2 | `01_schema_base.sql` | ALTER `profiles` (agregar `spa_id`, constraints de roles, trigger anti-eliminación de último admin), tabla `clientes` + RLS | ~10 seg |
| 3 | `02_servicios_productos.sql` | Tablas `servicios`, `productos`, `paquetes`, `paquete_servicios` | ~10 seg |
| 4 | `03_personal_horarios.sql` | Tablas `personal`, `horarios_personal`, `bloqueos_agenda` | ~10 seg |
| 5 | `04_citas.sql` | Tablas `citas`, `cita_items`, `pagos_cita`, triggers de folio y estado | ~15 seg |
| 6 | `05_caja_gastos.sql` | Tablas `cajas`, `movimientos_caja`, `gastos`, triggers de pagos | ~15 seg |
| 7 | `06_funciones_disponibilidad.sql` | Función `get_disponibilidad()` para el wizard de citas | ~5 seg |
| 8 | `07_funciones_reportes.sql` | Funciones de dashboard y reportes | ~5 seg |
| 9 | `08_seed_data.sql` | **Solo desarrollo**: 2 spas, 10 servicios, 3 terapeutas, 5 clientes | ~5 seg |

---

## Pasos Previos

### 1. Crear proyecto Supabase

1. Ve a [supabase.com](https://supabase.com) → **New Project**
2. Nombre: `spaflow-prod` (o `spaflow-dev` para pruebas)
3. Selecciona la región más cercana (us-east-1 o us-west-1 para México)
4. Guarda el **database password**

### 2. Obtener las keys

En **Settings → API**:
- `Project URL` → `VITE_SUPABASE_URL`
- `anon public` → `VITE_SUPABASE_ANON_KEY`

Pégalas en `spa-app/.env.local`:
```
VITE_SUPABASE_URL=https://TU-PROYECTO.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciO...
```

### 3. Ejecutar los scripts

En Supabase → **SQL Editor** → **New query** → pegar el contenido de cada archivo → **Run**.

---

## Post-migración: Crear el primer Superadmin

Después de registrar tu cuenta en la app:

```sql
-- Ejecutar en Supabase SQL Editor
UPDATE public.profiles
SET role = 'superadmin', spa_id = NULL
WHERE email = 'tu-email@ejemplo.com';
```

## Crear el primer spa y admin_spa

```sql
-- 1. Insertar el spa
INSERT INTO public.spas (nombre, slug, color_primario, zona_horaria, plan)
VALUES ('Mi Spa', 'mi-spa', '#8b5cf6', 'America/Mexico_City', 'pro')
RETURNING id;  -- Copia este UUID

-- 2. Asociar al admin (después de que se registre en la app)
UPDATE public.profiles
SET role = 'admin_spa', spa_id = 'UUID-DEL-SPA-AQUI'
WHERE email = 'admin@mispa.com';
```

---

## Estructura de Tablas Resultante

```
spas                    ← Tenants del SaaS
├── profiles            ← Usuarios con spa_id
├── clientes            ← Clientes del spa
├── servicios           ← Catálogo de servicios
├── productos           ← Productos de venta
├── paquetes            ← Combos de servicios
│   └── paquete_servicios
├── personal            ← Terapeutas
│   ├── horarios_personal
│   └── bloqueos_agenda
├── citas               ← Core del sistema
│   ├── cita_items      ← Servicios/productos de la cita
│   └── pagos_cita      ─── trigger ──→ movimientos_caja
├── cajas
├── movimientos_caja
└── gastos              ─── trigger ──→ movimientos_caja
```

---

## Verificar Aislamiento de Tenants

Para confirmar que RLS funciona correctamente:

1. Login como usuario del **Spa A**
2. Abrir Supabase Table Editor → `citas`
3. Debe mostrar solo las citas del Spa A
4. Ejecutar en SQL Editor:
   ```sql
   -- Debe retornar 0 filas si el usuario es del Spa A
   SELECT * FROM citas WHERE spa_id != current_spa_id();
   ```

---

## Troubleshooting

| Error | Solución |
|---|---|
| `profiles_role_check violation` | El rol asignado no es uno de los 4 válidos |
| `profiles_tenant_consistency violation` | superadmin tiene spa_id o usuario normal no tiene spa_id |
| `cita_anticipo_valido` | El anticipo no puede ser mayor al total de la cita |
| `cita_item_solo_un_tipo` | Un item de cita debe ser servicio, producto, o descripción; no mezclar |
| `current_spa_id() returns NULL` | El perfil del usuario no tiene spa_id asignado |
