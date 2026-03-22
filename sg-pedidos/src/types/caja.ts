export type MetodoPago = 'EFECTIVO' | 'TRANSFERENCIA' | 'TARJETA' | 'OTRO'

export type TipoMovimientoCaja =
  | 'VENTA'
  | 'ANTICIPO'
  | 'ABONO'
  | 'GASTO_NEGOCIO'
  | 'GASTO_PERSONAL'
  | 'RETIRO_DUENO'
  | 'COMPRA_MATERIAL'
  | 'AJUSTE_ENTRADA'
  | 'AJUSTE_SALIDA'
  | 'PAGO_SERVICIO'
  | 'PRESTAMO_RECIBIDO'

export interface Caja {
  id: string
  nombre: string
  saldo_inicial: number
  abierta: boolean
  fecha_apertura: string
  fecha_cierre?: string | null
  created_at: string
}

export interface MovimientoCaja {
  id: string
  caja_id: string
  pedido_id?: string | null
  tipo: TipoMovimientoCaja
  concepto: string
  categoria?: string | null
  metodo_pago: MetodoPago | string
  es_entrada: boolean
  monto: number
  notas?: string | null
  created_at: string
}

export interface MovimientoCajaInput {
  caja_id?: string
  pedido_id?: string | null
  tipo: TipoMovimientoCaja
  concepto: string
  categoria?: string | null
  metodo_pago?: MetodoPago | string
  es_entrada: boolean
  monto: number
  notas?: string | null
  created_at?: string
}
