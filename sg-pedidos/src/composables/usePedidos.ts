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
      pedido_items ( id, producto_id, descripcion_personalizada, cantidad, precio_unitario, subtotal, productos ( nombre ) ),
      pagos ( id, monto )
    `)
    .order('created_at', { ascending: false })

  if (error) {
    errorMsg.value = error.message
  } else {
    pedidos.value = (data as unknown as Pedido[]) || []
  }

  loading.value = false
}

async function fetchPedidoById(id: string) {
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
      pedido_items ( id, producto_id, descripcion_personalizada, cantidad, precio_unitario, subtotal, productos ( id, nombre ) ),
      pagos ( id, monto, creado_en, es_anticipo )
    `)
    .eq('id', id)
    .single()

  if (error) {
    errorMsg.value = error.message
    throw error
  }

  return data as unknown as Pedido
}

async function crearPedido(input: CrearPedidoInput) {
  errorMsg.value = null
  // Prefer RPC: try to call DB function that creates pedido and decrements stock atomically
  try {
    const { data, error } = await supabase.rpc('create_pedido_with_stock', {
      cliente_id: input.cliente_id,
      notas: input.notas ?? null,
      items: input.items,
      anticipo: input.anticipo ?? null
    })

    if (error) {
      // if function not found or other RPC error, rethrow and fallback to client flow
      throw error
    }

    // rpc returns a row with pedido_id
    const pedidoId = (data && Array.isArray(data) && data[0] && (data[0].pedido_id || data[0].create_pedido_with_stock)) ? (data[0].pedido_id || data[0].create_pedido_with_stock) : null

    if (!pedidoId) {
      throw new Error('RPC did not return pedido id')
    }

    // fetch the created pedido with relations (include producto.costo_material)
    const { data: created, error: fetchErr } = await supabase
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
        pedido_items ( id, producto_id, descripcion_personalizada, cantidad, precio_unitario, subtotal, productos ( id, nombre, costo_material ) )
      `)
      .eq('id', pedidoId)
      .single()

    if (fetchErr) {
      errorMsg.value = fetchErr.message
      throw fetchErr
    }

    // after creating pedido, insert expense records for consumed products using mapping
    try {
      const items = (created as any).pedido_items || []
      const gastosToInsert = [] as any[]
      for (const it of items) {
        const cantidad = it.cantidad || 0
        const costo = (it.productos && typeof it.productos.costo_material === 'number') ? it.productos.costo_material : 0
        const monto = costo * cantidad
        if (monto > 0) {
          gastosToInsert.push({
            descripcion: `Gasto por consumo en pedido ${created.id}: ${it.productos?.nombre || it.producto_id}`,
            monto,
            producto_id: it.producto_id,
            referencia: `pedido:${created.id}`,
            meta: { pedido_id: created.id, item_id: it.id, qty: cantidad }
          })
        }
      }

      if (gastosToInsert.length) await supabase.from('gastos').insert(gastosToInsert)
    } catch (gErr) {
      console.warn('Failed to insert gastos for pedido', gErr)
    }

    await fetchPedidos()
    return created
  } catch (rpcErr) {
    // fallback: rethrow so client-side caller can handle, or optionally you could keep the previous non-atomic flow here.
    errorMsg.value = rpcErr?.message ?? String(rpcErr)
    throw rpcErr
  }
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
