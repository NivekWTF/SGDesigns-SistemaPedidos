// src/composables/useProductos.ts
import { ref } from 'vue'
import { supabase } from '../lib/supabase'
import type { Producto, ProductoInput } from '../types'

const productos = ref<Producto[]>([])
const loading = ref(false)
const errorMsg = ref<string | null>(null)

async function fetchProductos() {
  loading.value = true
  errorMsg.value = null

  const { data, error } = await supabase
    .from('productos')
    .select('*')
    .order('nombre', { ascending: true })

  if (error) {
    errorMsg.value = error.message
  } else {
    productos.value = data ?? []
  }

  loading.value = false
}

async function crearProducto(input: ProductoInput) {
  const { data, error } = await supabase
    .from('productos')
    .insert({
      ...input,
      activo: input.activo ?? true
    })
    .select()
    .single()

  if (error) {
    errorMsg.value = error.message
    throw error
  }

  productos.value.push(data)
  return data
}

async function actualizarProducto(id: string, input: ProductoInput) {
  const { data, error } = await supabase
    .from('productos')
    .update(input)
    .eq('id', id)
    .select()
    .single()

  if (error) {
    errorMsg.value = error.message
    throw error
  }

  const idx = productos.value.findIndex(p => p.id === id)
  if (idx !== -1) productos.value[idx] = data
  return data
}

async function eliminarProducto(id: string) {
  const { error } = await supabase
    .from('productos')
    .delete()
    .eq('id', id)

  if (error) {
    errorMsg.value = error.message
    throw error
  }

  productos.value = productos.value.filter(p => p.id !== id)
}

export function useProductos() {
  return {
    productos,
    loading,
    errorMsg,
    fetchProductos,
    crearProducto,
    actualizarProducto,
    eliminarProducto
  }
}
