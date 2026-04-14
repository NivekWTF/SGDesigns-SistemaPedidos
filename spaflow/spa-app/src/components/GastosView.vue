<template>
  <div class="p-6 gastos-page">
    <header class="page-header">
      <div>
        <h1 class="page-title">Gastos</h1>
        <p class="page-sub">Registra y consulta tus gastos</p>
      </div>
    </header>

    <section class="stats-grid">
      <div class="stat-card">
        <div class="stat-num">{{ gastos.length }}</div>
        <div class="stat-label">Total Registros</div>
      </div>
      <div class="stat-card">
        <div class="stat-num">{{ formatCurrency(totalGastos) }}</div>
        <div class="stat-label">Monto Total</div>
      </div>
    </section>

    <!-- Formulario para nuevo gasto -->
    <section v-if="showForm" class="form-overlay" @click.self="showForm = false">
      <div class="form-card">
        <h3>Nuevo Gasto</h3>
        <form @submit.prevent="guardarGasto">
          <div class="form-group">
            <label>Descripción</label>
            <input v-model="form.descripcion" placeholder="Ej: Compra de papel couché" class="form-input" />
          </div>
          <div class="form-group">
            <label>Monto *</label>
            <input v-model.number="form.monto" type="number" step="0.01" min="0" required placeholder="0.00" class="form-input" />
          </div>
          <div class="form-group">
            <label>Referencia</label>
            <input v-model="form.referencia" placeholder="Ej: Factura #123" class="form-input" />
          </div>
          <div class="form-actions">
            <button type="button" class="btn-secondary" @click="showForm = false">Cancelar</button>
            <button type="submit" class="btn-primary" :disabled="!form.monto">Guardar</button>
          </div>
          <p v-if="errorMsg" class="error-msg">⚠️ {{ errorMsg }}</p>
        </form>
      </div>
    </section>

    <!-- Listado -->
    <section class="mt-8 list-section">
      <div class="list-controls">
        <div class="search">
          <input v-model="searchTerm" placeholder="Buscar por descripción..." />
        </div>
        <button type="button" class="btn-primary" @click="openForm">+ Nuevo gasto</button>
      </div>

      <p v-if="loading">Cargando...</p>
      <p v-else-if="errorMsg && !gastos.length">⚠️ {{ errorMsg }}</p>

      <div v-else class="orders-table">
        <div class="orders-row header">
          <div>Fecha</div>
          <div>Descripción</div>
          <div>Monto</div>
          <div>Referencia</div>
          <div>Acciones</div>
        </div>

        <div v-for="g in paginatedGastos" :key="g.id" class="orders-row">
          <div>{{ formatDate(g.created_at) }}</div>
          <div>{{ g.descripcion || '-' }}</div>
          <div class="monto-cell">{{ formatCurrency(g.monto) }}</div>
          <div>{{ g.referencia || '-' }}</div>
          <div class="actions">
            <button class="btn-delete" @click="borrar(g.id)">Eliminar</button>
          </div>
        </div>

        <div v-if="!filteredGastos.length" class="empty-row">
          No hay gastos registrados.
        </div>

        <div class="pagination">
          <div>
            <button @click="prevPage" :disabled="page === 1">Anterior</button>
            <button @click="nextPage" :disabled="page >= totalPages">Siguiente</button>
          </div>
          <div>Página {{ page }} / {{ totalPages }}</div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useGastos } from '../composables/useGastos'
import type { GastoInput } from '../composables/useGastos'

const { gastos, loading, errorMsg, fetchGastos, crearGasto, eliminarGasto } = useGastos()

const showForm = ref(false)
const searchTerm = ref('')
const page = ref(1)
const perPage = 15

const form = ref<GastoInput>({ descripcion: '', monto: 0, referencia: '' })

onMounted(fetchGastos)

const totalGastos = computed(() => gastos.value.reduce((s, g) => s + (g.monto || 0), 0))

const filteredGastos = computed(() => {
  const q = searchTerm.value.toLowerCase()
  if (!q) return gastos.value
  return gastos.value.filter(g => (g.descripcion || '').toLowerCase().includes(q) || (g.referencia || '').toLowerCase().includes(q))
})

const totalPages = computed(() => Math.max(1, Math.ceil(filteredGastos.value.length / perPage)))
const paginatedGastos = computed(() => {
  const start = (page.value - 1) * perPage
  return filteredGastos.value.slice(start, start + perPage)
})

function prevPage() { if (page.value > 1) page.value-- }
function nextPage() { if (page.value < totalPages.value) page.value++ }

function openForm() {
  form.value = { descripcion: '', monto: 0, referencia: '' }
  showForm.value = true
}

async function guardarGasto() {
  if (!form.value.monto) return
  await crearGasto(form.value)
  showForm.value = false
}

async function borrar(id: string) {
  if (!confirm('¿Eliminar este gasto?')) return
  await eliminarGasto(id)
}

function formatCurrency(n: number) {
  return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN', maximumFractionDigits: 2 }).format(n || 0)
}

function formatDate(iso: string | null) {
  if (!iso) return '-'
  const d = new Date(iso)
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`
}
</script>

<style scoped>
.gastos-page { max-width: 1100px }

.page-header { margin-bottom: 16px }
.page-title { font-size: 1.5rem; font-weight: 800; color: #0f172a }
.page-sub { color: #64748b; font-size: 13px; margin-top: 2px }

.stats-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(160px, 1fr)); gap: 10px; margin-bottom: 16px }
.stat-card { background: #fff; padding: 14px 16px; border-radius: 10px; border: 1px solid #eef2f6; text-align: center }
.stat-num { font-weight: 700; font-size: 20px; color: #0f172a }
.stat-label { color: #64748b; font-size: 12px; text-transform: uppercase; letter-spacing: .3px; margin-top: 2px }

.list-section h2 { font-size: 1.1rem; font-weight: 700; margin-bottom: 8px }
.list-controls { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; gap: 8px; flex-wrap: wrap }
.search { flex: 1; max-width: 60% }
.search input { width: 100%; padding: 8px 12px; border: 1px solid #e2e8f0; border-radius: 8px; font-size: 14px }

.orders-table { background: #fff; border-radius: 10px; border: 1px solid #eef2f6; overflow: hidden }
.orders-row { display: grid; grid-template-columns: 120px 1fr 120px 150px 90px; padding: 10px 14px; align-items: center; gap: 8px; border-bottom: 1px solid #f1f5f9 }
.orders-row.header { font-weight: 700; font-size: 12px; text-transform: uppercase; color: #64748b; background: #f8fafc }
.orders-row:last-child { border-bottom: none }
.monto-cell { font-weight: 600; color: #dc2626 }
.empty-row { padding: 24px; text-align: center; color: #94a3b8; font-size: 14px }
.actions { display: flex; gap: 6px }

.btn-primary { background: #0ea5a4; color: #fff; border: none; padding: 8px 18px; border-radius: 8px; font-weight: 600; font-size: 14px; cursor: pointer; white-space: nowrap }
.btn-primary:hover { background: #0d9695 }
.btn-primary:disabled { opacity: .5; cursor: not-allowed }
.btn-secondary { background: #f1f5f9; color: #334155; border: 1px solid #e2e8f0; padding: 8px 18px; border-radius: 8px; font-weight: 600; font-size: 14px; cursor: pointer }
.btn-delete { background: none; border: 1px solid #fecaca; color: #dc2626; padding: 4px 10px; border-radius: 6px; font-size: 12px; cursor: pointer }
.btn-delete:hover { background: #fef2f2 }

.pagination { display: flex; gap: 8px; align-items: center; justify-content: flex-end; padding: 12px }
.pagination button { padding: 6px 14px; border: 1px solid #e2e8f0; border-radius: 6px; background: #fff; cursor: pointer; font-size: 13px }
.pagination button:disabled { opacity: .4; cursor: not-allowed }

/* Form overlay */
.form-overlay { position: fixed; inset: 0; background: rgba(0,0,0,.35); display: flex; align-items: center; justify-content: center; z-index: 200 }
.form-card { background: #fff; border-radius: 12px; padding: 24px; width: 100%; max-width: 440px; box-shadow: 0 8px 30px rgba(0,0,0,.12) }
.form-card h3 { font-size: 1.1rem; font-weight: 700; margin-bottom: 16px; color: #0f172a }
.form-group { margin-bottom: 12px }
.form-group label { display: block; font-size: 13px; font-weight: 600; color: #334155; margin-bottom: 4px }
.form-input { width: 100%; padding: 8px 12px; border: 1px solid #e2e8f0; border-radius: 8px; font-size: 14px; box-sizing: border-box }
.form-actions { display: flex; gap: 8px; justify-content: flex-end; margin-top: 16px }
.error-msg { color: #dc2626; font-size: 13px; margin-top: 8px }

@media (max-width: 768px) {
  .orders-row { grid-template-columns: 90px 1fr 90px 80px; font-size: 13px }
  .orders-row > div:nth-child(4) { display: none }
  .list-controls { flex-direction: column; align-items: stretch }
  .search { max-width: 100% }
  .form-card { margin: 16px }
}

/* Dark mode */
:is(.dark) .gastos-page{color:#e2e8f0}
:is(.dark) .page-title{color:#e2e8f0}
:is(.dark) .page-sub{color:#94a3b8}
:is(.dark) .stat-card{background:#111c2e;border-color:#1e293b}
:is(.dark) .stat-num{color:#e2e8f0}
:is(.dark) .stat-label{color:#94a3b8}
:is(.dark) .list-section h2{color:#e2e8f0}
:is(.dark) .search input{background:#0f1729;border-color:#334155;color:#e2e8f0}
:is(.dark) .search input::placeholder{color:#475569}
:is(.dark) .orders-table{background:#111c2e;border-color:#1e293b}
:is(.dark) .orders-row{border-bottom-color:#1e293b;color:#cbd5e1}
:is(.dark) .orders-row.header{background:#0f1729;color:#94a3b8}
:is(.dark) .monto-cell{color:#fca5a5}
:is(.dark) .empty-row{color:#475569}
:is(.dark) .btn-primary{background:#0ea5a4}
:is(.dark) .btn-primary:hover{background:#0d9695}
:is(.dark) .btn-secondary{background:#1e293b;border-color:#334155;color:#cbd5e1}
:is(.dark) .btn-delete{background:transparent;border-color:#7f1d1d;color:#fca5a5}
:is(.dark) .btn-delete:hover{background:#1c1917}
:is(.dark) .pagination button{background:#0f1729;border-color:#334155;color:#cbd5e1}
:is(.dark) .form-overlay{background:rgba(0,0,0,0.6)}
:is(.dark) .form-card{background:#111c2e;box-shadow:0 8px 30px rgba(0,0,0,0.3)}
:is(.dark) .form-card h3{color:#e2e8f0}
:is(.dark) .form-group label{color:#94a3b8}
:is(.dark) .form-input{background:#0f1729;border-color:#334155;color:#e2e8f0}
</style>
