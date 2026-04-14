// src/composables/useGastos.ts
import { ref } from 'vue'
import { supabase } from '../lib/supabase'
import { useTenant } from './useTenant'

export type MetodoGasto = 'EFECTIVO' | 'TRANSFERENCIA' | 'TARJETA' | 'OTRO'

export interface Gasto {
  id: string
  spa_id: string
  concepto: string
  monto: number
  categoria: string | null
  metodo_pago: MetodoGasto
  fecha: string
  notas: string | null
  created_at: string
}

export type GastoInput = Omit<Gasto, 'id' | 'spa_id' | 'created_at'>

const gastos = ref<Gasto[]>([])
const loading = ref(false)
const errorMsg = ref<string | null>(null)

async function fetchGastos(params?: { desde?: string; hasta?: string }) {
  loading.value = true
  errorMsg.value = null

  let query = supabase
    .from('gastos')
    .select('*')
    .order('fecha', { ascending: false })
    .order('created_at', { ascending: false })

  if (params?.desde) query = query.gte('fecha', params.desde)
  if (params?.hasta) query = query.lte('fecha', params.hasta)

  const { data, error } = await query.limit(500)

  if (error) {
    errorMsg.value = error.message
  } else {
    gastos.value = (data ?? []) as Gasto[]
  }
  loading.value = false
}

async function crearGasto(input: GastoInput) {
  errorMsg.value = null
  const { spaId } = useTenant()
  if (!spaId.value) throw new Error('No hay spa activo')

  const { data, error } = await supabase
    .from('gastos')
    .insert({ ...input, spa_id: spaId.value })
    .select()
    .single()

  if (error) { errorMsg.value = error.message; throw error }

  gastos.value.unshift(data as Gasto)
  return data as Gasto
}

async function eliminarGasto(id: string) {
  const { error } = await supabase.from('gastos').delete().eq('id', id)
  if (error) { errorMsg.value = error.message; throw error }
  gastos.value = gastos.value.filter(g => g.id !== id)
}

export function useGastos() {
  return { gastos, loading, errorMsg, fetchGastos, crearGasto, eliminarGasto }
}
