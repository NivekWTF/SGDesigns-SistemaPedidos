export interface Pago {
  id: string
  pedido_id: string
  monto: number
  metodo?: string | null
  referencia?: string | null
  creado_en: string
  es_anticipo: boolean
}

export interface PagoInput {
  pedido_id: string
  monto: number
  metodo?: string | null
  referencia?: string | null
  es_anticipo?: boolean
}
