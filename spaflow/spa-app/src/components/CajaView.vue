<template>
  <div class="view-page">
    <div class="page-header">
      <div>
        <h1 class="font-spa-display">Caja</h1>
        <p class="page-sub">Movimientos de {{ cajaActiva?.nombre ?? 'caja' }} · {{ fechaHoy }}</p>
      </div>
      <div class="header-actions">
        <button class="btn-ghost" @click="showAbrirCaja = true" v-if="!cajaActiva?.abierta">
          <Unlock class="h-4 w-4" /> Abrir caja
        </button>
        <button class="btn-ghost" @click="cerrarCaja" v-else>
          <Lock class="h-4 w-4" /> Cerrar caja
        </button>
        <button class="btn-primary" @click="showMovForm = true">
          <Plus class="h-4 w-4" /> Registrar movimiento
        </button>
      </div>
    </div>

    <!-- Resumen rápido -->
    <div class="resumen-grid">
      <div class="res-card green">
        <TrendingUp class="h-5 w-5" />
        <div>
          <div class="res-val">{{ fmt(totalEntradas) }}</div>
          <div class="res-lbl">Entradas</div>
        </div>
      </div>
      <div class="res-card red">
        <TrendingDown class="h-5 w-5" />
        <div>
          <div class="res-val">{{ fmt(totalSalidas) }}</div>
          <div class="res-lbl">Salidas</div>
        </div>
      </div>
      <div class="res-card" :class="saldoNeto >= 0 ? 'blue' : 'red'">
        <Wallet class="h-5 w-5" />
        <div>
          <div class="res-val">{{ fmt(saldoNeto) }}</div>
          <div class="res-lbl">Saldo neto</div>
        </div>
      </div>
      <div class="res-card purple">
        <ReceiptText class="h-5 w-5" />
        <div>
          <div class="res-val">{{ movimientos.length }}</div>
          <div class="res-lbl">Movimientos</div>
        </div>
      </div>
    </div>

    <!-- Filtros -->
    <div class="filters-bar">
      <div class="search-wrap">
        <Search class="search-icon h-4 w-4" />
        <input v-model="q" placeholder="Buscar concepto..." class="search-input" />
      </div>
      <div class="filter-row">
        <div class="field-inline">
          <label>Desde</label>
          <input type="date" v-model="filtroDesde" @change="recargar" />
        </div>
        <div class="field-inline">
          <label>Hasta</label>
          <input type="date" v-model="filtroHasta" @change="recargar" />
        </div>
        <div class="filter-tabs">
          <button :class="['tab-btn', filtroTipo === '' && 'active']" @click="filtroTipo = ''">Todos</button>
          <button :class="['tab-btn green-tab', filtroTipo === 'in' && 'active']" @click="filtroTipo = 'in'">⬆ Entradas</button>
          <button :class="['tab-btn red-tab', filtroTipo === 'out' && 'active']" @click="filtroTipo = 'out'">⬇ Salidas</button>
        </div>
      </div>
    </div>

    <!-- Tabla movimientos -->
    <div class="card-spa table-wrap">
      <div v-if="loading" class="empty-state"><div class="spinner"/><p>Cargando...</p></div>
      <div v-else-if="filtrados.length === 0" class="empty-state">
        <ReceiptText class="h-8 w-8 op-30"/><p>Sin movimientos en este período</p>
      </div>
      <table v-else class="spa-table">
        <thead>
          <tr>
            <th>Fecha</th>
            <th>Concepto</th>
            <th>Método</th>
            <th class="text-right">Monto</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="m in filtrados" :key="m.id" class="mov-row">
            <td class="date-cell">{{ fmtDateTime(m.created_at) }}</td>
            <td>
              <div class="concepto-cell">
                <span class="tipo-pill" :class="m.es_entrada ? 'entrada' : 'salida'">
                  {{ m.es_entrada ? '↑' : '↓' }}
                </span>
                <div>
                  <div class="concepto-nombre">{{ m.concepto }}</div>
                  <div v-if="m.referencia_id" class="concepto-ref">Cita #{{ m.referencia_id.slice(0, 8) }}</div>
                </div>
              </div>
            </td>
            <td>
              <span class="metodo-tag">{{ metodIcon(m.metodo_pago) }} {{ m.metodo_pago }}</span>
            </td>
            <td class="monto-cell" :class="m.es_entrada ? 'monto-entrada' : 'monto-salida'">
              {{ m.es_entrada ? '+' : '-' }}{{ fmt(m.monto) }}
            </td>
          </tr>
        </tbody>
        <tfoot>
          <tr class="table-footer">
            <td colspan="3" class="footer-lbl">Total período</td>
            <td class="monto-cell" :class="saldoFiltrado >= 0 ? 'monto-entrada' : 'monto-salida'">
              {{ fmt(saldoFiltrado) }}
            </td>
          </tr>
        </tfoot>
      </table>
    </div>

    <!-- Modal: Nuevo movimiento -->
    <Teleport to="body">
      <div v-if="showMovForm" class="modal-backdrop" @click.self="showMovForm = false">
        <div class="modal-box">
          <div class="modal-header">
            <h2>Nuevo movimiento</h2>
            <button class="icon-btn" @click="showMovForm = false"><X class="h-5 w-5"/></button>
          </div>
          <form @submit.prevent="registrarMovimiento" class="modal-form">
            <div class="tipo-toggle">
              <button type="button" :class="['tipo-btn green-btn', movForm.es_entrada && 'active']"
                @click="movForm.es_entrada = true">↑ Entrada</button>
              <button type="button" :class="['tipo-btn red-btn', !movForm.es_entrada && 'active']"
                @click="movForm.es_entrada = false">↓ Salida</button>
            </div>
            <div class="field">
              <label>Concepto *</label>
              <input v-model="movForm.concepto" required placeholder="Ej. Pago servicio masaje, Reabastecimiento..." />
            </div>
            <div class="fields-row">
              <div class="field">
                <label>Monto *</label>
                <div class="input-prefix">
                  <span>$</span>
                  <input v-model.number="movForm.monto" type="number" min="0.01" step="0.01" required />
                </div>
              </div>
              <div class="field">
                <label>Método de pago</label>
                <select v-model="movForm.metodo_pago">
                  <option value="EFECTIVO">💵 Efectivo</option>
                  <option value="TRANSFERENCIA">🏦 Transferencia</option>
                  <option value="TARJETA">💳 Tarjeta</option>
                  <option value="OTRO">🧾 Otro</option>
                </select>
              </div>
            </div>
            <div v-if="movError" class="form-error">{{ movError }}</div>
            <div class="modal-footer">
              <button type="button" class="btn-ghost" @click="showMovForm = false">Cancelar</button>
              <button type="submit" class="btn-primary" :disabled="savingMov">
                <Loader2 v-if="savingMov" class="h-4 w-4 animate-spin"/> Registrar
              </button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>

    <!-- Modal: Abrir caja -->
    <Teleport to="body">
      <div v-if="showAbrirCaja" class="modal-backdrop" @click.self="showAbrirCaja = false">
        <div class="modal-box modal-sm">
          <div class="modal-header">
            <h2>Abrir caja</h2>
            <button class="icon-btn" @click="showAbrirCaja = false"><X class="h-5 w-5"/></button>
          </div>
          <div class="modal-form">
            <div class="field">
              <label>Saldo inicial</label>
              <div class="input-prefix">
                <span>$</span>
                <input v-model.number="saldoInicial" type="number" min="0" step="0.01" />
              </div>
            </div>
            <div class="modal-footer">
              <button class="btn-ghost" @click="showAbrirCaja = false">Cancelar</button>
              <button class="btn-primary" @click="doAbrirCaja">
                <Unlock class="h-4 w-4"/> Abrir
              </button>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useCaja } from '../composables/useCaja'
import { TrendingUp, TrendingDown, Wallet, ReceiptText, Plus, Search, X, Lock, Unlock, Loader2 } from 'lucide-vue-next'

const { cajaActiva, movimientos, loading, errorMsg, ensureCajaActiva, fetchMovimientos, abrirCaja, crearMovimiento } = useCaja()

const fechaHoy = new Date().toLocaleDateString('es-MX', { weekday: 'long', day: 'numeric', month: 'long' })
const hoy = new Date().toISOString().slice(0, 10)
const filtroDesde = ref(hoy)
const filtroHasta = ref(hoy)
const filtroTipo = ref('')
const q = ref('')

const fmt = (n: number) => new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(n ?? 0)
const fmtDateTime = (d: string) => new Date(d).toLocaleString('es-MX', { day: '2-digit', month: 'short', hour: '2-digit', minute: '2-digit' })
const metodIcon = (m: string) => ({ EFECTIVO: '💵', TRANSFERENCIA: '🏦', TARJETA: '💳', OTRO: '🧾' }[m] ?? '💰')

const filtrados = computed(() => {
  let list = movimientos.value
  if (filtroTipo.value === 'in') list = list.filter(m => m.es_entrada)
  if (filtroTipo.value === 'out') list = list.filter(m => !m.es_entrada)
  if (q.value.trim()) {
    const t = q.value.toLowerCase()
    list = list.filter(m => m.concepto.toLowerCase().includes(t))
  }
  return list
})

const totalEntradas = computed(() => movimientos.value.filter(m => m.es_entrada).reduce((s, m) => s + m.monto, 0))
const totalSalidas  = computed(() => movimientos.value.filter(m => !m.es_entrada).reduce((s, m) => s + m.monto, 0))
const saldoNeto     = computed(() => totalEntradas.value - totalSalidas.value)
const saldoFiltrado = computed(() => filtrados.value.reduce((s, m) => s + (m.es_entrada ? m.monto : -m.monto), 0))

async function recargar() {
  await ensureCajaActiva()
  await fetchMovimientos({ dateFrom: filtroDesde.value, dateTo: filtroHasta.value })
}

// Nuevo movimiento
const showMovForm = ref(false)
const savingMov = ref(false)
const movError = ref<string | null>(null)
const movForm = ref({ concepto: '', monto: 0, es_entrada: true, metodo_pago: 'EFECTIVO' })

async function registrarMovimiento() {
  movError.value = null
  savingMov.value = true
  try {
    await crearMovimiento(movForm.value as any)
    showMovForm.value = false
    movForm.value = { concepto: '', monto: 0, es_entrada: true, metodo_pago: 'EFECTIVO' }
  } catch (e: any) {
    movError.value = e.message ?? 'Error al registrar'
  } finally { savingMov.value = false }
}

// Abrir / cerrar caja
const showAbrirCaja = ref(false)
const saldoInicial = ref(0)

async function doAbrirCaja() {
  await abrirCaja(saldoInicial.value)
  showAbrirCaja.value = false
  await recargar()
}

async function cerrarCaja() {
  if (!confirm('¿Cerrar la caja actual?')) return
  const { supabase } = await import('../lib/supabase')
  await supabase.from('cajas').update({ abierta: false, fecha_cierre: new Date().toISOString() }).eq('abierta', true)
  cajaActiva.value = null
}

onMounted(recargar)
</script>

<style scoped>
.view-page { padding: 24px; max-width: 1000px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px; gap: 12px; flex-wrap: wrap; }
.page-header h1 { font-size: 26px; font-weight: 700; color: var(--foreground); margin: 0; }
.page-sub { color: var(--muted-foreground); font-size: 14px; margin: 4px 0 0; text-transform: capitalize; }
.header-actions { display: flex; gap: 10px; align-items: center; }

/* Resumen */
.resumen-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 18px; }
.res-card { display: flex; align-items: center; gap: 12px; padding: 16px; border-radius: var(--radius); border: 1.5px solid var(--border); background: var(--card); }
.res-card.green svg { color: #10b981; } .res-card.green .res-val { color: #10b981; }
.res-card.red svg { color: #ef4444; } .res-card.red .res-val { color: #ef4444; }
.res-card.blue svg { color: #3b82f6; } .res-card.blue .res-val { color: #3b82f6; }
.res-card.purple svg { color: var(--primary); } .res-card.purple .res-val { color: var(--primary); }
.res-val { font-size: 20px; font-weight: 800; line-height: 1.1; }
.res-lbl { font-size: 12px; color: var(--muted-foreground); margin-top: 2px; }

/* Filters */
.filters-bar { display: flex; flex-direction: column; gap: 10px; margin-bottom: 14px; }
.filter-row { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
.search-wrap { position: relative; max-width: 300px; }
.search-icon { position: absolute; left: 10px; top: 50%; transform: translateY(-50%); color: var(--muted-foreground); pointer-events: none; }
.search-input { width: 100%; padding: 8px 12px 8px 34px; border: 1.5px solid var(--border); border-radius: var(--radius); background: var(--card); color: var(--foreground); font-size: 13px; box-sizing: border-box; }
.search-input:focus { outline: none; border-color: var(--primary); }
.field-inline { display: flex; flex-direction: column; gap: 4px; }
.field-inline label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .05em; color: var(--muted-foreground); }
.field-inline input, .field-inline select { padding: 7px 10px; border: 1.5px solid var(--border); border-radius: var(--radius); background: var(--background); color: var(--foreground); font-size: 13px; }
.filter-tabs { display: flex; border: 1.5px solid var(--border); border-radius: var(--radius); overflow: hidden; }
.tab-btn { padding: 6px 14px; background: transparent; border: none; color: var(--muted-foreground); font-size: 12px; font-weight: 700; cursor: pointer; transition: all .15s; }
.tab-btn.active { background: var(--primary); color: white; }
.green-tab.active { background: #10b981; }
.red-tab.active { background: #ef4444; }

/* Table */
.table-wrap { padding: 0; overflow-x: auto; }
.spa-table { width: 100%; border-collapse: collapse; min-width: 600px; }
.spa-table th { padding: 11px 16px; text-align: left; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .06em; color: var(--muted-foreground); border-bottom: 2px solid var(--border); }
.text-right { text-align: right !important; }
.spa-table td { padding: 12px 16px; border-bottom: 1px solid var(--border); vertical-align: middle; font-size: 13px; }
.mov-row:hover { background: var(--muted); transition: background .1s; }
.date-cell { color: var(--muted-foreground); white-space: nowrap; font-size: 12px; }
.concepto-cell { display: flex; align-items: center; gap: 10px; }
.tipo-pill { display: inline-flex; align-items: center; justify-content: center; width: 24px; height: 24px; border-radius: 6px; font-weight: 800; font-size: 12px; flex-shrink: 0; }
.tipo-pill.entrada { background: #d1fae5; color: #065f46; }
.tipo-pill.salida  { background: #fee2e2; color: #991b1b; }
:is(.dark) .tipo-pill.entrada { background: #064e3b; color: #6ee7b7; }
:is(.dark) .tipo-pill.salida  { background: #450a0a; color: #fca5a5; }
.concepto-nombre { font-weight: 600; color: var(--foreground); }
.concepto-ref { font-size: 11px; color: var(--muted-foreground); font-family: monospace; }
.metodo-tag { font-size: 12px; color: var(--muted-foreground); white-space: nowrap; }
.monto-cell { text-align: right; font-weight: 700; font-size: 15px; white-space: nowrap; }
.monto-entrada { color: #10b981; }
.monto-salida  { color: #ef4444; }
.table-footer td { border-top: 2px solid var(--border); font-weight: 700; padding-top: 14px; }
.footer-lbl { color: var(--muted-foreground); font-size: 13px; }

/* Tipo toggle */
.tipo-toggle { display: flex; border-radius: var(--radius); overflow: hidden; border: 1.5px solid var(--border); }
.tipo-btn { flex: 1; padding: 10px; background: transparent; border: none; font-size: 14px; font-weight: 700; cursor: pointer; transition: all .15s; color: var(--muted-foreground); }
.green-btn.active { background: #d1fae5; color: #065f46; }
.red-btn.active { background: #fee2e2; color: #991b1b; }
:is(.dark) .green-btn.active { background: #064e3b; color: #6ee7b7; }
:is(.dark) .red-btn.active { background: #450a0a; color: #fca5a5; }

/* Common */
.empty-state { padding: 60px; text-align: center; display: flex; flex-direction: column; align-items: center; gap: 12px; color: var(--muted-foreground); }
.op-30 { opacity: .3; }
.spinner { width: 28px; height: 28px; border: 3px solid var(--border); border-top-color: var(--primary); border-radius: 50%; animation: spin .6s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
.icon-btn { display: inline-flex; align-items: center; justify-content: center; width: 32px; height: 32px; border-radius: 8px; border: 1px solid var(--border); background: transparent; color: var(--muted-foreground); cursor: pointer; }
.icon-btn:hover { background: var(--muted); }
.modal-backdrop { position: fixed; inset: 0; background: rgba(0,0,0,.45); backdrop-filter: blur(4px); z-index: 200; display: flex; align-items: center; justify-content: center; padding: 16px; }
.modal-box { background: var(--card); border-radius: calc(var(--radius) + 4px); width: 100%; max-width: 480px; box-shadow: 0 20px 60px rgba(0,0,0,.25); }
.modal-sm { max-width: 360px; }
.modal-header { display: flex; align-items: center; justify-content: space-between; padding: 20px 24px 0; }
.modal-header h2 { font-size: 18px; font-weight: 700; color: var(--foreground); margin: 0; }
.modal-form { padding: 18px 24px 22px; display: flex; flex-direction: column; gap: 14px; }
.modal-footer { display: flex; justify-content: flex-end; gap: 10px; padding-top: 8px; border-top: 1px solid var(--border); }
.field { display: flex; flex-direction: column; gap: 5px; }
.field label { font-size: 13px; font-weight: 600; color: var(--foreground); }
.field input, .field select { padding: 9px 12px; border: 1.5px solid var(--border); border-radius: var(--radius); background: var(--background); color: var(--foreground); font-size: 14px; }
.field input:focus, .field select:focus { outline: none; border-color: var(--primary); }
.fields-row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.input-prefix { display: flex; }
.input-prefix span { padding: 9px 10px; background: var(--muted); border: 1.5px solid var(--border); border-right: none; border-radius: var(--radius) 0 0 var(--radius); color: var(--muted-foreground); font-size: 14px; }
.input-prefix input { border-radius: 0 var(--radius) var(--radius) 0; flex: 1; min-width: 0; }
.form-error { padding: 10px 14px; background: #fee2e2; color: #dc2626; border-radius: var(--radius); font-size: 13px; }
:is(.dark) .form-error { background: #450a0a; color: #f87171; }

@media (max-width: 760px) {
  .resumen-grid { grid-template-columns: 1fr 1fr; gap: 10px; }
  .view-page { padding: 16px; }
}
</style>
