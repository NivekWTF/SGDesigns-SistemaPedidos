export interface Producto {
  id: string
  nombre: string
  descripcion?: string | null
  unidad?: string | null
  precio_base: number
  costo_material?: number | null
  stock?: number | null
  activo: boolean
  created_at?: string | null
}

export interface ProductoInput {
  nombre: string
  descripcion?: string
  unidad?: string
  precio_base: number
  costo_material?: number | null
  activo?: boolean
  stock?: number | null
}

