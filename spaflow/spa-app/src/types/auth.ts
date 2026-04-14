// ── SpaFlow RBAC Roles ────────────────────────────────────────────────────
// superadmin   → dueño del SaaS (spa_id = null)
// admin_spa    → gerente/dueño del spa
// recepcionista → staff que agenda citas y registra pagos
// terapeuta    → personal que ejecuta los servicios
// ─────────────────────────────────────────────────────────────────────────
export type AppRole = 'superadmin' | 'admin_spa' | 'recepcionista' | 'terapeuta'

export interface UserProfile {
  id: string
  email?: string | null
  full_name?: string | null
  role: AppRole
  spa_id?: string | null       // null solo para superadmin
  created_at?: string | null
  updated_at?: string | null
}