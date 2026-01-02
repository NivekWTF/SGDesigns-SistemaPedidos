import { ref } from 'vue'
import { supabase } from '../lib/supabase'
import type { CrearPedidoInput, EstadoPedido, Pedido, PedidoItem } from '../types'

const pedidos = ref<Pedido[]>([])
const loading = ref(false)
const errorMsg = ref<string | null>(null)

async function fetchPedidos() {
  loading.value = true
  errorMsg.value = null

  const { data, error } = await supabase
    .from('pedidos')
    .select(`
      id,
      folio,
      estado,
      notas,
      total,
      created_at,
      cliente_id,
      clientes ( nombre ),
      pedido_items ( id, descripcion_personalizada, cantidad, precio_unitario, subtotal, productos ( nombre ) )
    `)
    .order('created_at', { ascending: false })

  if (error) {
    errorMsg.value = error.message
  } else {
    pedidos.value = (data as unknown as Pedido[]) || []
  }

  loading.value = false
}

async function crearPedido(input: CrearPedidoInput) {
  errorMsg.value = null

  // calcular total a partir de los items
  const total = input.items.reduce(
    (acc, it) => acc + it.cantidad * it.precio_unitario,
    0
  )

  // 1) insertar pedido
  const { data: pedido, error: errorPedido } = await supabase
    .from('pedidos')
    .insert({
      cliente_id: input.cliente_id,
      notas: input.notas,
      fecha_entrega: input.fecha_entrega ?? null,
      total
    })
    .select()
    .single()

  if (errorPedido || !pedido) {
    errorMsg.value = errorPedido?.message ?? 'Error al crear pedido'
    throw errorPedido
  }

  // 2) insertar items
  const itemsToInsert = input.items.map(it => ({
    pedido_id: pedido.id,
    producto_id: it.producto_id,
    descripcion_personalizada: it.descripcion_personalizada ?? null,
    cantidad: it.cantidad,
    precio_unitario: it.precio_unitario
  }))

  const { error: errorItems } = await supabase
    .from('pedido_items')
    .insert(itemsToInsert)

  if (errorItems) {
    errorMsg.value = errorItems.message
    throw errorItems
  }

  // 3) registrar anticipo si viene
  if (typeof input.anticipo === 'number' && input.anticipo > 0) {
    const pagoToInsert = {
      pedido_id: pedido.id,
      monto: input.anticipo,
      metodo: null,
      referencia: null,
      creado_en: new Date().toISOString(),
      es_anticipo: true
    }

    const { error: errorPago } = await supabase.from('pagos').insert(pagoToInsert)
    if (errorPago) {
      errorMsg.value = errorPago.message
      throw errorPago
    }
  }

  // refrescar lista
  await fetchPedidos()
  return pedido
}

async function actualizarEstadoPedido(id: string, estado: EstadoPedido) {
  const { error } = await supabase
    .from('pedidos')
    .update({ estado, updated_at: new Date().toISOString() })
    .eq('id', id)

  if (error) {
    errorMsg.value = error.message
    throw error
  }

  await fetchPedidos()
}

async function eliminarPedido(id: string) {
  const { error } = await supabase
    .from('pedidos')
    .delete()
    .eq('id', id)

  if (error) {
    errorMsg.value = error.message
    throw error
  }

  pedidos.value = pedidos.value.filter(p => p.id !== id)
}

async function actualizarPedidoCompleto(id: string, input: { notas?: string | null; items: PedidoItem[] }) {
  errorMsg.value = null

  // 1) actualizar campos del pedido
  const { error: errorUpdate } = await supabase
    .from('pedidos')
    .update({ notas: input.notas ?? null, updated_at: new Date().toISOString() })
    .eq('id', id)

  if (errorUpdate) {
    errorMsg.value = errorUpdate.message
    throw errorUpdate
  }

  // 2) eliminar items existentes
  const { error: errorDelete } = await supabase.from('pedido_items').delete().eq('pedido_id', id)
  if (errorDelete) {
    errorMsg.value = errorDelete.message
    throw errorDelete
  }

  // 3) insertar nuevos items
  const itemsToInsert = input.items.map(it => ({
    pedido_id: id,
    producto_id: it.producto_id,
    descripcion_personalizada: it.descripcion_personalizada ?? null,
    cantidad: it.cantidad,
    precio_unitario: it.precio_unitario
  }))

  const { error: errorItems } = await supabase.from('pedido_items').insert(itemsToInsert)
  if (errorItems) {
    errorMsg.value = errorItems.message
    throw errorItems
  }

  await fetchPedidos()
}

export function usePedidos() {
  return {
    pedidos,
    loading,
    errorMsg,
    fetchPedidos,
    crearPedido,
    actualizarPedidoCompleto,
    actualizarEstadoPedido,
    eliminarPedido
  }
}
