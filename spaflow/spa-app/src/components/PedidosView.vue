<template>
  <div class="p-6 orders-page">
    <header class="page-header">
      <div>
        <h1 class="page-title">Pedidos</h1>
        <p class="page-sub">Aquí puedes ver todos tus pedidos</p>
      </div>
    </header>

    <section class="stats-grid">
      <div class="stat-card">
        <div class="stat-num">{{ pedidos.length }}</div>
        <div class="stat-label">Total pedidos</div>
      </div>

      <div class="stat-card">
        <div class="stat-num">{{ pendientesCount }}</div>
        <div class="stat-label">Pendientes</div>
      </div>

      <div class="stat-card">
        <div class="stat-num">{{ completadosCount }}</div>
        <div class="stat-label">Completados</div>
      </div>

      <div class="stat-card">
        <div class="stat-num">{{ canceladosCount }}</div>
        <div class="stat-label">Cancelados</div>
      </div>
      <div class="stat-card" v-if="lowStockCount > 0">
        <div class="stat-num">{{ lowStockCount }}</div>
        <div class="stat-label">Productos bajo stock</div>
      </div>
    </section>

    <!-- New order wizard modal rendered when Add Order is clicked -->
    <NewOrderWizard v-if="showNewOrder" :initialPedido="selectedPedido" :key="selectedPedido ? selectedPedido.id : 'new'" @close="showNewOrder = false; selectedPedido = null" @created="onNewCreated" />
    <OrderDetailsModal v-if="showDetails && selectedPedido" :pedido="selectedPedido" @close="showDetails = false; selectedPedido = null" @updated="onPaymentUpdated" />

    <!-- Modal de anticipo / pago parcial -->
    <div v-if="showAnticipo" class="payment-overlay" @click.self="showAnticipo = false">
      <div class="payment-modal">
        <div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:10px">
          <h3 style="margin:0;font-size:1rem">Registrar pago / anticipo</h3>
          <button class="btn-ghost" style="padding:4px 8px;font-size:1rem" @click="showAnticipo = false">✕</button>
        </div>
        <p style="font-size:0.875rem;margin:0 0 2px">
          <strong>{{ anticipoModalPedido?.folio || '#' + (anticipoModalPedido?.id||'').slice(0,8) }}</strong>
          · {{ anticipoModalPedido?.clientes?.nombre }}
        </p>
        <p style="font-size:0.875rem;margin:0 0 14px;color:#64748b">
          Total: {{ formatCurrency(anticipoModalPedido?.total || 0) }}
          &nbsp;·&nbsp;
          Restante: <strong style="color:#dc2626">{{ formatCurrency(anticipoRemaining) }}</strong>
        </p>

        <label style="display:block;font-weight:600;font-size:0.875rem;margin-bottom:4px">Monto a pagar</label>
        <input
          v-model.number="anticipoMonto"
          type="number"
          min="0.01"
          :max="anticipoRemaining"
          step="0.01"
          class="input"
          style="width:100%;box-sizing:border-box;margin-bottom:14px;padding:8px 10px;border-radius:8px"
        />

        <label style="display:block;font-weight:600;font-size:0.875rem;margin-bottom:8px">Método de pago</label>
        <div style="display:flex;gap:8px;justify-content:center;margin-bottom:16px">
          <button :class="['payment-option', anticipoMethod === 'Efectivo' && 'payment-option-active']" style="padding:10px 14px;font-size:0.9rem" @click="anticipoMethod = 'Efectivo'">💵 Efectivo</button>
          <button :class="['payment-option', anticipoMethod === 'Transferencia' && 'payment-option-active']" style="padding:10px 14px;font-size:0.9rem" @click="anticipoMethod = 'Transferencia'">🏦 Transferencia</button>
          <button :class="['payment-option', anticipoMethod === 'Tarjeta' && 'payment-option-active']" style="padding:10px 14px;font-size:0.9rem" @click="anticipoMethod = 'Tarjeta'">💳 Tarjeta</button>
        </div>

        <div style="display:flex;gap:8px;justify-content:flex-end">
          <button class="btn-ghost" @click="showAnticipo = false">Cancelar</button>
          <button
            class="btn-primary"
            :disabled="!anticipoMethod || !anticipoMonto || anticipoMonto <= 0 || anticipoPaying"
            @click="confirmAnticipo"
          >
            {{ anticipoPaying ? 'Registrando...' : 'Registrar pago' }}
          </button>
        </div>
      </div>
    </div>

    <!-- Modal para seleccionar método de pago al entregar -->
    <div v-if="showPaymentModal" class="payment-overlay" @click.self="showPaymentModal = false">
      <div class="payment-modal">
        <h3 style="margin:0 0 12px">Método de pago</h3>
        <p style="color:#666;margin:0 0 16px;font-size:0.9rem">
          Selecciona el método de pago para marcar como entregado.
          <br />Restante: <strong>{{ formatCurrency(paymentModalRemaining) }}</strong>
        </p>
        <div style="display:flex;gap:12px;justify-content:center;margin-bottom:16px">
          <button
            :class="['payment-option', paymentMethod === 'Efectivo' && 'payment-option-active']"
            @click="paymentMethod = 'Efectivo'"
          >
            💵 Efectivo
          </button>
          <button
            :class="['payment-option', paymentMethod === 'Transferencia' && 'payment-option-active']"
            @click="paymentMethod = 'Transferencia'"
          >
            🏦 Transferencia
          </button>
          <button
            :class="['payment-option', paymentMethod === 'Tarjeta' && 'payment-option-active']"
            @click="paymentMethod = 'Tarjeta'"
          >
            💳 Tarjeta
          </button>
        </div>
        <div style="display:flex;gap:8px;justify-content:flex-end">
          <button class="btn-ghost" @click="showPaymentModal = false">Cancelar</button>
          <button class="btn-primary" :disabled="!paymentMethod" @click="confirmEntregado">Confirmar entrega</button>
        </div>
      </div>
    </div>

    <section class="mt-8 list-section">
      <div v-if="infoMsg" class="info-toast">{{ infoMsg }}</div>
      <h2>Listado de pedidos</h2>

      <div class="list-controls" style="display:flex;gap:12px;align-items:center;margin-top:12px;margin-bottom:8px">
        <div style="flex:1;display:flex;gap:12px;align-items:center">
          <div class="search" style="flex:1">
            <input v-model="searchTerm" placeholder="Buscar por nombre, ID de pedido..." />
          </div>

          <div>
            <select v-model="statusFilter" class="input">
              <option value="ALL">Todos los estados</option>
              <option value="PENDIENTE">PENDIENTE</option>
              <option value="EN_PRODUCCION">EN_PRODUCCION</option>
              <option value="TERMINADO">TERMINADO</option>
              <option value="ENTREGADO">ENTREGADO</option>
              <option value="CANCELADO">CANCELADO</option>
            </select>
          </div>

            <div style="display:flex;gap:8px;align-items:center">
            <input type="date" v-model="startDate" class="input" />
            <span style="color:#666">a</span>
            <input type="date" v-model="endDate" class="input" />
          </div>
        </div>

        <div style="display:flex;gap:8px;align-items:center">
          <button type="button" class="btn-ghost" @click="toggleMoreFilters">Más filtros</button>
          <button type="button" class="btn-primary" @click="openNewOrder">+ Nuevo pedido</button>
        </div>
      </div>

      <div v-if="showMoreFilters" class="more-filters" style="margin-bottom:12px;padding:10px;border:1px solid #eef2f5;border-radius:8px;background:#fff">
        <label style="display:inline-flex;align-items:center;gap:8px;margin-right:12px"><input type="checkbox" v-model="onlyWithAnticipo" /> Only with anticipo</label>
        <label style="display:inline-flex;align-items:center;gap:8px"><input type="checkbox" v-model="onlyWithNotes" /> Only with notes</label>
      </div>

      <p v-if="loading">Cargando...</p>
      <p v-else-if="errorMsg">⚠️ {{ errorMsg }}</p>

      <div v-else class="orders-table-wrapper">
        <div class="orders-table">
          <div class="orders-row header">
            <div>ID Pedido</div>
            <div>Descripción</div>
            <div>Cliente</div>
            <div>Estado</div>
            <div>Importe</div>
            <div>Restan</div>
            <div>Acciones</div>
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

            <div class="amount">{{ formatCurrency(Number(p.total) || 0) }}</div>

            <div class="remaining">{{ formatCurrency(remaining(p)) }}</div>

            <div class="actions">
              <button class="btn-primary" @click="editPedido(p)">Editar</button>
              <button v-if="remaining(p) > 0" class="btn-pay-row" @click.stop="openAnticipo(p)">💳 Pagar</button>
              <div class="menu">
                <button class="btn-menu" @click="toggleMenu(p.id)">⋯</button>
                <div v-if="openMenuId === p.id" class="menu-pop">
                  <button @click="viewDetails(p)">Detalles</button>
                  <template v-if="isAdmin">
                    <div class="menu-divider"></div>
                    <button @click="borrar(p.id)" style="color:#ef4444">Eliminar</button>
                  </template>
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
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, computed } from 'vue'
import { usePedidos } from '../composables/usePedidos'
import { useAuth } from '../composables/useAuth'
import { useFormat } from '../composables/useFormat'
import { useProductos } from '../composables/useProductos'
import NewOrderWizard from './NewOrderWizard.vue'
import OrderDetailsModal from './OrderDetailsModal.vue'
import type { EstadoPedido } from '../types'

const {
  pedidos,
  loading,
  errorMsg,
  fetchPedidos,
  fetchPedidoById,
  actualizarEstadoPedido,
  registrarPago,
  eliminarPedido
} = usePedidos()

const { isAdmin } = useAuth()

// productos para el select
const { productos, fetchProductos } = useProductos()

const { formatDateOnly, formatCurrency } = useFormat()

// UI state
const searchTerm = ref('')
const openMenuId = ref<string | null>(null)

// modal state for new order
const showNewOrder = ref(false)
// details modal
const showDetails = ref(false)
const selectedPedido = ref<any | null>(null)

const statusFilter = ref<'ALL'|'PENDIENTE'|'EN_PRODUCCION'|'TERMINADO'|'ENTREGADO'|'CANCELADO'>('ALL')
const infoMsg = ref<string | null>(null)
const startDate = ref<string | null>(null)
const endDate = ref<string | null>(null)
const showMoreFilters = ref(false)
const onlyWithAnticipo = ref(false)
const onlyWithNotes = ref(false)

function parseLocalDate(dateStr: string, endOfDay = false): Date {
  const [year = 0, month = 1, day = 1] = dateStr.split('-').map((v) => Number(v))
  if (endOfDay) return new Date(year, month - 1, day, 23, 59, 59, 999)
  return new Date(year, month - 1, day, 0, 0, 0, 0)
}

// Payment method modal state
const showPaymentModal = ref(false)
const paymentMethod = ref<'Efectivo' | 'Transferencia' | 'Tarjeta' | ''>('')
const paymentModalPedido = ref<any | null>(null)
const paymentModalRemaining = computed(() => {
  if (!paymentModalPedido.value) return 0
  return remaining(paymentModalPedido.value)
})

// Anticipo / partial payment modal state
const showAnticipo = ref(false)
const anticipoModalPedido = ref<any | null>(null)
const anticipoMonto = ref(0)
const anticipoMethod = ref<'Efectivo' | 'Transferencia' | 'Tarjeta' | ''>('')
const anticipoPaying = ref(false)

const anticipoRemaining = computed(() => {
  if (!anticipoModalPedido.value) return 0
  return remaining(anticipoModalPedido.value)
})

function openAnticipo(p: any) {
  anticipoModalPedido.value = p
  anticipoMonto.value = Number(remaining(p).toFixed(2))
  anticipoMethod.value = ''
  showAnticipo.value = true
  openMenuId.value = null
}

async function confirmAnticipo() {
  const p = anticipoModalPedido.value
  if (!p || !anticipoMethod.value || !anticipoMonto.value || anticipoMonto.value <= 0) return
  anticipoPaying.value = true
  try {
    await registrarPago(p.id, anticipoMonto.value, anticipoMethod.value)
    showAnticipo.value = false
    anticipoModalPedido.value = null
    anticipoMonto.value = 0
    anticipoMethod.value = ''
    infoMsg.value = 'Pago registrado correctamente'
    setTimeout(() => { infoMsg.value = null }, 2500)
    await fetchPedidos()
  } catch (err) {
    console.error('Error registrando anticipo', err)
    alert('No se pudo registrar el pago')
  } finally {
    anticipoPaying.value = false
  }
}

async function onPaymentUpdated() {
  await fetchPedidos()
}

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
      const sd = parseLocalDate(startDate.value)
      const created = p.created_at ? new Date(p.created_at) : null
      if (!created || created < sd) return false
    }
    if (endDate.value) {
      const ed = parseLocalDate(endDate.value, true)
      const created = p.created_at ? new Date(p.created_at) : null
      if (!created || created > ed) return false
    }

    // more filters
    if (onlyWithAnticipo.value) {
      const pagosArr = (p as any).pagos || []
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

function fmtQty(n: number) {
  if (!Number.isFinite(n)) return '0'
  if (Number.isInteger(n)) return String(n)
  return n.toFixed(2).replace(/\.?0+$/, '')
}

function formatDescription(p: any) {
  const items = p.pedido_items || []
  if (!items || items.length === 0) return '—'
  return items
    .map((it: any) => {
      const name = it.descripcion_personalizada || it.productos?.nombre || 'Item'
      return `${fmtQty(Number(it.cantidad))} x ${name}`
    })
    .join(', ')
}

async function setEstado(p: any, nuevoEstado: EstadoPedido | string) {
  // If marking as ENTREGADO, show payment method modal first
  if (nuevoEstado === 'ENTREGADO') {
    paymentModalPedido.value = p
    paymentMethod.value = ''
    showPaymentModal.value = true
    openMenuId.value = null
    return
  }

  try {
    await actualizarEstadoPedido(p.id, nuevoEstado as EstadoPedido)
    openMenuId.value = null
    infoMsg.value = 'Pedido actualizado'
    setTimeout(()=>{ infoMsg.value = null }, 2500)
  } catch (err) {
    console.error('Error actualizando estado', err)
    alert('No se pudo actualizar el estado')
  }
}

async function confirmEntregado() {
  const p = paymentModalPedido.value
  if (!p || !paymentMethod.value) return

  try {
    // Register the remaining balance as a payment with the chosen method
    const resto = remaining(p)
    if (resto > 0) {
      await registrarPago(p.id, resto, paymentMethod.value)
    }

    await actualizarEstadoPedido(p.id, 'ENTREGADO')
    showPaymentModal.value = false
    paymentModalPedido.value = null
    paymentMethod.value = ''
    infoMsg.value = 'Pedido entregado'
    setTimeout(() => { infoMsg.value = null }, 2500)
    // Refetch to update payment info in the list
    await fetchPedidos()
  } catch (err) {
    console.error('Error entregando pedido', err)
    alert('No se pudo entregar el pedido')
  }
}

async function borrar(id: string) {
  if (!isAdmin.value) {
    openMenuId.value = null
    alert('Solo un administrador puede eliminar pedidos')
    return
  }

  if (!confirm('¿Seguro que quieres eliminar este pedido?')) return
  await eliminarPedido(id)
}
</script>

<style scoped>
.page-header { display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;flex-wrap:wrap;gap:8px }
.page-title { margin:0;font-size:1.25rem }
.page-sub { margin:0;color:#666 }
.header-actions { display:flex;gap:12px;align-items:center;flex-wrap:wrap }
.search input { width:100%;max-width:400px;padding:12px 12px;border:1px solid #ddd;border-radius:6px;box-sizing:border-box }
.btn-primary { background:#059669;color:white;padding:8px 12px;border-radius:6px;border:none;white-space:nowrap }
.stats-grid { display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:12px;margin:12px 0 }
.stat-card { background:#fff;border:1px solid #eee;padding:12px;border-radius:8px }
.stat-num { font-weight:700;font-size:1.1rem }
.stat-label { color:#666 }
.orders-table-wrapper { margin-top:12px;border-top:1px solid #eee;overflow:visible;position:relative }
.orders-table { overflow:visible;position:relative;min-width:700px }
.orders-row { display:grid;grid-template-columns: 2fr 3fr 2fr 1fr 1fr 1fr 1fr;align-items:center;padding:12px;border-bottom:1px solid #f3f3f3;min-width:700px }
.orders-row.header { font-weight:600;color:#444;background:#fafafa }

@media (max-width: 768px) {
  .page-header { flex-direction:column;align-items:flex-start }
  .header-actions { width:100% }
  .search { width:100% }
  .search input { max-width:none;width:100% }
  .stats-grid { grid-template-columns:repeat(2,1fr);gap:8px }
  .list-controls { flex-direction:column!important;align-items:stretch!important }
}
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
.menu-pop { position:absolute;background:white;border:1px solid #eee;padding:8px;border-radius:6px;box-shadow:0 4px 16px rgba(0,0,0,0.06);z-index:120;right:0;left:auto;top:36px;min-width:120px;white-space:nowrap}
.menu-divider{height:1px;background:#f1f5f9;margin:8px 0}
.status-actions{display:flex;flex-direction:column;gap:6px}
.status-label{font-weight:700;color:#333;font-size:0.85rem}
.status-btn{background:transparent;border:1px solid #eef2f5;padding:6px 8px;border-radius:6px;text-align:left}
.orders-page { background:#f6f7fb }
.create-section { background:white;padding:12px;border-radius:8px;border:1px solid #eee;margin-bottom:16px }
.info-toast{background:#ecfdf5;border:1px solid #bbf7d0;color:#065f46;padding:8px 12px;border-radius:8px;margin-bottom:8px}

/* Payment method modal */
.payment-overlay{position:fixed;inset:0;background:rgba(0,0,0,0.4);display:flex;align-items:center;justify-content:center;z-index:200}
.payment-modal{background:#fff;border-radius:12px;padding:24px;width:100%;max-width:420px;box-shadow:0 8px 32px rgba(0,0,0,0.12)}
.payment-option{background:#f6f7fb;border:2px solid #e5e7eb;padding:14px 24px;border-radius:10px;font-size:1rem;cursor:pointer;transition:all 0.15s}
.payment-option:hover{border-color:#059669;background:#ecfdf5}
.payment-option-active{border-color:#059669;background:#ecfdf5;font-weight:700}
.btn-ghost{background:transparent;border:1px solid #ddd;padding:8px 14px;border-radius:6px;cursor:pointer}
.btn-pay-row{background:#eff6ff;border:1px solid #bfdbfe;color:#2563eb;padding:6px 10px;border-radius:6px;font-weight:600;font-size:0.85rem}
.btn-pay-row:hover{background:#dbeafe}

/* Dark mode */
:is(.dark) .orders-page{background:transparent}
:is(.dark) .page-title{color:#e2e8f0}
:is(.dark) .page-sub{color:#94a3b8}
:is(.dark) .stat-card{background:#111c2e;border-color:#1e293b}
:is(.dark) .stat-num{color:#e2e8f0}
:is(.dark) .stat-label{color:#94a3b8}
:is(.dark) .search input{background:#0f1729;border-color:#334155;color:#e2e8f0}
:is(.dark) .search input::placeholder{color:#475569}
:is(.dark) .input{background:#0f1729;border-color:#334155;color:#e2e8f0}
:is(.dark) .orders-table-wrapper{border-top-color:#1e293b}
:is(.dark) .orders-row{border-bottom-color:#1e293b;color:#cbd5e1}
:is(.dark) .orders-row.header{background:#0f1729;color:#94a3b8}
:is(.dark) .order-id .id-main{color:#e2e8f0}
:is(.dark) .id-sub{color:#94a3b8}
:is(.dark) .description{color:#94a3b8}
:is(.dark) .customer{color:#cbd5e1}
:is(.dark) .amount{color:#e2e8f0}
:is(.dark) .remaining{color:#f59e0b}
:is(.dark) .btn-delete{background:#0f1729;border-color:#334155;color:#cbd5e1}
:is(.dark) .btn-menu{background:#0f1729;border-color:#334155;color:#cbd5e1}
:is(.dark) .menu-pop{background:#111c2e;border-color:#1e293b;box-shadow:0 4px 16px rgba(0,0,0,0.3)}
:is(.dark) .menu-pop button{color:#cbd5e1}
:is(.dark) .menu-divider{background:#1e293b}
:is(.dark) .status-label{color:#94a3b8}
:is(.dark) .status-btn{border-color:#334155;color:#cbd5e1}
:is(.dark) .status-btn:hover{background:#1e293b}
:is(.dark) .create-section{background:#111c2e;border-color:#1e293b}
:is(.dark) .info-toast{background:#052e16;border-color:#064e3b;color:#6ee7b7}
:is(.dark) .btn-ghost{border-color:#334155;color:#cbd5e1}
:is(.dark) .btn-ghost:hover{background:#1e293b}
:is(.dark) .btn-pay-row{background:#1e3a5f;border-color:#1d4ed8;color:#93c5fd}
:is(.dark) .btn-pay-row:hover{background:#1e40af}
:is(.dark) .more-filters{background:#111c2e !important;border-color:#1e293b !important;color:#cbd5e1}
:is(.dark) .payment-overlay{background:rgba(0,0,0,0.6)}
:is(.dark) .payment-modal{background:#111c2e;box-shadow:0 8px 32px rgba(0,0,0,0.3)}
:is(.dark) .payment-modal h3{color:#e2e8f0}
:is(.dark) .payment-modal p{color:#94a3b8}
:is(.dark) .payment-modal .input{background:#0f1729;border-color:#334155;color:#e2e8f0}
:is(.dark) .payment-modal label{color:#cbd5e1}
:is(.dark) .payment-option{background:#0f1729;border-color:#334155;color:#cbd5e1}
:is(.dark) .payment-option:hover{border-color:#059669;background:#052e16}
:is(.dark) .payment-option-active{border-color:#059669;background:#052e16}
</style>
