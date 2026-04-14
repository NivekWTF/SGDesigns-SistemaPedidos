// src/composables/useCitas.ts
import { ref } from 'vue'
import { supabase } from '../lib/supabase'
import { useTenant } from './useTenant'
import type { Servicio } from './useServicios'
import type { Cliente } from './useClientes'
import type { Terapeuta } from './usePersonal'

export type EstadoCita = 'AGENDADA' | 'CONFIRMADA' | 'EN_CURSO' | 'COMPLETADA' | 'CANCELADA' | 'NO_SHOW'
export type MetodoPago  = 'EFECTIVO' | 'TRANSFERENCIA' | 'TARJETA' | 'OTRO'

export interface CitaItem {
  id: string
  cita_id: string
  servicio_id: string | null
  producto_id: string | null
  descripcion_personalizada: string | null
  cantidad: number
  precio_unitario: number
  subtotal: number
  // joins opcionales
  servicios?: Pick<Servicio, 'id' | 'nombre' | 'categoria' | 'duracion_min'>
}

export interface PagoCita {
  id: string
  cita_id: string
  monto: number
  metodo: MetodoPago
  es_anticipo: boolean
  referencia: string | null
  creado_en: string
}

export interface Cita {
  id: string
  spa_id: string
  folio: string | null
  cliente_id: string
  personal_id: string | null
  estado: EstadoCita
  fecha_inicio: string
  fecha_fin: string
  notas: string | null
  notas_internas: string | null
  total: number
  anticipo: number
  created_by: string | null
  created_at: string
  updated_at: string
  // joins
  clientes?: Pick<Cliente, 'id' | 'nombre' | 'telefono' | 'correo'>
  personal?: Pick<Terapeuta, 'id' | 'nombre' | 'color_agenda'>
  cita_items?: CitaItem[]
  pagos_cita?: PagoCita[]
}

export interface NuevaCitaInput {
  cliente_id: string
  personal_id: string | null
  fecha_inicio: string
  fecha_fin: string
  notas?: string
  notas_internas?: string
  anticipo?: number
  items: Array<{
    servicio_id?: string
    producto_id?: string
    descripcion_personalizada?: string
    cantidad: number
    precio_unitario: number
  }>
  pago_inicial?: {
    monto: number
    metodo: MetodoPago
    es_anticipo: boolean
  }
}

const citas = ref<Cita[]>([])
const loading = ref(false)
const errorMsg = ref<string | null>(null)

const CITA_SELECT = `
  id, spa_id, folio, cliente_id, personal_id, estado,
  fecha_inicio, fecha_fin, notas, notas_internas, total, anticipo,
  created_by, created_at, updated_at,
  clientes (id, nombre, telefono, correo),
  personal (id, nombre, color_agenda),
  cita_items (
    id, cita_id, servicio_id, producto_id, descripcion_personalizada,
    cantidad, precio_unitario, subtotal,
    servicios (id, nombre, categoria, duracion_min)
  ),
  pagos_cita (id, cita_id, monto, metodo, es_anticipo, referencia, creado_en)
`

async function fetchCitas(params?: {
  desde?: string
  hasta?: string
  personalId?: string
  estado?: EstadoCita
}) {
  loading.value = true
  errorMsg.value = null

  let query = supabase
    .from('citas')
    .select(CITA_SELECT)
    .order('fecha_inicio', { ascending: true })

  if (params?.desde) query = query.gte('fecha_inicio', params.desde)
  if (params?.hasta) query = query.lte('fecha_inicio', params.hasta)
  if (params?.personalId) query = query.eq('personal_id', params.personalId)
  if (params?.estado) query = query.eq('estado', params.estado)

  const { data, error } = await query.limit(500)

  if (error) {
    errorMsg.value = error.message
  } else {
    citas.value = (data ?? []) as Cita[]
  }

  loading.value = false
}

async function crearCita(input: NuevaCitaInput): Promise<Cita> {
  errorMsg.value = null
  const { spaId } = useTenant()
  if (!spaId.value) throw new Error('No hay spa activo')

  // Calcular total
  const total = input.items.reduce((sum, item) => sum + item.cantidad * item.precio_unitario, 0)

  // 1. Crear la cita
  const { data: cita, error: citaErr } = await supabase
    .from('citas')
    .insert({
      spa_id: spaId.value,
      cliente_id: input.cliente_id,
      personal_id: input.personal_id ?? null,
      fecha_inicio: input.fecha_inicio,
      fecha_fin: input.fecha_fin,
      notas: input.notas ?? null,
      notas_internas: input.notas_internas ?? null,
      total,
      anticipo: input.anticipo ?? 0,
    })
    .select('id, folio')
    .single()

  if (citaErr) { errorMsg.value = citaErr.message; throw citaErr }

  const citaId = (cita as any).id as string

  // 2. Insertar los items
  if (input.items.length > 0) {
    const { error: itemsErr } = await supabase
      .from('cita_items')
      .insert(input.items.map(item => ({ ...item, cita_id: citaId })))

    if (itemsErr) { errorMsg.value = itemsErr.message; throw itemsErr }
  }

  // 3. Registrar pago inicial si aplica
  if (input.pago_inicial && input.pago_inicial.monto > 0) {
    const { error: pagoErr } = await supabase
      .from('pagos_cita')
      .insert({
        cita_id: citaId,
        monto: input.pago_inicial.monto,
        metodo: input.pago_inicial.metodo,
        es_anticipo: input.pago_inicial.es_anticipo,
      })

    if (pagoErr) { errorMsg.value = pagoErr.message; throw pagoErr }
  }

  // 4. Recargar la cita con todos los joins
  const { data: full, error: fullErr } = await supabase
    .from('citas')
    .select(CITA_SELECT)
    .eq('id', citaId)
    .single()

  if (fullErr) { errorMsg.value = fullErr.message; throw fullErr }

  const nuevaCita = full as Cita
  citas.value.push(nuevaCita)
  return nuevaCita
}

async function actualizarEstado(citaId: string, estado: EstadoCita, notasInternas?: string) {
  const update: Record<string, any> = { estado }
  if (notasInternas !== undefined) update.notas_internas = notasInternas

  const { data, error } = await supabase
    .from('citas')
    .update(update)
    .eq('id', citaId)
    .select(CITA_SELECT)
    .single()

  if (error) { errorMsg.value = error.message; throw error }

  const idx = citas.value.findIndex(c => c.id === citaId)
  if (idx !== -1) citas.value[idx] = data as Cita
  return data as Cita
}

async function registrarPago(citaId: string, pago: { monto: number; metodo: MetodoPago; es_anticipo?: boolean; referencia?: string }) {
  const { data, error } = await supabase
    .from('pagos_cita')
    .insert({ cita_id: citaId, es_anticipo: false, ...pago })
    .select()
    .single()

  if (error) { errorMsg.value = error.message; throw error }

  // Actualizar la cita en memoria
  const citaIdx = citas.value.findIndex(c => c.id === citaId)
  if (citaIdx !== -1) {
    citas.value[citaIdx].pagos_cita = [
      ...(citas.value[citaIdx].pagos_cita ?? []),
      data as PagoCita
    ]
  }

  return data as PagoCita
}

async function cancelarCita(citaId: string, motivo?: string) {
  return actualizarEstado(citaId, 'CANCELADA', motivo)
}

// ── Disponibilidad ───────────────────────────────────────────────
export interface SlotDisponible {
  slot_inicio: string
  slot_fin: string
}

async function getDisponibilidad(personalId: string, fecha: string, duracionMin: number): Promise<SlotDisponible[]> {
  const { spaId } = useTenant()

  const { data, error } = await supabase
    .rpc('get_disponibilidad', {
      p_personal_id: personalId,
      p_fecha: fecha,
      p_duracion_min: duracionMin,
      p_spa_id: spaId.value,
    })

  if (error) throw error
  return (data ?? []) as SlotDisponible[]
}

export function useCitas() {
  return {
    citas,
    loading,
    errorMsg,
    fetchCitas,
    crearCita,
    actualizarEstado,
    registrarPago,
    cancelarCita,
    getDisponibilidad,
  }
}
