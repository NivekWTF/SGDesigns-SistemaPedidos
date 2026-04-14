<template>
  <div class="dashboard-page">
    <!-- Hero saludo -->
    <div class="hero-row">
      <div>
        <h1 class="font-spa-display">Buenos días 🌸</h1>
        <p class="hero-sub">{{ spaNombre }} · {{ fechaHoy }}</p>
      </div>
      <router-link to="/citas" class="btn-primary">
        <Plus class="h-4 w-4" /> Nueva cita
      </router-link>
    </div>

    <!-- KPIs del día -->
    <div class="kpis-grid">
      <div class="kpi-card kpi-primary">
        <div class="kpi-icon-wrap"><CalendarDays class="h-5 w-5"/></div>
        <div class="kpi-content">
          <div class="kpi-val">{{ kpis.citas_agendadas + kpis.citas_confirmadas }}</div>
          <div class="kpi-lbl">Citas pendientes</div>
        </div>
        <div class="kpi-trend" :class="kpis.citas_en_curso > 0 ? 'trend-up' : ''">
          {{ kpis.citas_en_curso }} en curso
        </div>
      </div>
      <div class="kpi-card kpi-green">
        <div class="kpi-icon-wrap"><CheckCircle class="h-5 w-5"/></div>
        <div class="kpi-content">
          <div class="kpi-val">{{ kpis.citas_completadas }}</div>
          <div class="kpi-lbl">Completadas hoy</div>
        </div>
        <div class="kpi-trend">
          {{ kpis.tasa_ocupacion }}% ocupación
        </div>
      </div>
      <div class="kpi-card kpi-amber">
        <div class="kpi-icon-wrap"><DollarSign class="h-5 w-5"/></div>
        <div class="kpi-content">
          <div class="kpi-val">{{ fmt(kpis.total_ingresos) }}</div>
          <div class="kpi-lbl">Ingresos hoy</div>
        </div>
        <div class="kpi-trend">
          Anticipos: {{ fmt(kpis.total_anticipos) }}
        </div>
      </div>
      <div class="kpi-card kpi-rose">
        <div class="kpi-icon-wrap"><Users class="h-5 w-5"/></div>
        <div class="kpi-content">
          <div class="kpi-val">{{ kpis.citas_no_show + kpis.citas_canceladas }}</div>
          <div class="kpi-lbl">Cancelaciones / No show</div>
        </div>
        <div class="kpi-trend">hoy</div>
      </div>
    </div>

    <div class="two-col">
      <!-- Próximas citas -->
      <div class="card-spa proximas-wrap">
        <div class="card-header">
          <h2>Próximas citas</h2>
          <router-link to="/citas" class="ver-todos">Ver agenda →</router-link>
        </div>
        <div v-if="loadingProximas" class="mini-loader"><div class="spinner"/></div>
        <div v-else-if="proximas.length === 0" class="empty-card">
          <CalendarDays class="h-8 w-8 op-30"/>
          <p>Sin citas próximas hoy</p>
        </div>
        <div v-else class="proximas-list">
          <div v-for="c in proximas" :key="c.folio" class="proxima-item">
            <div class="proxima-hora">{{ fmtHora(c.fecha_inicio) }}</div>
            <div class="proxima-info">
              <div class="proxima-cliente">{{ c.cliente_nombre }}</div>
              <div class="proxima-servicios">{{ c.servicios }}</div>
            </div>
            <div v-if="c.personal_nombre" class="proxima-terapeuta">
              <div class="t-dot" :style="{ background: colorTerapeuta(c.personal_nombre) }"/>
              {{ c.personal_nombre }}
            </div>
            <span class="estado-badge" :class="estadoClass(c.estado)">
              {{ estadoLabel(c.estado) }}
            </span>
          </div>
        </div>
      </div>

      <!-- Resumen de caja -->
      <div class="card-spa caja-wrap">
        <div class="card-header">
          <h2>Caja del día</h2>
          <router-link to="/caja" class="ver-todos">Ver caja →</router-link>
        </div>
        <div v-if="loadingCaja" class="mini-loader"><div class="spinner"/></div>
        <div v-else class="caja-stats">
          <div class="caja-row caja-entradas">
            <TrendingUp class="h-4 w-4"/>
            <span>Entradas</span>
            <span class="caja-val green">{{ fmt(cajaDia.total_entradas) }}</span>
          </div>
          <div class="caja-row caja-salidas">
            <TrendingDown class="h-4 w-4"/>
            <span>Salidas</span>
            <span class="caja-val red">{{ fmt(cajaDia.total_salidas) }}</span>
          </div>
          <div class="caja-divider"/>
          <div class="caja-row saldo-row">
            <Wallet class="h-4 w-4"/>
            <span>Saldo neto</span>
            <span class="caja-val" :class="cajaDia.saldo_dia >= 0 ? 'green' : 'red'">
              {{ fmt(cajaDia.saldo_dia) }}
            </span>
          </div>
          <!-- Por método -->
          <div v-if="Object.keys(cajaDia.por_metodo ?? {}).length > 0" class="metodos-list">
            <div class="metodos-title">Por método</div>
            <div v-for="(monto, metodo) in cajaDia.por_metodo" :key="metodo" class="metodo-row">
              <span>{{ metodIcon(metodo) }} {{ metodo }}</span>
              <span class="metodo-val">{{ fmt(Number(monto)) }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Gráfica ingresos últimos 30 días -->
    <div class="card-spa chart-wrap">
      <div class="card-header">
        <h2>Ingresos — últimos 30 días</h2>
        <div class="chart-toggle">
          <button :class="['ctab', chartView === 'dia' && 'active']" @click="chartView = 'dia'">Día</button>
          <button :class="['ctab', chartView === 'semana' && 'active']" @click="chartView = 'semana'">Semana</button>
        </div>
      </div>
      <div v-if="loadingChart" class="mini-loader"><div class="spinner"/></div>
      <div v-else-if="ingresos.length === 0" class="empty-card">
        <BarChart3 class="h-8 w-8 op-30"/><p>Sin datos de ingresos aún</p>
      </div>
      <div v-else class="chart-area">
        <div class="bar-chart">
          <div v-for="item in ingresos" :key="item.periodo" class="bar-col">
            <div class="bar-tooltip">{{ fmt(item.total_ingresos) }}</div>
            <div class="bar" :style="{ height: barHeight(item.total_ingresos) + '%' }" />
            <div class="bar-label">{{ item.periodo.slice(-5) }}</div>
          </div>
        </div>
        <div class="chart-footer">
          Total período: <strong>{{ fmt(totalPeriodo) }}</strong>
          · {{ ingresos.filter(i => i.num_citas > 0).length }} días con actividad
        </div>
      </div>
    </div>

    <!-- Top servicios -->
    <div class="card-spa">
      <div class="card-header">
        <h2>Top servicios del mes</h2>
      </div>
      <div v-if="topServicios.length === 0" class="empty-card">
        <Sparkles class="h-8 w-8 op-30"/><p>Sin datos este mes</p>
      </div>
      <div v-else class="top-servicios-list">
        <div v-for="(s, idx) in topServicios" :key="s.servicio_id" class="top-item">
          <div class="top-rank">#{{ idx + 1 }}</div>
          <div class="top-info">
            <div class="top-nombre">{{ s.nombre }}</div>
            <div class="top-bar-wrap">
              <div class="top-bar" :style="{ width: (s.num_veces / topServicios[0].num_veces * 100) + '%' }"/>
            </div>
          </div>
          <div class="top-nums">
            <span class="top-count">{{ s.num_veces }}×</span>
            <span class="top-ingreso">{{ fmt(s.total_ingreso) }}</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useTenant } from '../composables/useTenant'
import { supabase } from '../lib/supabase'
import {
  CalendarDays, CheckCircle, DollarSign, Users, Plus,
  TrendingUp, TrendingDown, Wallet, BarChart3, Sparkles
} from 'lucide-vue-next'

const { spaId, spaNombre } = useTenant()

const fechaHoy = new Date().toLocaleDateString('es-MX', {
  weekday: 'long', day: 'numeric', month: 'long', year: 'numeric'
})

const fmt = (n: number) =>
  new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(n ?? 0)
const fmtHora = (d: string) =>
  new Date(d).toLocaleTimeString('es-MX', { hour: '2-digit', minute: '2-digit', hour12: false })
const metodIcon = (m: string) =>
  ({ EFECTIVO: '💵', TRANSFERENCIA: '🏦', TARJETA: '💳', OTRO: '🧾' }[m] ?? '💰')

// ── KPIs ─────────────────────────────────────────────────────────
const kpis = ref({
  citas_agendadas: 0, citas_confirmadas: 0, citas_en_curso: 0,
  citas_completadas: 0, citas_canceladas: 0, citas_no_show: 0,
  total_ingresos: 0, total_anticipos: 0, tasa_ocupacion: 0,
})

// ── Próximas ─────────────────────────────────────────────────────
const proximas = ref<any[]>([])
const loadingProximas = ref(false)

// ── Caja ──────────────────────────────────────────────────────────
const cajaDia = ref<any>({ total_entradas: 0, total_salidas: 0, saldo_dia: 0, por_metodo: {} })
const loadingCaja = ref(false)

// ── Chart ─────────────────────────────────────────────────────────
const ingresos = ref<any[]>([])
const loadingChart = ref(false)
const chartView = ref<'dia' | 'semana'>('dia')
const totalPeriodo = computed(() => ingresos.value.reduce((s, i) => s + i.total_ingresos, 0))
const maxIngreso = computed(() => Math.max(...ingresos.value.map(i => i.total_ingresos), 1))
const barHeight = (n: number) => Math.max(4, (n / maxIngreso.value) * 100)

// ── Top Servicios ─────────────────────────────────────────────────
const topServicios = ref<any[]>([])

// ── Helpers estado ────────────────────────────────────────────────
const TERAPEUTA_COLORS: Record<string, string> = {}
const COLOR_LIST = ['#8b5cf6','#ec4899','#f59e0b','#10b981','#3b82f6','#ef4444']
function colorTerapeuta(nombre: string) {
  if (!TERAPEUTA_COLORS[nombre]) {
    const idx = Object.keys(TERAPEUTA_COLORS).length % COLOR_LIST.length
    TERAPEUTA_COLORS[nombre] = COLOR_LIST[idx]
  }
  return TERAPEUTA_COLORS[nombre]
}
function estadoLabel(e: string) {
  const M: Record<string, string> = { AGENDADA: 'Agendada', CONFIRMADA: 'Confirmada', EN_CURSO: 'En curso', COMPLETADA: 'Completada', CANCELADA: 'Cancelada', NO_SHOW: 'No show' }
  return M[e] ?? e
}
function estadoClass(e: string) {
  const M: Record<string, string> = { AGENDADA: 'badge-agendada', CONFIRMADA: 'badge-confirmada', EN_CURSO: 'badge-en-curso', COMPLETADA: 'badge-completada', CANCELADA: 'badge-cancelada', NO_SHOW: 'badge-no-show' }
  return M[e]
}

async function cargarDatos() {
  if (!spaId.value) return
  const id = spaId.value
  const hoy = new Date().toISOString().slice(0, 10)
  const hace30 = new Date(Date.now() - 30 * 86400000).toISOString().slice(0, 10)
  const mesInicio = new Date(new Date().getFullYear(), new Date().getMonth(), 1).toISOString().slice(0, 10)

  // KPIs
  const { data: k } = await supabase.rpc('get_kpis_dia', { p_spa_id: id })
  if (k?.[0]) Object.assign(kpis.value, k[0])

  // Próximas 3 horas
  loadingProximas.value = true
  const { data: p } = await supabase.rpc('get_proximas_citas', { p_spa_id: id, p_horas: 5 })
  proximas.value = p ?? []
  loadingProximas.value = false

  // Caja
  loadingCaja.value = true
  const { data: c } = await supabase.rpc('get_resumen_caja_dia', { p_spa_id: id })
  if (c?.[0]) cajaDia.value = c[0]
  loadingCaja.value = false

  // Ingresos últimos 30 días
  loadingChart.value = true
  const { data: ing } = await supabase.rpc('get_ingresos_periodo', {
    p_spa_id: id, p_desde: hace30, p_hasta: hoy, p_agrupacion: chartView.value
  })
  ingresos.value = ing ?? []
  loadingChart.value = false

  // Top servicios
  const { data: top } = await supabase.rpc('get_top_servicios', {
    p_spa_id: id, p_desde: mesInicio, p_hasta: hoy, p_limit: 7
  })
  topServicios.value = top ?? []
}

onMounted(cargarDatos)
</script>

<style scoped>
.dashboard-page { padding: 24px; max-width: 1200px; display: flex; flex-direction: column; gap: 20px; }

/* Hero */
.hero-row { display: flex; align-items: center; justify-content: space-between; gap: 12px; flex-wrap: wrap; }
.hero-row h1 { font-size: 28px; font-weight: 800; color: var(--foreground); margin: 0; }
.hero-sub { font-size: 14px; color: var(--muted-foreground); margin: 4px 0 0; text-transform: capitalize; }

/* KPIs */
.kpis-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 14px; }
.kpi-card {
  border-radius: var(--radius); padding: 18px 20px;
  display: flex; flex-direction: column; gap: 8px;
  position: relative; overflow: hidden;
  transition: transform .2s, box-shadow .2s;
}
.kpi-card:hover { transform: translateY(-2px); box-shadow: 0 8px 24px rgba(0,0,0,.12); }
.kpi-primary { background: linear-gradient(135deg, var(--primary) 0%, #7c3aed 100%); color: white; }
.kpi-green   { background: linear-gradient(135deg, #10b981 0%, #059669 100%); color: white; }
.kpi-amber   { background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%); color: white; }
.kpi-rose    { background: linear-gradient(135deg, #f43f5e 0%, #e11d48 100%); color: white; }
.kpi-icon-wrap { opacity: .7; }
.kpi-content { flex: 1; }
.kpi-val { font-size: 28px; font-weight: 800; line-height: 1; }
.kpi-lbl { font-size: 12px; opacity: .85; margin-top: 3px; }
.kpi-trend { font-size: 11px; opacity: .8; font-weight: 600; }
.trend-up { opacity: 1 !important; }

/* Two col */
.two-col { display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }

/* Card header */
.card-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 14px; }
.card-header h2 { font-size: 15px; font-weight: 700; color: var(--foreground); margin: 0; }
.ver-todos { font-size: 13px; color: var(--primary); font-weight: 600; text-decoration: none; }
.ver-todos:hover { text-decoration: underline; }

/* Próximas */
.proximas-list { display: flex; flex-direction: column; gap: 0; }
.proxima-item {
  display: flex; align-items: center; gap: 10px;
  padding: 10px 0; border-bottom: 1px solid var(--border);
}
.proxima-item:last-child { border-bottom: none; }
.proxima-hora { font-size: 14px; font-weight: 800; color: var(--primary); min-width: 48px; font-family: monospace; }
.proxima-info { flex: 1; min-width: 0; }
.proxima-cliente { font-weight: 600; font-size: 14px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.proxima-servicios { font-size: 12px; color: var(--muted-foreground); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.proxima-terapeuta { display: flex; align-items: center; gap: 5px; font-size: 12px; color: var(--muted-foreground); white-space: nowrap; }
.t-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }

/* Caja */
.caja-stats { display: flex; flex-direction: column; gap: 10px; }
.caja-row { display: flex; align-items: center; gap: 8px; font-size: 14px; color: var(--foreground); }
.caja-row svg { color: var(--muted-foreground); flex-shrink: 0; }
.caja-row span:nth-child(2) { flex: 1; }
.caja-val { font-weight: 700; font-size: 16px; }
.green { color: #10b981; }
.red   { color: #ef4444; }
.caja-divider { border-top: 1px dashed var(--border); }
.saldo-row { padding-top: 4px; }
.metodos-list { margin-top: 4px; padding: 10px; background: var(--muted); border-radius: var(--radius); display: flex; flex-direction: column; gap: 6px; }
.metodos-title { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .06em; color: var(--muted-foreground); }
.metodo-row { display: flex; justify-content: space-between; font-size: 13px; }
.metodo-val { font-weight: 600; }

/* Chart */
.chart-toggle { display: flex; gap: 0; border: 1.5px solid var(--border); border-radius: var(--radius); overflow: hidden; }
.ctab { padding: 4px 12px; background: transparent; border: none; color: var(--muted-foreground); font-size: 12px; font-weight: 700; cursor: pointer; }
.ctab.active { background: var(--primary); color: white; }
.chart-area { display: flex; flex-direction: column; gap: 8px; }
.bar-chart { display: flex; align-items: flex-end; gap: 3px; height: 140px; padding-bottom: 24px; position: relative; overflow-x: auto; }
.bar-col { display: flex; flex-direction: column; align-items: center; gap: 4px; min-width: 24px; flex: 1; position: relative; }
.bar-col:hover .bar-tooltip { display: block; }
.bar-tooltip { display: none; position: absolute; bottom: calc(100% + 4px); background: var(--foreground); color: var(--background); font-size: 10px; padding: 3px 6px; border-radius: 4px; white-space: nowrap; z-index: 10; }
.bar { width: 100%; border-radius: 4px 4px 0 0; background: var(--primary); opacity: .85; transition: opacity .2s; min-height: 4px; }
.bar-col:hover .bar { opacity: 1; }
.bar-label { font-size: 9px; color: var(--muted-foreground); position: absolute; bottom: 0; }
.chart-footer { font-size: 13px; color: var(--muted-foreground); text-align: right; }

/* Top Servicios */
.top-servicios-list { display: flex; flex-direction: column; gap: 10px; }
.top-item { display: flex; align-items: center; gap: 12px; }
.top-rank { font-size: 16px; font-weight: 800; color: var(--muted-foreground); min-width: 28px; text-align: center; }
.top-info { flex: 1; display: flex; flex-direction: column; gap: 4px; }
.top-nombre { font-size: 14px; font-weight: 600; color: var(--foreground); }
.top-bar-wrap { height: 6px; background: var(--muted); border-radius: 3px; overflow: hidden; }
.top-bar { height: 100%; background: var(--primary); border-radius: 3px; transition: width .6s ease; }
.top-nums { display: flex; flex-direction: column; align-items: flex-end; gap: 2px; }
.top-count { font-size: 13px; color: var(--muted-foreground); }
.top-ingreso { font-size: 14px; font-weight: 700; color: var(--foreground); }

/* Common */
.mini-loader { padding: 32px; display: flex; justify-content: center; }
.spinner { width: 28px; height: 28px; border: 3px solid var(--border); border-top-color: var(--primary); border-radius: 50%; animation: spin .6s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
.empty-card { padding: 40px; text-align: center; display: flex; flex-direction: column; align-items: center; gap: 10px; color: var(--muted-foreground); font-size: 14px; }
.op-30 { opacity: .3; }

/* Estado badges */
.estado-badge { display: inline-block; padding: 2px 8px; border-radius: 999px; font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: .04em; white-space: nowrap; }
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
  .kpis-grid { grid-template-columns: repeat(2, 1fr); }
  .two-col { grid-template-columns: 1fr; }
}
@media (max-width: 560px) {
  .dashboard-page { padding: 16px; }
  .kpis-grid { grid-template-columns: 1fr 1fr; gap: 10px; }
  .kpi-val { font-size: 22px; }
}
</style>
