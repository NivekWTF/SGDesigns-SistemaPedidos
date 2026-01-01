<template>
  <div class="p-6 orders-page">
    <header class="page-header">
      <div>
        <h1 class="page-title">Orders List</h1>
        <p class="page-sub">Here you can find all of your Orders</p>
      </div>
      <div class="header-actions">
        <div class="search">
          <input v-model="searchTerm" placeholder="Search by name, Order ID..." />
        </div>
        <button type="button" class="btn-primary" @click="openNewOrder">+ Add Order</button>
      </div>
    </header>

    <section class="stats-grid">
      <div class="stat-card">
        <div class="stat-num">{{ pedidos.length }}</div>
        <div class="stat-label">Total Orders</div>
      </div>
      <div class="stat-card">
        <div class="stat-num">{{ pendientesCount }}</div>
        <div class="stat-label">New Orders</div>
      </div>
      <div class="stat-card">
        <div class="stat-num">{{ completadosCount }}</div>
        <div class="stat-label">Completed Orders</div>
      </div>
      <div class="stat-card">
        <div class="stat-num">{{ canceladosCount }}<<div data-v-7a7a37b1="" class="topbar-inner"><a data-v-7a7a37b1="" href="/pedidos" class="router-link-active router-link-exact-active top-link" aria-current="page">Pedidos</a><a data-v-7a7a37b1="" href="/clientes" class="top-link">Clientes</a><a data-v-7a7a37b1="" href="/productos" class="top-link">Productos</a></div>/div>
        <div class="stat-label">Cancelled Orders</div>
      </div>
    </section>

    <!-- New order modal rendered when Add Order is clicked -->
    <NewOrderForm v-if="showNewOrder" @close="showNewOrder = false" @created="onNewCreated" />

    <section class="mt-8 list-section">
      <h2>Listado de pedidos</h2>

      <p v-if="loading">Cargando...</p>
      <p v-else-if="errorMsg">⚠️ {{ errorMsg }}</p>

      <div v-else class="orders-table">
        <div class="orders-row header">
          <div>Order ID</div>
          <div>Customer</div>
          <div>Status</div>
          <div>Amount</div>
          <div>Actions</div>
        </div>

        <div v-for="p in filteredPedidos" :key="p.id" class="orders-row">
          <div class="order-id">
            <div class="id-main">{{ p.folio || ('#' + p.id.slice(0,8)) }}</div>
            <div class="id-sub">{{ formatDateOnly(p.created_at) }}</div>
          </div>

          <div class="customer">{{ p.clientes?.nombre || 'Sin cliente' }}</div>

          <div class="status">
            <span :class="['badge', statusClass(p.estado)]">{{ p.estado }}</span>
          </div>

          <div class="amount">${{ p.total.toFixed(2) }}</div>

          <div class="actions">
            <button class="btn-delete" @click="borrar(p.id)">Eliminar</button>
            <div class="menu">
              <button class="btn-menu" @click="toggleMenu(p.id)">⋯</button>
              <div v-if="openMenuId === p.id" class="menu-pop">
                <button @click="viewDetails(p)">Details</button>
                <button @click="editPedido(p)">Edit</button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, computed } from 'vue'
import { usePedidos } from '../composables/usePedidos'
import { useFormat } from '../composables/useFormat'
import { useProductos } from '../composables/useProductos'
import { useClientes } from '../composables/useClientes'
import NewOrderForm from './NewOrderForm.vue'
import type { EstadoPedido, PedidoItemInput } from '../types'
import type { Producto } from '../types'

const {
  pedidos,
  loading,
  errorMsg,
  fetchPedidos,
  crearPedido,
  actualizarEstadoPedido,
  eliminarPedido
} = usePedidos()

// Formulario (múltiples ítems) - kept for table edit logic, creation moved to component
const clienteId = ref('')
const notas = ref('')
const anticipo = ref(0)
const items = ref<PedidoItemInput[]>([
  { producto_id: null, descripcion_personalizada: '', cantidad: 1, precio_unitario: 0 }
])

// productos para el select
const { productos, fetchProductos } = useProductos()

// estado editable en la tabla
const estados = ref<Record<string, EstadoPedido>>({} as any)

const { formatDate, formatDateOnly } = useFormat()
const { clientes, fetchClientes } = useClientes()

// UI state
const searchTerm = ref('')
const openMenuId = ref<string | null>(null)

// modal state for new order
const showNewOrder = ref(false)

const filteredPedidos = computed(() => {
  const q = (searchTerm.value || '').toLowerCase().trim()
  if (!q) return pedidos.value
  return pedidos.value.filter((p) => {
    const idText = (p.folio || p.id).toLowerCase()
    const cliente = (p.clientes?.nombre || '').toLowerCase()
    return idText.includes(q) || cliente.includes(q)
  })
})

const pendientesCount = computed(() => pedidos.value.filter(p => p.estado === 'PENDIENTE').length)
const completadosCount = computed(() => pedidos.value.filter(p => p.estado === 'TERMINADO' || p.estado === 'ENTREGADO').length)
const canceladosCount = computed(() => pedidos.value.filter(p => p.estado === 'CANCELADO').length)

function toggleMenu(id: string) {
  openMenuId.value = openMenuId.value === id ? null : id
}

function openNewOrder(){
  showNewOrder.value = true
}

async function onNewCreated(){
  showNewOrder.value = false
  await fetchPedidos()
}

function viewDetails(p: any) {
  // quick details modal - replace with navigation to detail page if available
  alert(JSON.stringify(p, null, 2))
  openMenuId.value = null
}

function editPedido(p: any) {
  // placeholder: you can route to an edit page
  alert('Edit pedido: ' + p.id)
  openMenuId.value = null
}

// removed createFormRef & scrollToForm; creation now handled in NewOrderForm component

onMounted(async () => {
  await fetchPedidos()
  await fetchProductos()
  await fetchClientes()
  // inicializar estados
  estados.value = Object.fromEntries(
    pedidos.value.map((p) => [p.id, (p.estado ?? 'PENDIENTE') as EstadoPedido])
  )
})

// helper for status classes
function statusClass(s?: EstadoPedido) {
  switch (s) {
    case 'PENDIENTE':
      return 'status-pending'
    case 'EN_PRODUCCION':
      return 'status-blue'
    case 'TERMINADO':
      return 'status-gray'
    case 'ENTREGADO':
      return 'status-green'
    case 'CANCELADO':
      return 'status-red'
    default:
      return 'status-gray'
  }
}

function addItem() {
  items.value.push({ producto_id: null, descripcion_personalizada: '', cantidad: 1, precio_unitario: 0 })
}

function removeItem(index: number) {
  if (items.value.length === 1) return
  items.value.splice(index, 1)
}

async function handleCrearPedido() {
  // ensure there's at least one item with valid values
  if (!clienteId.value) {
    alert('El ID de cliente es requerido')
    return
  }

  const payloadItems = items.value.map((it) => ({
    producto_id: it.producto_id,
    cantidad: it.cantidad,
    precio_unitario: it.precio_unitario,
    descripcion_personalizada: it.descripcion_personalizada
  }))

  await crearPedido({
    cliente_id: clienteId.value,
    notas: notas.value,
    items: payloadItems,
    anticipo: anticipo.value > 0 ? anticipo.value : undefined
  })

  // reset form
  clienteId.value = ''
  notas.value = ''
  anticipo.value = 0
  items.value = [{ producto_id: null, descripcion_personalizada: '', cantidad: 1, precio_unitario: 0 }]
}

function onProductChange(idx: number) {
  const item = items.value[idx]
  if (!item) return

  const prodId = item.producto_id
  const prod = (productos.value as Producto[]).find((p) => p.id === prodId)
  if (prod) item.precio_unitario = prod.precio_base
}

async function cambiarEstado(id: string) {
  const nuevoEstado = estados.value[id]
  if (typeof nuevoEstado === 'undefined') {
    // no-op if state not initialized for this pedido; log for debugging
    console.warn(`Pedido ${id} tiene estado indefinido, omitiendo actualización.`)
    return
  }

  await actualizarEstadoPedido(id, nuevoEstado)
}

async function borrar(id: string) {
  if (!confirm('¿Seguro que quieres eliminar este pedido?')) return
  await eliminarPedido(id)
}
</script>

<style scoped>
.page-header { display:flex;justify-content:space-between;align-items:center;margin-bottom:12px }
.page-title { margin:0;font-size:1.25rem }
.page-sub { margin:0;color:#666 }
.header-actions { display:flex;gap:12px;align-items:center }
.search input { padding:8px 12px;border:1px solid #ddd;border-radius:6px }
.btn-primary { background:#059669;color:white;padding:8px 12px;border-radius:6px;border:none }
.stats-grid { display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin:12px 0 }
.stat-card { background:#fff;border:1px solid #eee;padding:12px;border-radius:8px }
.stat-num { font-weight:700;font-size:1.1rem }
.stat-label { color:#666 }
.orders-table { margin-top:12px;border-top:1px solid #eee }
.orders-row { display:grid;grid-template-columns: 2fr 2fr 1fr 1fr 1fr;align-items:center;padding:12px;border-bottom:1px solid #f3f3f3 }
.orders-row.header { font-weight:600;color:#444;background:#fafafa }
.order-id .id-main { font-weight:700 }
.id-sub { font-size:0.85rem;color:#666 }
.customer { padding-left:8px }
.badge { padding:6px 10px;border-radius:999px;color:white;font-weight:600 }
.status-pending { background:#f59e0b }
.status-blue { background:#3b82f6 }
.status-gray { background:#6b7280 }
.status-green { background:#10b981 }
.status-red { background:#ef4444 }
.actions { display:flex;gap:8px;justify-content:flex-end }
.btn-delete { background:#fff;border:1px solid #eee;padding:6px 8px;border-radius:6px }
.btn-menu { background:#fff;border:1px solid #eee;padding:6px 8px;border-radius:6px }
.menu-pop { position:absolute;background:white;border:1px solid #eee;padding:8px;border-radius:6px;box-shadow:0 4px 16px rgba(0,0,0,0.06);z-index:20 }
.orders-page { background:#f6f7fb }
.create-section { background:white;padding:12px;border-radius:8px;border:1px solid #eee;margin-bottom:16px }
</style>
