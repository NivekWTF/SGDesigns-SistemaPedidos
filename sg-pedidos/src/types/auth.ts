export type AppRole = 'admin' | 'empleado'

export interface UserProfile {
  id: string
  email?: string | null
  full_name?: string | null
  role: AppRole
  created_at?: string | null
  updated_at?: string | null
}