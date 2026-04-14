<template>
  <div class="citas-page">
    <!-- Header -->
    <div class="page-header">
      <div>
        <h1 class="font-spa-display">Agenda</h1>
        <p class="page-sub">Citas del spa · {{ spaNombre }}</p>
      </div>
      <div class="header-actions">
        <div class="view-toggle">
          <button :class="['toggle-btn', viewMode === 'calendario' && 'active']" @click="viewMode = 'calendario'">
            <CalendarDays class="h-4 w-4" /> Calendario
          </button>
          <button :class="['toggle-btn', viewMode === 'lista' && 'active']" @click="viewMode = 'lista'">
            <List class="h-4 w-4" /> Lista
          </button>
        </div>
        <button class="btn-primary" @click="abrirWizard(null)">
          <Plus class="h-4 w-4" /> Nueva cita
        </button>
      </div>
    </div>

    <!-- KPIs del día -->
    <div class="kpis-row">
      <div class="kpi-card">
        <div class="kpi-val">{{ kpis.citas_agendadas + kpis.citas_confirmadas }}</div>
        <div class="kpi-lbl">📅 Pendientes</div>
      </div>
      <div class="kpi-card">
        <div class="kpi-val text-amber">{{ kpis.citas_en_curso }}</div>
        <div class="kpi-lbl">⏳ En curso</div>
      </div>
      <div class="kpi-card">
        <div class="kpi-val text-green">{{ kpis.citas_completadas }}</div>
        <div class="kpi-lbl">✅ Completadas</div>
      </div>
      <div class="kpi-card">
        <div class="kpi-val text-primary">{{ fmt(kpis.total_ingresos) }}</div>
        <div class="kpi-lbl">💰 Ingresos hoy</div>
      </div>
    </div>

    <!-- Calendario FullCalendar -->
    <div v-show="viewMode === 'calendario'" class="card-spa calendar-wrap">
      <FullCalendar ref="calRef" :options="calOptions" />
    </div>

    <!-- Vista Lista -->
    <div v-show="viewMode === 'lista'" class="card-spa">
      <div class="lista-toolbar">
        <div class="field-inline">
          <label>Desde</label>
          <input type="date" v-model="listaDesde" />
        </div>
        <div class="field-inline">
          <label>Hasta</label>
          <input type="date" v-model="listaHasta" />
        </div>
        <div class="field-inline">
          <label>Estado</label>
          <select v-model="listaEstado">
            <option value="">Todos</option>
            <option value="AGENDADA">Agendadas</option>
            <option value="CONFIRMADA">Confirmadas</option>
            <option value="EN_CURSO">En curso</option>
            <option value="COMPLETADA">Completadas</option>
            <option value="CANCELADA">Canceladas</option>
            <option value="NO_SHOW">No show</option>
          </select>
        </div>
        <button class="btn-ghost" @click="recargarLista"><RefreshCw class="h-4 w-4" /> Actualizar</button>
      </div>

      <table class="spa-table">
        <thead>
          <tr>
            <th>Folio</th>
            <th>Cliente</th>
            <th>Terapeuta</th>
            <th>Fecha / Hora</th>
            <th>Servicios</th>
            <th>Total</th>
            <th>Estado</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-if="loading">
            <td colspan="8" class="text-center p-8">
              <div class="spinner mx-auto"/>
            </td>
          </tr>
          <tr v-else-if="citas.length === 0">
            <td colspan="8" class="empty-row">No hay citas en este período</td>
          </tr>
          <tr v-for="c in citas" :key="c.id" class="cita-row" @click="verDetalle(c)">
            <td class="folio-cell">{{ c.folio ?? '—' }}</td>
            <td class="font-medium">{{ c.clientes?.nombre }}</td>
            <td>
              <div v-if="c.personal" class="terapeuta-mini">
                <div class="t-dot" :style="{ background: c.personal.color_agenda }"/>
                {{ c.personal.nombre }}
              </div>
              <span v-else class="muted">Sin asignar</span>
            </td>
            <td>
              <div class="fecha-line">{{ fmtFecha(c.fecha_inicio) }}</div>
              <div class="hora-line">{{ fmtHora(c.fecha_inicio) }} – {{ fmtHora(c.fecha_fin) }}</div>
            </td>
            <td>
              <div class="servicios-names">
                {{ nombresServicios(c) }}
              </div>
            </td>
            <td class="font-bold">{{ fmt(c.total) }}</td>
            <td><span class="estado-badge" :class="estadoClass(c.estado)">{{ estadoLabel(c.estado) }}</span></td>
            <td class="actions-cell" @click.stop>
              <button class="icon-btn" @click="verDetalle(c)" title="Ver detalle"><Eye class="h-4 w-4"/></button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Wizard nueva cita -->
    <NewCitaWizard
      v-if="showWizard"
      :fecha-inicial="wizardFechaInicial"
      @close="showWizard = false"
      @created="onCitaCreada"
    />

    <!-- Detalle cita -->
    <CitaDetailModal
      v-if="citaDetalle"
      :cita="citaDetalle"
      @close="citaDetalle = null"
      @updated="onCitaActualizada"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import FullCalendar from '@fullcalendar/vue3'
import dayGridPlugin from '@fullcalendar/daygrid'
import timeGridPlugin from '@fullcalendar/timegrid'
import interactionPlugin from '@fullcalendar/interaction'
import esLocale from '@fullcalendar/core/locales/es'
import type { CalendarOptions, EventClickArg, DateSelectArg } from '@fullcalendar/core'
import { useCitas } from '../composables/useCitas'
import type { Cita, EstadoCita } from '../composables/useCitas'
import { useTenant } from '../composables/useTenant'
import { CalendarDays, List, Plus, RefreshCw, Eye } from 'lucide-vue-next'
import NewCitaWizard from './NewCitaWizard.vue'
import CitaDetailModal from './CitaDetailModal.vue'

const { spaNombre, spaId } = useTenant()
const { citas, loading, fetchCitas } = useCitas()

// ── KPIs ─────────────────────────────────────────────────────────
const kpis = ref({ citas_agendadas: 0, citas_confirmadas: 0, citas_en_curso: 0, citas_completadas: 0, total_ingresos: 0 })

async function cargarKpis() {
  if (!spaId.value) return
  const { supabase } = await import('../lib/supabase')
  const { data } = await supabase.rpc('get_kpis_dia', { p_spa_id: spaId.value })
  if (data?.[0]) Object.assign(kpis.value, data[0])
}

// ── Vista ─────────────────────────────────────────────────────────
const viewMode = ref<'calendario' | 'lista'>('calendario')
const calRef = ref<InstanceType<typeof FullCalendar> | null>(null)

// ── Wizard ────────────────────────────────────────────────────────
const showWizard = ref(false)
const wizardFechaInicial = ref<string | null>(null)

function abrirWizard(fecha: string | null) {
  wizardFechaInicial.value = fecha
  showWizard.value = true
}

// ── Detalle ───────────────────────────────────────────────────────
const citaDetalle = ref<Cita | null>(null)
function verDetalle(c: Cita) { citaDetalle.value = c }

// ── Helpers formato ───────────────────────────────────────────────
function fmt(n: number) {
  return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(n)
}
function fmtFecha(d: string) {
  return new Date(d).toLocaleDateString('es-MX', { weekday: 'short', day: 'numeric', month: 'short' })
}
function fmtHora(d: string) {
  return new Date(d).toLocaleTimeString('es-MX', { hour: '2-digit', minute: '2-digit', hour12: false })
}
function nombresServicios(c: Cita) {
  return (c.cita_items ?? []).filter(i => i.servicios).map(i => i.servicios?.nombre).join(', ') || '—'
}
function estadoLabel(e: EstadoCita) {
  const MAP: Record<EstadoCita, string> = {
    AGENDADA: 'Agendada', CONFIRMADA: 'Confirmada', EN_CURSO: 'En curso',
    COMPLETADA: 'Completada', CANCELADA: 'Cancelada', NO_SHOW: 'No show'
  }
  return MAP[e] ?? e
}
function estadoClass(e: EstadoCita) {
  const MAP: Record<EstadoCita, string> = {
    AGENDADA: 'badge-agendada', CONFIRMADA: 'badge-confirmada', EN_CURSO: 'badge-en-curso',
    COMPLETADA: 'badge-completada', CANCELADA: 'badge-cancelada', NO_SHOW: 'badge-no-show'
  }
  return MAP[e]
}

// ── FullCalendar Events ───────────────────────────────────────────
const calEvents = computed(() => citas.value.map(c => ({
  id: c.id,
  title: `${c.clientes?.nombre ?? '?'} · ${nombresServicios(c)}`,
  start: c.fecha_inicio,
  end:   c.fecha_fin,
  backgroundColor: c.personal?.color_agenda ?? '#8b5cf6',
  borderColor:     c.personal?.color_agenda ?? '#8b5cf6',
  extendedProps:   { cita: c },
  classNames: [`ev-${c.estado.toLowerCase()}`],
})))

const calOptions = computed<CalendarOptions>(() => ({
  plugins: [dayGridPlugin, timeGridPlugin, interactionPlugin],
  locale: esLocale,
  initialView: 'timeGridWeek',
  headerToolbar: {
    left:   'prev,next today',
    center: 'title',
    right:  'dayGridMonth,timeGridWeek,timeGridDay',
  },
  slotMinTime: '08:00:00',
  slotMaxTime: '21:00:00',
  slotDuration: '00:30:00',
  allDaySlot: false,
  nowIndicator: true,
  selectable: true,
  selectMirror: true,
  // ✅ Usar función en vez de valor estático para que FullCalendar
  // reciba los eventos actualizados cuando citas.value cambia
  events: (fetchInfo: any, successCallback: (evs: any[]) => void) => {
    successCallback(calEvents.value)
  },
  select: (info: DateSelectArg) => {
    abrirWizard(info.startStr)
  },
  eventClick: (info: EventClickArg) => {
    const cita = info.event.extendedProps.cita as Cita
    verDetalle(cita)
  },
  height: 'auto',
  contentHeight: 600,
}))

// ── Lista ─────────────────────────────────────────────────────────
const today = new Date().toISOString().slice(0, 10)
const listaDesde = ref(today)
const listaHasta = ref(today)
const listaEstado = ref<string>('')

async function recargarLista() {
  await fetchCitas({
    desde: listaDesde.value ? `${listaDesde.value}T00:00:00` : undefined,
    hasta: listaHasta.value ? `${listaHasta.value}T23:59:59` : undefined,
    estado: listaEstado.value as EstadoCita || undefined,
  })
}

// ── Callbacks ─────────────────────────────────────────────────────
async function onCitaCreada() {
  showWizard.value = false
  // Recargar el rango del mes completo (no solo hoy) y refetch en el calendario
  await Promise.all([cargarMes(), recargarLista(), cargarKpis()])
  calRef.value?.getApi().refetchEvents()
}
async function onCitaActualizada() {
  await Promise.all([cargarMes(), recargarLista(), cargarKpis()])
  calRef.value?.getApi().refetchEvents()
}

// Rango del mes visible — compartido entre calendario y onCitaCreada
const mesDesde = ref('')
const mesHasta = ref('')

async function cargarMes(offset = 0) {
  const hoy = new Date()
  const d = new Date(hoy.getFullYear(), hoy.getMonth() + offset, 1)
  mesDesde.value = d.toISOString()
  mesHasta.value = new Date(d.getFullYear(), d.getMonth() + 1, 0, 23, 59, 59).toISOString()
  await fetchCitas({ desde: mesDesde.value, hasta: mesHasta.value })
  // Forzar a FullCalendar a re-renderizar los eventos
  calRef.value?.getApi().refetchEvents()
}

onMounted(async () => {
  await cargarMes()
  await cargarKpis()
})
</script>

<style scoped>
.citas-page { padding: 24px; max-width: 1300px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px; gap: 12px; flex-wrap: wrap; }
.page-header h1 { font-size: 26px; font-weight: 700; color: var(--foreground); margin: 0; }
.page-sub { color: var(--muted-foreground); font-size: 14px; margin: 4px 0 0; }
.header-actions { display: flex; align-items: center; gap: 10px; }

/* View toggle */
.view-toggle { display: flex; border: 1.5px solid var(--border); border-radius: var(--radius); overflow: hidden; }
.toggle-btn { display: flex; align-items: center; gap: 6px; padding: 7px 14px; background: transparent; border: none; color: var(--muted-foreground); font-size: 13px; font-weight: 600; cursor: pointer; transition: all .15s; }
.toggle-btn.active { background: var(--primary); color: white; }

/* KPIs */
.kpis-row { display: grid; grid-template-columns: repeat(4, 1fr); gap: 12px; margin-bottom: 20px; }
.kpi-card { background: var(--card); border: 1px solid var(--border); border-radius: var(--radius); padding: 16px 20px; }
.kpi-val { font-size: 26px; font-weight: 800; color: var(--foreground); line-height: 1.1; }
.kpi-lbl { font-size: 12px; color: var(--muted-foreground); margin-top: 4px; }
.text-amber { color: #f59e0b; }
.text-green { color: #10b981; }
.text-primary { color: var(--primary); }

/* Calendar */
.calendar-wrap { padding: 16px; }
:deep(.fc) { font-family: inherit; }
:deep(.fc-toolbar-title) { font-size: 18px; font-weight: 700; color: var(--foreground); }
:deep(.fc-button-primary) {
  background: var(--primary) !important; border-color: var(--primary) !important;
  font-size: 13px !important; padding: 6px 12px !important;
}
:deep(.fc-button-primary:not(.fc-button-active):hover) { opacity: .85; }
:deep(.fc-button-active) { background: var(--primary-hover, #7c3aed) !important; }
:deep(.fc-event) { border-radius: 6px; padding: 2px 6px; font-size: 12px; cursor: pointer; }
:deep(.fc-event:hover) { filter: brightness(1.1); }
:deep(.fc-timegrid-slot) { height: 36px; }
:deep(.fc-now-indicator-line) { border-color: #ef4444; border-width: 2px; }
:deep(.fc-daygrid-day-number, .fc-col-header-cell-cushion) { color: var(--foreground); }
:deep(.fc-theme-standard td, .fc-theme-standard th) { border-color: var(--border); }
:deep(.fc-highlight) { background: color-mix(in srgb, var(--primary) 15%, transparent); }
:deep(.ev-cancelada) { opacity: .45; text-decoration: line-through; }
:deep(.ev-completada) { opacity: .7; }

/* Lista */
.lista-toolbar { display: flex; gap: 12px; align-items: flex-end; flex-wrap: wrap; padding: 16px; border-bottom: 1px solid var(--border); }
.field-inline { display: flex; flex-direction: column; gap: 4px; }
.field-inline label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .05em; color: var(--muted-foreground); }
.field-inline input, .field-inline select { padding: 7px 10px; border: 1.5px solid var(--border); border-radius: var(--radius); background: var(--background); color: var(--foreground); font-size: 13px; }

.spa-table { width: 100%; border-collapse: collapse; min-width: 800px; }
.spa-table th { padding: 11px 16px; text-align: left; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .06em; color: var(--muted-foreground); border-bottom: 2px solid var(--border); }
.spa-table td { padding: 13px 16px; border-bottom: 1px solid var(--border); vertical-align: middle; }
.cita-row { cursor: pointer; transition: background .1s; }
.cita-row:hover { background: var(--muted); }
.folio-cell { font-family: monospace; font-size: 12px; color: var(--muted-foreground); }
.terapeuta-mini { display: flex; align-items: center; gap: 6px; font-size: 13px; }
.t-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
.fecha-line { font-size: 13px; font-weight: 600; color: var(--foreground); }
.hora-line { font-size: 12px; color: var(--muted-foreground); }
.servicios-names { font-size: 12px; color: var(--muted-foreground); max-width: 220px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.font-medium { font-weight: 600; font-size: 14px; }
.font-bold { font-weight: 700; }
.muted { color: var(--muted-foreground); font-size: 13px; }
.empty-row { text-align: center; padding: 40px; color: var(--muted-foreground); }
.text-center { text-align: center; }
.p-8 { padding: 32px; }
.mx-auto { margin: 0 auto; }
.actions-cell { display: flex; justify-content: flex-end; }
.icon-btn { display: inline-flex; align-items: center; justify-content: center; width: 32px; height: 32px; border-radius: 8px; border: 1px solid var(--border); background: transparent; color: var(--muted-foreground); cursor: pointer; transition: all .15s; }
.icon-btn:hover { background: var(--muted); color: var(--foreground); }
.spinner { width: 28px; height: 28px; border: 3px solid var(--border); border-top-color: var(--primary); border-radius: 50%; animation: spin .6s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }

/* Estado badges */
.estado-badge { display: inline-block; padding: 3px 10px; border-radius: 999px; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .04em; }
.badge-agendada   { background: #dbeafe; color: #1d4ed8; }
.badge-confirmada { background: #d1fae5; color: #065f46; }
.badge-en-curso   { background: #fef3c7; color: #92400e; }
.badge-completada { background: #e0e7ff; color: #3730a3; }
.badge-cancelada  { background: #fee2e2; color: #991b1b; }
.badge-no-show    { background: #f3f4f6; color: #4b5563; }
:is(.dark) .badge-agendada   { background: #1e3a5f; color: #93c5fd; }
:is(.dark) .badge-confirmada { background: #064e3b; color: #6ee7b7; }
:is(.dark) .badge-en-curso   { background: #451a03; color: #fde68a; }
:is(.dark) .badge-completada { background: #1e1b4b; color: #a5b4fc; }
:is(.dark) .badge-cancelada  { background: #450a0a; color: #fca5a5; }
:is(.dark) .badge-no-show    { background: #1f2937; color: #9ca3af; }

@media (max-width: 900px) {
  .citas-page { padding: 16px; }
  .kpis-row { grid-template-columns: repeat(2, 1fr); }
}
@media (max-width: 560px) {
  .kpis-row { grid-template-columns: 1fr 1fr; }
  .view-toggle span { display: none; }
}
</style>
