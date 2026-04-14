export interface Cliente {
  id: string
  nombre: string
  telefono?: string | null
  correo?: string | null
  created_at?: string | null
}

export interface ClienteInput {
  nombre: string
  telefono?: string
  correo?: string
}

