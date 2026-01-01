// src/composables/useClientes.ts
import { ref } from 'vue'
import { supabase } from '../lib/supabase'
import type { Cliente, ClienteInput } from '../types'

const clientes = ref<Cliente[]>([])
const loading = ref(false)
const errorMsg = ref<string | null>(null)

async function fetchClientes() {
  loading.value = true
  errorMsg.value = null

  const { data, error } = await supabase
    .from('clientes')
    .select('*')
    .order('created_at', { ascending: false })

  if (error) {
    errorMsg.value = error.message
  } else {
    clientes.value = data ?? []
  }

  loading.value = false
}

async function crearCliente(input: ClienteInput) {
  errorMsg.value = null

  const { data, error } = await supabase
    .from('clientes')
    .insert(input)
    .select()
    .single()

  if (error) {
    errorMsg.value = error.message
    throw error
  }

  clientes.value.unshift(data)
  return data
}

async function actualizarCliente(id: string, input: ClienteInput) {
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
  if (idx !== -1) clientes.value[idx] = data
  return data
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
    crearCliente,
    actualizarCliente,
    eliminarCliente
  }
}
