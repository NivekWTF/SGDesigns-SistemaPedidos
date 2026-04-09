export type EstadoPedido =
  | 'PENDIENTE'
  | 'EN_PRODUCCION'
  | 'TERMINADO'
  | 'ENTREGADO'
  | 'CANCELADO'

export interface PedidoItemInput {
  producto_id: string | null
  descripcion_personalizada?: string
  cantidad: number
  precio_unitario: number
}

export interface CrearPedidoInput {
  cliente_id: string
  notas?: string
  fecha_entrega?: string // 'YYYY-MM-DD'
  items: PedidoItemInput[]
  anticipo?: number
  anticipo_metodo?: string
}

export interface PedidoItem {
  id: string
  producto_id?: string | null
  descripcion_personalizada?: string | null
  cantidad: number
  precio_unitario: number
  subtotal?: number | null
  productos?: import('./productos').Producto | null
}

export interface PedidoArchivo {
  id: string
  pedido_id: string
  url: string
  nombre_archivo: string
  tipo?: string | null
  tamanio_bytes?: number | null
  created_at?: string | null
}

export interface Pedido {
  id: string
  folio?: string | null
  estado: EstadoPedido
  total: number
  notas?: string | null
  created_at?: string | null
  updated_at?: string | null
  cliente_id?: string | null
  /** relación opcional cargada desde la tabla `clientes` */
  clientes?: import('./clientes').Cliente | null
  pedido_items?: PedidoItem[] | null
  /** archivos adjuntos (fotos de referencia, diseños, etc.) */
  pedido_archivos?: PedidoArchivo[] | null
}
