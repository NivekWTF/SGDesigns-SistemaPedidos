<template>
  <div class="p-6 orders-page">
    <header class="page-header">
      <div>
        <h1 class="page-title">Orders List</h1>
        <p class="page-sub">Here you can find all of your Orders</p>
      </div>
      <!-- header-actions moved below the list title to improve layout */ -->
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
        <div class="stat-num">{{ canceladosCount }}</div>
        <div class="stat-label">Cancelled Orders</div>
      </div>
      <div class="stat-card" v-if="lowStockCount > 0">
        <div class="stat-num">{{ lowStockCount }}</div>
        <div class="stat-label">Productos bajo stock</div>
      </div>
    </section>

    <!-- New order wizard modal rendered when Add Order is clicked -->
    <NewOrderWizard v-if="showNewOrder" :initialPedido="selectedPedido" :key="selectedPedido ? selectedPedido.id : 'new'" @close="showNewOrder = false; selectedPedido = null" @created="onNewCreated" />
    <OrderDetailsModal v-if="showDetails && selectedPedido" :pedido="selectedPedido" @close="showDetails = false; selectedPedido = null" />

    <section class="mt-8 list-section">
      <h2>Listado de pedidos</h2>

      <div class="list-controls" style="display:flex;gap:12px;align-items:center;margin-top:12px;margin-bottom:8px">
        <div style="flex:1;display:flex;gap:12px;align-items:center">
          <div class="search" style="flex:1">
            <input v-model="searchTerm" placeholder="Buscar por nombre, Order ID..." />
          </div>

          <div>
            <select v-model="statusFilter" class="input">
              <option value="ALL">All Status</option>
              <option value="PENDIENTE">PENDIENTE</option>
              <option value="EN_PRODUCCION">EN_PRODUCCION</option>
              <option value="TERMINADO">TERMINADO</option>
              <option value="ENTREGADO">ENTREGADO</option>
              <option value="CANCELADO">CANCELADO</option>
            </select>
          </div>

          <div style="display:flex;gap:8px;align-items:center">
            <input type="date" v-model="startDate" class="input" />
            <span style="color:#666">to</span>
            <input type="date" v-model="endDate" class="input" />
          </div>
        </div>

        <div style="display:flex;gap:8px;align-items:center">
          <button type="button" class="btn-ghost" @click="toggleMoreFilters">More Filter</button>
          <button type="button" class="btn-primary" @click="openNewOrder">+ Add Order</button>
        </div>
      </div>

      <div v-if="showMoreFilters" class="more-filters" style="margin-bottom:12px;padding:10px;border:1px solid #eef2f5;border-radius:8px;background:#fff">
        <label style="display:inline-flex;align-items:center;gap:8px;margin-right:12px"><input type="checkbox" v-model="onlyWithAnticipo" /> Only with anticipo</label>
        <label style="display:inline-flex;align-items:center;gap:8px"><input type="checkbox" v-model="onlyWithNotes" /> Only with notes</label>
      </div>

      <p v-if="loading">Cargando...</p>
      <p v-else-if="errorMsg">⚠️ {{ errorMsg }}</p>

      <div v-else class="orders-table">
        <div class="orders-row header">
          <div>Order ID</div>
          <div>Descripción</div>
          <div>Customer</div>
          <div>Status</div>
          <div>Amount</div>
          <div>Restan</div>
          <div>Actions</div>
        </div>

        <div v-for="p in filteredPedidos" :key="p.id" class="orders-row">
          <div class="order-id">
            <div class="id-main">{{ p.folio || ('#' + p.id.slice(0,8)) }}</div>
            <div class="id-sub">{{ formatDateOnly(p.created_at) }}</div>
          </div>

          <div class="description">{{ formatDescription(p) }}</div>

          <div class="customer">{{ p.clientes?.nombre || 'Sin cliente' }}</div>

          <div class="status">
            <span :class="['badge', statusClass(p.estado)]">{{ p.estado }}</span>
          </div>

          <div class="amount">${{ p.total.toFixed(2) }}</div>

          <div class="remaining">${{ remaining(p).toFixed(2) }}</div>

          <div class="actions">
            <button class="btn-primary" @click="editPedido(p)">Editar</button>
            <div class="menu">
              <button class="btn-menu" @click="toggleMenu(p.id)">⋯</button>
              <div v-if="openMenuId === p.id" class="menu-pop">
                <button @click="viewDetails(p)">Detalles</button>
                <div class="menu-divider"></div>
                <button @click="borrar(p.id)" style="color:#ef4444">Eliminar</button>
                <div class="menu-divider"></div>
                <div class="status-actions">
                  <div class="status-label">Cambiar estado</div>
                  <button class="status-btn" @click="setEstado(p, 'PENDIENTE')">PENDIENTE</button>
                  <button class="status-btn" @click="setEstado(p, 'EN_PRODUCCION')">EN_PRODUCCION</button>
                  <button class="status-btn" @click="setEstado(p, 'TERMINADO')">TERMINADO</button>
                  <button class="status-btn" @click="setEstado(p, 'ENTREGADO')">ENTREGADO</button>
                  <button class="status-btn" @click="setEstado(p, 'CANCELADO')">CANCELAR</button>
                </div>
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
import NewOrderWizard from './NewOrderWizard.vue'
import OrderDetailsModal from './OrderDetailsModal.vue'
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
// details modal
const showDetails = ref(false)
const selectedPedido = ref<any | null>(null)

const statusFilter = ref<'ALL'|'PENDIENTE'|'EN_PRODUCCION'|'TERMINADO'|'ENTREGADO'|'CANCELADO'>('ALL')
const startDate = ref<string | null>(null)
const endDate = ref<string | null>(null)
const showMoreFilters = ref(false)
const onlyWithAnticipo = ref(false)
const onlyWithNotes = ref(false)

function toggleMoreFilters(){ showMoreFilters.value = !showMoreFilters.value }

const filteredPedidos = computed(() => {
  const q = (searchTerm.value || '').toLowerCase().trim()

  return pedidos.value.filter((p) => {
    // text search
    if (q) {
      const idText = (p.folio || p.id || '').toString().toLowerCase()
      const cliente = (p.clientes?.nombre || '').toLowerCase()
      if (!idText.includes(q) && !cliente.includes(q)) return false
    }

    // status filter
    if (statusFilter.value !== 'ALL' && p.estado !== statusFilter.value) return false

    // date range filter (created_at)
    if (startDate.value) {
      const sd = new Date(startDate.value)
      const created = p.created_at ? new Date(p.created_at) : null
      if (!created || created < sd) return false
    }
    if (endDate.value) {
      const ed = new Date(endDate.value)
      // include the full day for endDate
      ed.setHours(23,59,59,999)
      const created = p.created_at ? new Date(p.created_at) : null
      if (!created || created > ed) return false
    }

    // more filters
    if (onlyWithAnticipo.value) {
      const pagosArr = p.pagos || []
      const hasAnt = pagosArr.some((r:any) => !!r.es_anticipo || Number(r.monto) > 0)
      if (!hasAnt) return false
    }
    if (onlyWithNotes.value) {
      if (!p.notas || String(p.notas).trim() === '') return false
    }

    return true
  })
})

const pendientesCount = computed(() => pedidos.value.filter(p => p.estado === 'PENDIENTE').length)
const completadosCount = computed(() => pedidos.value.filter(p => p.estado === 'TERMINADO' || p.estado === 'ENTREGADO').length)
const canceladosCount = computed(() => pedidos.value.filter(p => p.estado === 'CANCELADO').length)

const lowStockCount = computed(() => (productos.value || []).filter((p:any) => typeof p.stock === 'number' && p.stock <= 5).length)

function remaining(p: any) {
  const pagosArr = p.pagos || []
  const paid = pagosArr.reduce((acc: number, r: any) => acc + (Number(r.monto) || 0), 0)
  const total = Number(p.total) || 0
  return Math.max(0, total - paid)
}

function toggleMenu(id: string) {
  openMenuId.value = openMenuId.value === id ? null : id
}

function openNewOrder(){
  selectedPedido.value = null
  showNewOrder.value = true
}

async function onNewCreated(){
  showNewOrder.value = false
  selectedPedido.value = null
  await fetchPedidos()
}

async function viewDetails(p: any) {
  // fetch full pedido (with nested items.productos and pagos) to ensure details show correctly
  try {
    const full = await fetchPedidoById(p.id)
    selectedPedido.value = full
  } catch (err) {
    // fallback to passed object
    selectedPedido.value = p
  }
  showDetails.value = true
  openMenuId.value = null
}

async function editPedido(p: any) {
  // fetch full pedido before opening editor to ensure producto relations are present
  try {
    const full = await fetchPedidoById(p.id)
    selectedPedido.value = full
  } catch (err) {
    selectedPedido.value = p
  }
  showNewOrder.value = true
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

function formatDescription(p: any) {
  const items = p.pedido_items || []
  if (!items || items.length === 0) return '—'
  return items
    .map((it: any) => {
      const name = it.descripcion_personalizada || it.productos?.nombre || 'Item'
      return `${it.cantidad} x ${name}`
    })
    .join(', ')
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

async function setEstado(p: any, nuevoEstado: EstadoPedido | string) {
  try {
    await actualizarEstadoPedido(p.id, nuevoEstado as EstadoPedido)
    openMenuId.value = null
  } catch (err) {
    console.error('Error actualizando estado', err)
    alert('No se pudo actualizar el estado')
  }
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
.search input { width: 80vh ;padding:12px 12px;border:1px solid #ddd;border-radius:6px }
.btn-primary { background:#059669;color:white;padding:8px 12px;border-radius:6px;border:none }
.stats-grid { display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin:12px 0 }
.stat-card { background:#fff;border:1px solid #eee;padding:12px;border-radius:8px }
.stat-num { font-weight:700;font-size:1.1rem }
.stat-label { color:#666 }
.orders-table { margin-top:12px;border-top:1px solid #eee }
.orders-row { display:grid;grid-template-columns: 2fr 3fr 2fr 1fr 1fr 1fr 1fr;align-items:center;padding:12px;border-bottom:1px solid #f3f3f3 }
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
.menu { position: relative }
.menu-pop { position:absolute;background:white;border:1px solid #eee;padding:8px;border-radius:6px;box-shadow:0 4px 16px rgba(0,0,0,0.06);z-index:120;right:0;left:auto;top:36px;min-width:120px;white-space:nowrap }
.menu-divider{height:1px;background:#f1f5f9;margin:8px 0}
.status-actions{display:flex;flex-direction:column;gap:6px}
.status-label{font-weight:700;color:#333;font-size:0.85rem}
.status-btn{background:transparent;border:1px solid #eef2f5;padding:6px 8px;border-radius:6px;text-align:left}
.orders-page { background:#f6f7fb }
.create-section { background:white;padding:12px;border-radius:8px;border:1px solid #eee;margin-bottom:16px }
</style>
