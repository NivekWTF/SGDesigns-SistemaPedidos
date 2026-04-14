// src/composables/useClientes.ts
import { ref } from 'vue'
import { supabase } from '../lib/supabase'
import { useTenant } from './useTenant'

export interface Cliente {
  id: string
  spa_id: string
  nombre: string
  telefono: string | null
  correo: string | null
  fecha_nacimiento: string | null
  genero: 'F' | 'M' | 'O' | null
  alergias: string | null
  notas_preferencias: string | null
  fecha_ultima_visita: string | null
  created_at: string
}

export type ClienteInput = Omit<Cliente, 'id' | 'spa_id' | 'created_at' | 'fecha_ultima_visita'>

const clientes = ref<Cliente[]>([])
const loading = ref(false)
const errorMsg = ref<string | null>(null)

async function fetchClientes() {
  loading.value = true
  errorMsg.value = null

  const { data, error } = await supabase
    .from('clientes')
    .select('*')
    .order('nombre', { ascending: true })

  if (error) {
    errorMsg.value = error.message
  } else {
    clientes.value = (data ?? []) as Cliente[]
  }

  loading.value = false
}

async function buscarClientes(q: string) {
  loading.value = true
  errorMsg.value = null

  const { data, error } = await supabase
    .from('clientes')
    .select('*')
    .or(`nombre.ilike.%${q}%,telefono.ilike.%${q}%,correo.ilike.%${q}%`)
    .order('nombre', { ascending: true })
    .limit(30)

  loading.value = false

  if (error) {
    errorMsg.value = error.message
    return []
  }

  return (data ?? []) as Cliente[]
}

async function crearCliente(input: ClienteInput) {
  errorMsg.value = null
  const { spaId } = useTenant()

  if (!spaId.value) throw new Error('No hay spa activo')

  const { data, error } = await supabase
    .from('clientes')
    .insert({ ...input, spa_id: spaId.value })
    .select()
    .single()

  if (error) {
    errorMsg.value = error.message
    throw error
  }

  clientes.value.unshift(data as Cliente)
  return data as Cliente
}

async function actualizarCliente(id: string, input: Partial<ClienteInput>) {
  const { data, error } = await supabase
    .from('clientes')
    .update(input)
    .eq('id', id)
    .select()
    .single()

  if (error) {
    errorMsg.value = error.message
    throw error
  }

  const idx = clientes.value.findIndex(c => c.id === id)
  if (idx !== -1) clientes.value[idx] = data as Cliente
  return data as Cliente
}

async function eliminarCliente(id: string) {
  const { error } = await supabase
    .from('clientes')
    .delete()
    .eq('id', id)

  if (error) {
    errorMsg.value = error.message
    throw error
  }

  clientes.value = clientes.value.filter(c => c.id !== id)
}

export function useClientes() {
  return {
    clientes,
    loading,
    errorMsg,
    fetchClientes,
    buscarClientes,
    crearCliente,
    actualizarCliente,
    eliminarCliente,
  }
}
