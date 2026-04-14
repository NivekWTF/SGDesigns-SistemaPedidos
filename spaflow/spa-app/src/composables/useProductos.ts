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

  // If initial stock > 0, record an expense for adding stock (compra)
  try {
    const stockQty = (input.stock ?? 0) as number
    if (stockQty > 0) {
      const costo = (input.costo_material ?? 0) as number
      const monto = costo * stockQty
      if (monto > 0) {
        await supabase.from('gastos').insert({
          descripcion: `Compra inicial de stock: ${input.nombre}`,
          monto,
          producto_id: data.id,
          referencia: 'stock_add',
          meta: { qty: stockQty }
        })
      }
    }
  } catch (e) {
    console.warn('Failed to insert gasto for initial stock', e)
  }

  return data
}

async function actualizarProducto(id: string, input: ProductoInput) {
  // If stock is being updated, compute delta and record gasto for increase
  // Fetch previous product to compute delta
  const { data: prev, error: prevErr } = await supabase.from('productos').select('id, nombre, stock').eq('id', id).single()
  if (prevErr) {
    errorMsg.value = prevErr.message
    throw prevErr
  }

  const prevStock = (prev as any).stock ?? 0
  const newStock = typeof input.stock === 'number' ? input.stock : prevStock

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

  // If stock increased, insert gasto for the added quantity using costo_material
  try {
    const delta = (newStock ?? 0) - (prevStock ?? 0)
    if (delta > 0) {
      const costo = ( (input.costo_material ?? (data as any).costo_material) ?? 0 ) as number
      const monto = costo * delta
      if (monto > 0) {
        await supabase.from('gastos').insert({
          descripcion: `Compra de stock: ${(data as any).nombre}`,
          monto,
          producto_id: id,
          referencia: 'stock_add',
          meta: { qty: delta }
        })
      }
    }
  } catch (e) {
    console.warn('Failed to insert gasto for stock update', e)
  }

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
