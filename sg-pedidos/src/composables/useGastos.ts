import { ref } from 'vue'
import { supabase } from '../lib/supabase'

export interface Gasto {
  id: string
  descripcion: string | null
  monto: number
  producto_id: string | null
  referencia: string | null
  meta: any
  created_at: string | null
}

export interface GastoInput {
  descripcion?: string
  monto: number
  producto_id?: string | null
  referencia?: string
}

const gastos = ref<Gasto[]>([])
const loading = ref(false)
const errorMsg = ref<string | null>(null)

async function fetchGastos() {
  loading.value = true
  errorMsg.value = null
  const { data, error } = await supabase
    .from('gastos')
    .select('*')
    .order('created_at', { ascending: false })
  if (error) {
    errorMsg.value = error.message
  } else {
    gastos.value = data ?? []
  }
  loading.value = false
}

async function crearGasto(input: GastoInput) {
  errorMsg.value = null
  const { data, error } = await supabase
    .from('gastos')
    .insert(input)
    .select()
    .single()
  if (error) {
    errorMsg.value = error.message
    throw error
  }
  gastos.value.unshift(data)
  return data
}

async function eliminarGasto(id: string) {
  const { error } = await supabase
    .from('gastos')
    .delete()
    .eq('id', id)
  if (error) {
    errorMsg.value = error.message
    throw error
  }
  gastos.value = gastos.value.filter(g => g.id !== id)
}

export function useGastos() {
  return {
    gastos,
    loading,
    errorMsg,
    fetchGastos,
    crearGasto,
    eliminarGasto
  }
}
