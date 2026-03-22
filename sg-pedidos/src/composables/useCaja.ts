import { ref } from 'vue'
import { supabase } from '../lib/supabase'
import type { Caja, MovimientoCaja, MovimientoCajaInput } from '../types'

const cajas = ref<Caja[]>([])
const cajaActiva = ref<Caja | null>(null)
const movimientos = ref<MovimientoCaja[]>([])
const loading = ref(false)
const errorMsg = ref<string | null>(null)

function buildRange(dateStr: string, endOfDay = false): string {
  const parts = dateStr.split('-').map((v) => Number(v))
  if (parts.length < 3 || parts.some((n) => Number.isNaN(n))) {
    return new Date().toISOString()
  }
  const year = parts[0] ?? 1970
  const month = parts[1] ?? 1
  const day = parts[2] ?? 1
  if (endOfDay) return new Date(year, month - 1, day, 23, 59, 59, 999).toISOString()
  return new Date(year, month - 1, day, 0, 0, 0, 0).toISOString()
}

async function ensureCajaActiva() {
  loading.value = true
  errorMsg.value = null

  const { data, error } = await supabase
    .from('cajas')
    .select('*')
    .eq('abierta', true)
    .order('fecha_apertura', { ascending: false })
    .limit(1)

  if (error) {
    errorMsg.value = error.message
    loading.value = false
    return null
  }

  const existing = (data || [])[0] as Caja | undefined
  if (existing) {
    cajaActiva.value = existing
    loading.value = false
    return existing
  }

  const { data: created, error: createError } = await supabase
    .from('cajas')
    .insert({ nombre: 'Caja principal', saldo_inicial: 0, abierta: true })
    .select()
    .single()

  if (createError) {
    errorMsg.value = createError.message
    loading.value = false
    return null
  }

  cajaActiva.value = created as Caja
  loading.value = false
  return cajaActiva.value
}

async function fetchCajas() {
  loading.value = true
  errorMsg.value = null

  const { data, error } = await supabase
    .from('cajas')
    .select('*')
    .order('fecha_apertura', { ascending: false })

  if (error) {
    errorMsg.value = error.message
  } else {
    cajas.value = (data || []) as Caja[]
  }
  loading.value = false
}

async function abrirCaja(saldoInicial: number, nombre = 'Caja principal') {
  loading.value = true
  errorMsg.value = null

  const { error: closeError } = await supabase
    .from('cajas')
    .update({ abierta: false, fecha_cierre: new Date().toISOString() })
    .eq('abierta', true)

  if (closeError) {
    errorMsg.value = closeError.message
    loading.value = false
    throw closeError
  }

  const { data, error } = await supabase
    .from('cajas')
    .insert({ nombre, saldo_inicial: saldoInicial, abierta: true })
    .select()
    .single()

  if (error) {
    errorMsg.value = error.message
    loading.value = false
    throw error
  }

  cajaActiva.value = data as Caja
  loading.value = false
  return cajaActiva.value
}

async function fetchMovimientos(params?: { cajaId?: string; dateFrom?: string | null; dateTo?: string | null }) {
  loading.value = true
  errorMsg.value = null

  let cajaId = params?.cajaId || cajaActiva.value?.id
  if (!cajaId) {
    const caja = await ensureCajaActiva()
    cajaId = caja?.id
  }

  if (!cajaId) {
    loading.value = false
    return
  }

  let query = supabase
    .from('movimientos_caja')
    .select('*')
    .eq('caja_id', cajaId)
    .order('created_at', { ascending: false })
    .limit(500)

  if (params?.dateFrom) {
    query = query.gte('created_at', buildRange(params.dateFrom))
  }
  if (params?.dateTo) {
    query = query.lte('created_at', buildRange(params.dateTo, true))
  }

  const { data, error } = await query

  if (error) {
    errorMsg.value = error.message
  } else {
    movimientos.value = (data || []) as MovimientoCaja[]
  }

  loading.value = false
}

async function crearMovimiento(input: MovimientoCajaInput) {
  errorMsg.value = null

  let cajaId = input.caja_id || cajaActiva.value?.id
  if (!cajaId) {
    const caja = await ensureCajaActiva()
    cajaId = caja?.id
  }

  if (!cajaId) {
    throw new Error('No hay caja activa disponible')
  }

  const payload = {
    ...input,
    caja_id: cajaId,
    metodo_pago: input.metodo_pago || 'EFECTIVO'
  }

  const { data, error } = await supabase
    .from('movimientos_caja')
    .insert(payload)
    .select()
    .single()

  if (error) {
    errorMsg.value = error.message
    throw error
  }

  if (data) movimientos.value.unshift(data as MovimientoCaja)
  return data as MovimientoCaja
}

export function useCaja() {
  return {
    cajas,
    cajaActiva,
    movimientos,
    loading,
    errorMsg,
    ensureCajaActiva,
    fetchCajas,
    abrirCaja,
    fetchMovimientos,
    crearMovimiento
  }
}
