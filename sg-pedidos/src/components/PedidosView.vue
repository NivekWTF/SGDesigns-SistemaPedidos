<template>
  <div class="p-6 orders-page">
    <header class="page-header">
      <div>
        <h1 class="page-title">Pedidos</h1>
        <p class="page-sub">Aquí puedes ver todos tus pedidos</p>
      </div>
    </header>

    <template v-if="loading">
      <section class="stats-grid">
        <SkeletonLoader variant="card" :count="4" />
      </section>
    </template>
    <template v-else>
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
    </template>

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
      <h2 style="margin-bottom: 16px;">Listado de pedidos</h2>

      <div class="list-controls">
        <div class="filters-row">
          <div class="search">
            <input v-model="searchTerm" placeholder="Buscar por nombre, ID, descripción..." />
          </div>

          <div class="status-select-wrap">
            <select v-model="statusFilter" class="input">
              <option value="ALL">Todos los estados</option>
              <option value="PENDIENTE">PENDIENTE</option>
              <option value="EN_PRODUCCION">EN_PRODUCCION</option>
              <option value="TERMINADO">TERMINADO</option>
              <option value="ENTREGADO">ENTREGADO</option>
              <option value="CANCELADO">CANCELADO</option>
            </select>
          </div>

          <div class="date-filters">
            <input type="date" v-model="startDate" class="input" />
            <span style="color:#666">a</span>
            <input type="date" v-model="endDate" class="input" />
          </div>
        </div>

        <div class="actions-row">
          <button type="button" class="btn-ghost" @click="toggleMoreFilters">Más filtros</button>
          <button type="button" class="btn-primary" @click="openNewOrder">+ Nuevo pedido</button>
        </div>
      </div>

      <div v-if="showMoreFilters" class="more-filters" style="margin-bottom:12px;padding:10px;border:1px solid #eef2f5;border-radius:8px;background:#fff">
        <label style="display:inline-flex;align-items:center;gap:8px;margin-right:12px"><input type="checkbox" v-model="onlyWithAnticipo" /> Solo con anticipo</label>
        <label style="display:inline-flex;align-items:center;gap:8px"><input type="checkbox" v-model="onlyWithNotes" /> Solo con notas</label>
      </div>

      <template v-if="loading">
        <div class="orders-table-wrapper">
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
            <SkeletonLoader variant="table-row" :count="6" :columns="7" />
          </div>
        </div>
      </template>
      <p v-else-if="errorMsg">⚠️ {{ errorMsg }}</p>

      <!-- ===== Desktop table view (hidden on mobile) ===== -->
      <div v-else class="orders-table-wrapper desktop-only">
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

          <div v-for="p in paginatedPedidos" :key="p.id" class="orders-row">
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

      <!-- ===== Mobile card view (hidden on desktop) ===== -->
      <div v-if="!loading && !errorMsg" class="mobile-cards-container mobile-only">
        <div v-if="paginatedPedidos.length === 0" class="empty-state">
          <span class="empty-icon">📋</span>
          <p>No se encontraron pedidos</p>
        </div>

        <div v-for="p in paginatedPedidos" :key="'card-' + p.id" class="order-card" @click="viewDetails(p)">
          <!-- Card header -->
          <div class="card-header">
            <div class="card-id-date">
              <span class="card-folio">{{ p.folio || ('#' + p.id.slice(0,8)) }}</span>
              <span class="card-date">📅 {{ formatDateOnly(p.created_at) }}</span>
            </div>
            <span :class="['badge', statusClass(p.estado)]">{{ p.estado }}</span>
          </div>

          <!-- Card body -->
          <div class="card-body">
            <div class="card-row">
              <span class="card-label">👤 Cliente</span>
              <span class="card-value card-client">{{ p.clientes?.nombre || 'Sin cliente' }}</span>
            </div>
            <div class="card-row">
              <span class="card-label">📝 Descripción</span>
              <span class="card-value card-desc">{{ formatDescription(p) }}</span>
            </div>
            <div class="card-row">
              <span class="card-label">📦 Cantidad</span>
              <span class="card-value">{{ totalItemsQty(p) }} item{{ totalItemsQty(p) !== 1 ? 's' : '' }}</span>
            </div>
          </div>

          <!-- Card footer -->
          <div class="card-footer">
            <div class="card-totals">
              <div class="card-total">
                <span class="card-total-label">Total</span>
                <span class="card-total-value">{{ formatCurrency(Number(p.total) || 0) }}</span>
              </div>
              <div v-if="remaining(p) > 0" class="card-remaining">
                <span class="card-total-label">Restante</span>
                <span class="card-total-value remaining-val">{{ formatCurrency(remaining(p)) }}</span>
              </div>
            </div>
            <div class="card-actions" @click.stop>
              <button class="card-btn card-btn-edit" @click="editPedido(p)">✏️ Editar</button>
              <button v-if="remaining(p) > 0" class="card-btn card-btn-pay" @click="openAnticipo(p)">💳 Pagar</button>
              <button class="card-btn card-btn-menu" @click="toggleMenu(p.id)">⋯</button>
              <div v-if="openMenuId === p.id" class="card-menu-pop">
                <button @click="viewDetails(p)">📄 Ver detalles</button>
                <template v-if="isAdmin">
                  <div class="menu-divider"></div>
                  <button @click="borrar(p.id)" style="color:#ef4444">🗑️ Eliminar</button>
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

      <!-- ===== Pagination controls ===== -->
      <div v-if="!loading && !errorMsg && totalPages > 1" class="pagination">
        <button class="page-btn" :disabled="currentPage === 1" @click="goToPage(1)">
          «
        </button>
        <button class="page-btn" :disabled="currentPage === 1" @click="goToPage(currentPage - 1)">
          ‹
        </button>

        <template v-for="pg in visiblePages" :key="pg">
          <span v-if="pg === '....'" class="page-ellipsis">…</span>
          <button v-else :class="['page-btn', { active: pg === currentPage }]" @click="goToPage(pg as number)">
            {{ pg }}
          </button>
        </template>

        <button class="page-btn" :disabled="currentPage === totalPages" @click="goToPage(currentPage + 1)">
          ›
        </button>
        <button class="page-btn" :disabled="currentPage === totalPages" @click="goToPage(totalPages)">
          »
        </button>

        <span class="page-info">{{ currentPage }} / {{ totalPages }} · {{ filteredPedidos.length }} pedidos</span>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref, computed, watch } from 'vue'
import { usePedidos } from '../composables/usePedidos'
import { useAuth } from '../composables/useAuth'
import { useFormat } from '../composables/useFormat'
import { useProductos } from '../composables/useProductos'
import NewOrderWizard from './NewOrderWizard.vue'
import OrderDetailsModal from './OrderDetailsModal.vue'
import SkeletonLoader from './ui/SkeletonLoader.vue'
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

    // --- Actualizar estado local sin refetch ---
    const idx = pedidos.value.findIndex((x: any) => x.id === p.id)
    if (idx !== -1) {
      const current = pedidos.value[idx] as any
      const nuevoPago = { id: crypto.randomUUID(), monto: anticipoMonto.value, metodo: anticipoMethod.value, es_anticipo: true, referencia: null, creado_en: new Date().toISOString() }
      pedidos.value[idx] = {
        ...current,
        pagos: [...(current.pagos || []), nuevoPago]
      }
    }

    showAnticipo.value = false
    anticipoModalPedido.value = null
    anticipoMonto.value = 0
    anticipoMethod.value = ''
    infoMsg.value = 'Pago registrado correctamente ✓'
    setTimeout(() => { infoMsg.value = null }, 2500)
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
      const desc = formatDescription(p).toLowerCase()
      if (!idText.includes(q) && !cliente.includes(q) && !desc.includes(q)) return false
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

// ── Pagination ──
const PAGE_SIZE = 20
const currentPage = ref(1)

// Reset to page 1 whenever filters change
watch([searchTerm, statusFilter, startDate, endDate, onlyWithAnticipo, onlyWithNotes], () => {
  currentPage.value = 1
})

const totalPages = computed(() => Math.max(1, Math.ceil(filteredPedidos.value.length / PAGE_SIZE)))

const paginatedPedidos = computed(() => {
  const start = (currentPage.value - 1) * PAGE_SIZE
  return filteredPedidos.value.slice(start, start + PAGE_SIZE)
})

function goToPage(page: number) {
  currentPage.value = Math.max(1, Math.min(page, totalPages.value))
  // Scroll to top of list section
  const el = document.querySelector('.list-section')
  if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' })
}

// Visible page numbers with ellipsis
const visiblePages = computed(() => {
  const total = totalPages.value
  const current = currentPage.value
  if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1)

  const pages: (number | string)[] = []
  pages.push(1)
  if (current > 3) pages.push('....')
  for (let i = Math.max(2, current - 1); i <= Math.min(total - 1, current + 1); i++) {
    pages.push(i)
  }
  if (current < total - 2) pages.push('....')
  pages.push(total)
  return pages
})

function totalItemsQty(p: any): number {
  const items = p.pedido_items || []
  return items.reduce((acc: number, it: any) => acc + (Number(it.cantidad) || 0), 0)
}

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

    // --- Actualizar estado local sin refetch para no reiniciar la UI ---
    const idx = pedidos.value.findIndex((x: any) => x.id === p.id)
    if (idx !== -1) {
      const current = pedidos.value[idx] as any
      const nuevoPago = resto > 0
        ? [{ id: crypto.randomUUID(), monto: resto, metodo: paymentMethod.value, es_anticipo: false, referencia: null, creado_en: new Date().toISOString() }]
        : []
      pedidos.value[idx] = {
        ...current,
        estado: 'ENTREGADO',
        updated_at: new Date().toISOString(),
        pagos: [...(current.pagos || []), ...nuevoPago]
      }
    }

    showPaymentModal.value = false
    paymentModalPedido.value = null
    paymentMethod.value = ''
    infoMsg.value = 'Pedido entregado ✓'
    setTimeout(() => { infoMsg.value = null }, 2500)
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
.btn-primary { background:#059669;color:white;padding:8px 12px;border-radius:6px;border:none;white-space:nowrap;font-weight:500;transition:all 0.2s }
.btn-primary:hover { background:#047857 }
.stats-grid { display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:12px;margin:12px 0 }
.stat-card { background:#fff;border:1px solid #eee;padding:12px;border-radius:8px;box-shadow:0 1px 3px rgba(0,0,0,0.02) }
.stat-num { font-weight:700;font-size:1.25rem;color:#0f172a }
.stat-label { color:#64748b;font-size:0.85rem }

/* Responsive list controls */
.list-controls { display:flex; gap:12px; align-items:center; margin-top:16px; margin-bottom:16px; justify-content:space-between; flex-wrap:wrap; }
.filters-row { display:flex; gap:12px; align-items:center; flex:1; flex-wrap:wrap; }
.search { flex: 1; min-width: 250px; }
.search input { width:100%;padding:10px 14px;border:1px solid #cbd5e1;border-radius:8px;box-sizing:border-box;font-size:0.95rem;transition:border-color 0.2s }
.search input:focus { outline:none; border-color:#059669; box-shadow:0 0 0 3px rgba(5,150,105,0.1) }
.status-select-wrap { min-width: 150px; }
.status-select-wrap select { width:100%;padding:10px 14px;border:1px solid #cbd5e1;border-radius:8px;font-size:0.95rem;background:#fff }
.date-filters { display:flex; gap:8px; align-items:center; }
.date-filters input { padding:8px 10px;border:1px solid #cbd5e1;border-radius:8px;font-size:0.9rem }
.actions-row { display:flex; gap:8px; align-items:center; }

.orders-table-wrapper { 
  margin-top:16px;
  background:#fff;
  border:1px solid #eef2f5;
  border-radius:12px;
  overflow-x:auto; /* Fix para que la tabla no rompa el width de la pagina completa */
  box-shadow:0 2px 8px rgba(0,0,0,0.02);
  width:100%;
}
.orders-table { 
  overflow:visible;
  position:relative;
  min-width:1150px;
  padding-bottom:120px; /* Espacio para los menus desplegables */
}
.orders-row { 
  display:grid;
  grid-template-columns: 1.2fr 2.5fr 1.5fr auto 1fr 1fr 240px;
  align-items:center;
  padding:14px 16px;
  border-bottom:1px solid #f1f5f9;
  gap:12px;
  transition:background-color 0.15s;
}
.orders-row:hover:not(.header) { background:#f8fafc; }
.orders-row.header { 
  font-weight:600;
  color:#64748b;
  background:#f8fafc;
  text-transform:uppercase;
  font-size:0.75rem;
  letter-spacing:0.05em;
  border-bottom:2px solid #eef2f5;
  border-radius:12px 12px 0 0;
}

@media (max-width: 768px) {
  .page-header { flex-direction:column;align-items:flex-start }
  .header-actions { width:100% }
  .stats-grid { grid-template-columns:repeat(2,1fr);gap:8px }
  .list-controls { flex-direction:column; align-items:stretch; }
  .filters-row { flex-direction:column; align-items:stretch; gap:10px; }
  .search { min-width:100%; width:100%; }
  .status-select-wrap { width:100%; }
  .status-select-wrap select { width:100%; }
  .date-filters { display:none !important; /* Ocultar en móvil para más espacio */ }
  .actions-row { width:100%; justify-content:space-between; margin-top:4px; }
}

.order-id .id-main { font-weight:700;color:#0f172a;font-size:0.95rem }
.id-sub { font-size:0.8rem;color:#64748b;margin-top:2px }
.description { font-size:0.9rem;color:#334155;line-height:1.4 }
.customer { font-size:0.9rem;color:#0f172a;font-weight:500 }
.amount { font-weight:600;color:#0f172a }
.remaining { font-weight:600;color:#dc2626 }
.badge { padding:4px 10px;border-radius:6px;color:white;font-weight:600;font-size:0.7rem;letter-spacing:0.3px;white-space:nowrap;box-shadow:0 1px 2px rgba(0,0,0,0.05) }
.status-pending { background:#f59e0b }
.status-blue { background:#3b82f6 }
.status-gray { background:#64748b }
.status-green { background:#10b981 }
.status-red { background:#ef4444 }
.actions { display:flex;gap:8px;justify-content:flex-end;align-items:center; }
.btn-delete { background:#fff;border:1px solid #eee;padding:6px 8px;border-radius:6px }
.btn-menu { background:#fff;border:1px solid #e2e8f0;padding:6px 10px;border-radius:6px;color:#475569;transition:all 0.2s;line-height:1; }
.btn-menu:hover { background:#f1f5f9;border-color:#cbd5e1;color:#0f172a }
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
:is(.dark) .orders-table-wrapper{background:#111c2e;border-color:#1e293b;}
:is(.dark) .orders-row{border-bottom-color:#1e293b;color:#cbd5e1;}
:is(.dark) .orders-row:hover:not(.header){background:#1e293b;}
:is(.dark) .orders-row.header{background:#0f1729;border-bottom-color:#1e293b;color:#94a3b8;}
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

/* ===== Responsive visibility ===== */
.mobile-only { display:none; }
.desktop-only { display:block; }

@media (max-width: 768px) {
  .mobile-only { display:block !important; }
  .mobile-cards-container.mobile-only { display:flex !important; }
  .desktop-only { display:none !important; }
}

/* ===== Mobile Order Cards ===== */
.mobile-cards-container {
  flex-direction:column;
  gap:12px;
  margin-top:16px;
  padding-bottom:24px;
}

.empty-state {
  display:flex;
  flex-direction:column;
  align-items:center;
  justify-content:center;
  padding:48px 16px;
  color:#94a3b8;
  font-size:0.95rem;
}
.empty-icon {
  font-size:2.5rem;
  margin-bottom:8px;
  opacity:0.6;
}

.order-card {
  background:#fff;
  border:1px solid #eef2f5;
  border-radius:14px;
  box-shadow:0 2px 12px rgba(0,0,0,0.04), 0 1px 3px rgba(0,0,0,0.02);
  overflow:visible;
  transition:transform 0.15s ease, box-shadow 0.15s ease;
  cursor:pointer;
  border-left:4px solid #e2e8f0;
  animation: cardFadeIn 0.25s ease both;
}
.order-card:active {
  transform:scale(0.985);
  box-shadow:0 1px 6px rgba(0,0,0,0.06);
}

@keyframes cardFadeIn {
  from { opacity:0; transform:translateY(8px); }
  to { opacity:1; transform:translateY(0); }
}

/* Status-based left border color */
.order-card:has(.status-pending) { border-left-color:#f59e0b; }
.order-card:has(.status-blue) { border-left-color:#3b82f6; }
.order-card:has(.status-gray) { border-left-color:#64748b; }
.order-card:has(.status-green) { border-left-color:#10b981; }
.order-card:has(.status-red) { border-left-color:#ef4444; }

.card-header {
  display:flex;
  justify-content:space-between;
  align-items:flex-start;
  padding:14px 16px 10px;
  gap:10px;
}
.card-id-date {
  display:flex;
  flex-direction:column;
  gap:3px;
}
.card-folio {
  font-weight:700;
  font-size:0.95rem;
  color:#0f172a;
  letter-spacing:0.01em;
}
.card-date {
  font-size:0.78rem;
  color:#94a3b8;
}

.card-body {
  padding:0 16px 12px;
  display:flex;
  flex-direction:column;
  gap:8px;
}
.card-row {
  display:flex;
  flex-direction:column;
  gap:2px;
}
.card-label {
  font-size:0.72rem;
  color:#94a3b8;
  font-weight:600;
  text-transform:uppercase;
  letter-spacing:0.04em;
}
.card-value {
  font-size:0.88rem;
  color:#334155;
  line-height:1.35;
}
.card-client {
  font-weight:600;
  color:#0f172a;
}
.card-desc {
  display:-webkit-box;
  -webkit-line-clamp:2;
  -webkit-box-orient:vertical;
  overflow:hidden;
  text-overflow:ellipsis;
}

.card-footer {
  display:flex;
  flex-direction:column;
  padding:10px 14px 14px;
  border-top:1px solid #f1f5f9;
  background:#fafbfc;
  gap:10px;
  border-radius:0 0 14px 10px;
  overflow:visible;
}
.card-footer-row {
  display:flex;
  justify-content:space-between;
  align-items:center;
  width:100%;
}

.card-totals {
  display:flex;
  gap:16px;
}
.card-total, .card-remaining {
  display:flex;
  flex-direction:column;
}
.card-total-label {
  font-size:0.68rem;
  color:#94a3b8;
  font-weight:600;
  text-transform:uppercase;
  letter-spacing:0.04em;
}
.card-total-value {
  font-weight:700;
  font-size:0.95rem;
  color:#0f172a;
}
.remaining-val {
  color:#dc2626;
}

.card-actions {
  display:flex;
  gap:6px;
  align-items:center;
  position:relative;
  flex-wrap:wrap;
  width:100%;
}
.card-btn {
  padding:7px 12px;
  border-radius:8px;
  font-size:0.8rem;
  font-weight:600;
  border:none;
  cursor:pointer;
  transition:all 0.15s;
  white-space:nowrap;
  flex:1 1 auto;
  text-align:center;
  min-width:0;
}
.card-btn-edit {
  background:#059669;
  color:white;
}
.card-btn-edit:hover { background:#047857; }
.card-btn-pay {
  background:#eff6ff;
  border:1px solid #bfdbfe;
  color:#2563eb;
}
.card-btn-pay:hover { background:#dbeafe; }
.card-btn-menu {
  background:#f1f5f9;
  border:1px solid #e2e8f0;
  color:#475569;
  padding:7px 10px;
  font-size:1rem;
  line-height:1;
  flex:0 0 auto;
}
.card-btn-menu:hover { background:#e2e8f0; }

.card-menu-pop {
  position:absolute;
  bottom:100%;
  right:0;
  margin-bottom:6px;
  background:#fff;
  border:1px solid #eef2f5;
  border-radius:10px;
  box-shadow:0 8px 24px rgba(0,0,0,0.1);
  padding:8px;
  z-index:130;
  min-width:160px;
  white-space:nowrap;
}
.card-menu-pop button {
  display:block;
  width:100%;
  text-align:left;
  padding:8px 12px;
  border:none;
  background:transparent;
  font-size:0.88rem;
  border-radius:6px;
  transition:background 0.12s;
}
.card-menu-pop button:hover { background:#f1f5f9; }

/* ===== Pagination ===== */
.pagination {
  display:flex;
  align-items:center;
  justify-content:center;
  gap:6px;
  margin-top:20px;
  padding:16px 0;
  flex-wrap:wrap;
}
.page-btn {
  min-width:36px;
  height:36px;
  display:inline-flex;
  align-items:center;
  justify-content:center;
  border:1px solid #e2e8f0;
  background:#fff;
  border-radius:8px;
  font-size:0.88rem;
  font-weight:500;
  color:#475569;
  cursor:pointer;
  transition:all 0.15s;
  padding:0 8px;
}
.page-btn:hover:not(:disabled):not(.active) { background:#f1f5f9;border-color:#cbd5e1;color:#0f172a; }
.page-btn:disabled { opacity:0.35;cursor:not-allowed; }
.page-btn.active {
  background:#059669;
  color:white;
  border-color:#059669;
  font-weight:700;
  box-shadow:0 2px 8px rgba(5,150,105,0.25);
}
.page-ellipsis {
  display:inline-flex;
  align-items:center;
  justify-content:center;
  width:28px;
  height:36px;
  color:#94a3b8;
  font-size:0.95rem;
  user-select:none;
}
.page-info {
  margin-left:12px;
  font-size:0.82rem;
  color:#94a3b8;
  white-space:nowrap;
}

@media (max-width: 768px) {
  .pagination { gap:4px; margin-top:14px; padding:12px 0; }
  .page-btn { min-width:32px; height:32px; font-size:0.82rem; }
  .page-info { width:100%; text-align:center; margin-left:0; margin-top:6px; }
}

/* ===== Dark mode for mobile cards & pagination ===== */
:is(.dark) .order-card {
  background:#111c2e;
  border-color:#1e293b;
  border-left-color:#334155;
  box-shadow:0 2px 12px rgba(0,0,0,0.15);
}
:is(.dark) .order-card:has(.status-pending) { border-left-color:#f59e0b; }
:is(.dark) .order-card:has(.status-blue) { border-left-color:#3b82f6; }
:is(.dark) .order-card:has(.status-gray) { border-left-color:#64748b; }
:is(.dark) .order-card:has(.status-green) { border-left-color:#10b981; }
:is(.dark) .order-card:has(.status-red) { border-left-color:#ef4444; }

:is(.dark) .card-folio { color:#e2e8f0; }
:is(.dark) .card-date { color:#64748b; }
:is(.dark) .card-label { color:#64748b; }
:is(.dark) .card-value { color:#cbd5e1; }
:is(.dark) .card-client { color:#e2e8f0; }
:is(.dark) .card-footer { background:#0f1729; border-top-color:#1e293b; }
:is(.dark) .card-total-value { color:#e2e8f0; }
:is(.dark) .remaining-val { color:#f59e0b; }
:is(.dark) .card-btn-edit { background:#059669; color:#fff; }
:is(.dark) .card-btn-pay { background:#1e3a5f; border-color:#1d4ed8; color:#93c5fd; }
:is(.dark) .card-btn-menu { background:#1e293b; border-color:#334155; color:#94a3b8; }
:is(.dark) .card-menu-pop { background:#111c2e; border-color:#1e293b; box-shadow:0 8px 24px rgba(0,0,0,0.35); }
:is(.dark) .card-menu-pop button { color:#cbd5e1; }
:is(.dark) .card-menu-pop button:hover { background:#1e293b; }
:is(.dark) .empty-state { color:#64748b; }

:is(.dark) .page-btn { background:#111c2e; border-color:#1e293b; color:#94a3b8; }
:is(.dark) .page-btn:hover:not(:disabled):not(.active) { background:#1e293b; color:#e2e8f0; }
:is(.dark) .page-btn.active { background:#059669; border-color:#059669; color:white; }
:is(.dark) .page-info { color:#64748b; }
</style>
