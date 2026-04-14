<template>
  <Teleport to="body">
    <div class="modal-backdrop" @click.self="$emit('close')">
      <div class="detail-box">
        <!-- Header -->
        <div class="detail-header">
          <div>
            <div class="folio-label">{{ cita.folio ?? 'Sin folio' }}</div>
            <span class="estado-badge" :class="estadoClass(cita.estado)">{{ estadoLabel(cita.estado) }}</span>
          </div>
          <button class="icon-btn" @click="$emit('close')"><X class="h-5 w-5" /></button>
        </div>

        <div class="detail-body">
          <!-- Info principal -->
          <div class="info-grid">
            <div class="info-block">
              <div class="info-lbl">👤 Cliente</div>
              <div class="info-val">{{ cita.clientes?.nombre }}</div>
              <div v-if="cita.clientes?.telefono" class="info-sub">{{ cita.clientes.telefono }}</div>
            </div>
            <div class="info-block">
              <div class="info-lbl">💆 Terapeuta</div>
              <div v-if="cita.personal" class="info-val flex-row">
                <div class="t-dot" :style="{ background: cita.personal.color_agenda }"/>
                {{ cita.personal.nombre }}
              </div>
              <div v-else class="info-sub">Sin asignar</div>
            </div>
            <div class="info-block">
              <div class="info-lbl">📅 Fecha y hora</div>
              <div class="info-val">{{ fmtFecha(cita.fecha_inicio) }}</div>
              <div class="info-sub">{{ fmtHora(cita.fecha_inicio) }} – {{ fmtHora(cita.fecha_fin) }}</div>
            </div>
            <div class="info-block">
              <div class="info-lbl">💰 Total</div>
              <div class="info-val text-primary">{{ fmt(cita.total) }}</div>
              <div v-if="cita.anticipo > 0" class="info-sub">Anticipo: {{ fmt(cita.anticipo) }}</div>
            </div>
          </div>

          <!-- Servicios -->
          <div class="section">
            <div class="section-title">Servicios contratados</div>
            <div class="items-list">
              <div v-for="item in cita.cita_items" :key="item.id" class="item-row">
                <div class="item-name">{{ item.servicios?.nombre ?? item.descripcion_personalizada ?? '?' }}</div>
                <div class="item-meta">{{ item.cantidad }} × {{ fmt(item.precio_unitario) }}</div>
                <div class="item-sub">{{ fmt(item.subtotal) }}</div>
              </div>
            </div>
          </div>

          <!-- Pagos -->
          <div class="section">
            <div class="section-title-row">
              <span class="section-title">Pagos registrados</span>
              <button class="btn-ghost btn-sm" @click="showPagoForm = !showPagoForm">
                <Plus class="h-3.5 w-3.5"/> Agregar pago
              </button>
            </div>
            <div v-if="showPagoForm" class="pago-form">
              <div class="fields-row">
                <div class="field">
                  <label>Monto</label>
                  <div class="input-prefix"><span>$</span><input v-model.number="pagoForm.monto" type="number" min="0" step="0.01"/></div>
                </div>
                <div class="field">
                  <label>Método</label>
                  <select v-model="pagoForm.metodo">
                    <option value="EFECTIVO">💵 Efectivo</option>
                    <option value="TRANSFERENCIA">🏦 Transferencia</option>
                    <option value="TARJETA">💳 Tarjeta</option>
                    <option value="OTRO">Otro</option>
                  </select>
                </div>
              </div>
              <button class="btn-primary btn-sm" @click="hacerPago" :disabled="pagoForm.monto <= 0">
                <Loader2 v-if="savingPago" class="h-3.5 w-3.5 animate-spin"/> Registrar pago
              </button>
            </div>
            <div v-if="(cita.pagos_cita ?? []).length === 0" class="empty-pagos">Sin pagos registrados</div>
            <div v-for="p in cita.pagos_cita" :key="p.id" class="pago-row">
              <div class="pago-icon">{{ metodIcon(p.metodo) }}</div>
              <div class="pago-info">
                <span class="pago-monto">{{ fmt(p.monto) }}</span>
                <span class="pago-meta">{{ p.metodo }} · {{ fmtShort(p.creado_en) }}</span>
              </div>
              <span v-if="p.es_anticipo" class="anticipo-tag">anticipo</span>
            </div>
            <div class="saldo-row">
              <span>Saldo pendiente</span>
              <span :class="saldoPendiente <= 0 ? 'text-green' : 'font-bold'">{{ fmt(Math.max(0, saldoPendiente)) }}</span>
            </div>
          </div>

          <!-- Cambiar estado -->
          <div class="section">
            <div class="section-title">Cambiar estado</div>
            <div class="estado-btns">
              <button
                v-for="e in estadosDisponibles" :key="e.value"
                class="estado-action-btn" :class="e.cls"
                @click="cambiarEstado(e.value)"
                :disabled="cambiandoEstado"
              >{{ e.icon }} {{ e.label }}</button>
            </div>
          </div>

          <!-- Notas -->
          <div v-if="cita.notas || cita.notas_internas" class="section">
            <div class="section-title">Notas</div>
            <div v-if="cita.notas" class="notas-text">📋 {{ cita.notas }}</div>
            <div v-if="cita.notas_internas" class="notas-text muted">🔒 {{ cita.notas_internas }}</div>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { X, Plus, Loader2 } from 'lucide-vue-next'
import { useCitas } from '../composables/useCitas'
import type { Cita, EstadoCita, MetodoPago } from '../composables/useCitas'

const props = defineProps<{ cita: Cita }>()
const emit = defineEmits(['close', 'updated'])

const { actualizarEstado, registrarPago } = useCitas()

function fmt(n: number) { return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(n) }
function fmtFecha(d: string) { return new Date(d).toLocaleDateString('es-MX', { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' }) }
function fmtHora(d: string) { return new Date(d).toLocaleTimeString('es-MX', { hour: '2-digit', minute: '2-digit', hour12: false }) }
function fmtShort(d: string) { return new Date(d).toLocaleDateString('es-MX', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }) }
function metodIcon(m: MetodoPago) { return { EFECTIVO: '💵', TRANSFERENCIA: '🏦', TARJETA: '💳', OTRO: '🧾' }[m] ?? '💰' }

const saldoPendiente = computed(() => {
  const pagado = (props.cita.pagos_cita ?? []).reduce((s, p) => s + p.monto, 0)
  return props.cita.total - pagado
})

function estadoLabel(e: EstadoCita) {
  const M: Record<EstadoCita, string> = { AGENDADA: 'Agendada', CONFIRMADA: 'Confirmada', EN_CURSO: 'En curso', COMPLETADA: 'Completada', CANCELADA: 'Cancelada', NO_SHOW: 'No show' }
  return M[e]
}
function estadoClass(e: EstadoCita) {
  const M: Record<EstadoCita, string> = { AGENDADA: 'badge-agendada', CONFIRMADA: 'badge-confirmada', EN_CURSO: 'badge-en-curso', COMPLETADA: 'badge-completada', CANCELADA: 'badge-cancelada', NO_SHOW: 'badge-no-show' }
  return M[e]
}

const ESTADOS_CONFIG: Array<{ value: EstadoCita; label: string; icon: string; cls: string; validDesde: EstadoCita[] }> = [
  { value: 'CONFIRMADA', label: 'Confirmar',   icon: '✅', cls: 'btn-confirmada', validDesde: ['AGENDADA'] },
  { value: 'EN_CURSO',   label: 'Iniciar',     icon: '▶️', cls: 'btn-en-curso',   validDesde: ['AGENDADA', 'CONFIRMADA'] },
  { value: 'COMPLETADA', label: 'Completar',   icon: '🏁', cls: 'btn-completada', validDesde: ['EN_CURSO', 'CONFIRMADA'] },
  { value: 'CANCELADA',  label: 'Cancelar',    icon: '❌', cls: 'btn-cancelada',  validDesde: ['AGENDADA', 'CONFIRMADA'] },
  { value: 'NO_SHOW',    label: 'No show',     icon: '👻', cls: 'btn-no-show',    validDesde: ['AGENDADA', 'CONFIRMADA'] },
]
const estadosDisponibles = computed(() =>
  ESTADOS_CONFIG.filter(e => e.validDesde.includes(props.cita.estado) && e.value !== props.cita.estado)
)

const cambiandoEstado = ref(false)
async function cambiarEstado(estado: EstadoCita) {
  cambiandoEstado.value = true
  try {
    await actualizarEstado(props.cita.id, estado)
    emit('updated')
    emit('close')
  } finally { cambiandoEstado.value = false }
}

// Pago
const showPagoForm = ref(false)
const savingPago = ref(false)
const pagoForm = ref({ monto: 0, metodo: 'EFECTIVO' as MetodoPago })

async function hacerPago() {
  if (pagoForm.value.monto <= 0) return
  savingPago.value = true
  try {
    await registrarPago(props.cita.id, pagoForm.value)
    showPagoForm.value = false
    pagoForm.value = { monto: 0, metodo: 'EFECTIVO' }
    emit('updated')
  } finally { savingPago.value = false }
}
</script>

<style scoped>
.modal-backdrop { position: fixed; inset: 0; background: rgba(0,0,0,.45); backdrop-filter: blur(4px); z-index: 250; display: flex; align-items: center; justify-content: center; padding: 16px; }
.detail-box { background: var(--card); border-radius: 16px; width: 100%; max-width: 560px; max-height: 92vh; overflow-y: auto; box-shadow: 0 24px 80px rgba(0,0,0,.3); }

.detail-header { display: flex; align-items: center; justify-content: space-between; padding: 20px 24px; border-bottom: 1px solid var(--border); }
.folio-label { font-family: monospace; font-size: 12px; color: var(--muted-foreground); margin-bottom: 4px; }
.icon-btn { display: inline-flex; align-items: center; justify-content: center; width: 34px; height: 34px; border-radius: 8px; border: 1px solid var(--border); background: transparent; color: var(--muted-foreground); cursor: pointer; }
.icon-btn:hover { background: var(--muted); }

.detail-body { padding: 20px 24px; display: flex; flex-direction: column; gap: 20px; }

/* Info grid */
.info-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
.info-block { display: flex; flex-direction: column; gap: 2px; }
.info-lbl { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .06em; color: var(--muted-foreground); }
.info-val { font-size: 15px; font-weight: 700; color: var(--foreground); }
.info-sub { font-size: 12px; color: var(--muted-foreground); }
.flex-row { display: flex; align-items: center; gap: 6px; }
.t-dot { width: 10px; height: 10px; border-radius: 50%; flex-shrink: 0; }
.text-primary { color: var(--primary); }

/* Sections */
.section { display: flex; flex-direction: column; gap: 8px; }
.section-title { font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: .06em; color: var(--muted-foreground); }
.section-title-row { display: flex; align-items: center; justify-content: space-between; }

/* Items */
.items-list { display: flex; flex-direction: column; gap: 4px; }
.item-row { display: flex; align-items: center; gap: 10px; padding: 8px 0; border-bottom: 1px dashed var(--border); }
.item-row:last-child { border-bottom: none; }
.item-name { flex: 1; font-weight: 600; font-size: 14px; }
.item-meta { font-size: 12px; color: var(--muted-foreground); }
.item-sub { font-weight: 700; font-size: 14px; }

/* Pagos */
.pago-form { background: var(--muted); border-radius: var(--radius); padding: 12px; display: flex; flex-direction: column; gap: 10px; }
.empty-pagos { font-size: 13px; color: var(--muted-foreground); font-style: italic; }
.pago-row { display: flex; align-items: center; gap: 10px; padding: 8px 0; border-bottom: 1px dashed var(--border); }
.pago-row:last-child { border-bottom: none; }
.pago-icon { font-size: 18px; }
.pago-info { flex: 1; display: flex; flex-direction: column; gap: 1px; }
.pago-monto { font-weight: 700; font-size: 14px; color: var(--foreground); }
.pago-meta { font-size: 12px; color: var(--muted-foreground); }
.anticipo-tag { padding: 2px 8px; border-radius: 999px; background: var(--secondary); color: var(--secondary-foreground); font-size: 10px; font-weight: 700; text-transform: uppercase; }
.saldo-row { display: flex; justify-content: space-between; padding-top: 8px; font-size: 14px; font-weight: 600; color: var(--foreground); border-top: 2px solid var(--border); }
.text-green { color: #10b981; font-weight: 700; }
.font-bold { font-weight: 700; color: #ef4444; }

/* Estados */
.estado-btns { display: flex; gap: 8px; flex-wrap: wrap; }
.estado-action-btn { padding: 8px 14px; border-radius: 999px; border: none; font-size: 13px; font-weight: 700; cursor: pointer; transition: all .15s; }
.btn-confirmada { background: #d1fae5; color: #065f46; }
.btn-en-curso   { background: #fef3c7; color: #92400e; }
.btn-completada { background: #e0e7ff; color: #3730a3; }
.btn-cancelada  { background: #fee2e2; color: #991b1b; }
.btn-no-show    { background: #f3f4f6; color: #4b5563; }
:is(.dark) .btn-confirmada { background: #064e3b; color: #6ee7b7; }
:is(.dark) .btn-en-curso   { background: #451a03; color: #fde68a; }
:is(.dark) .btn-completada { background: #1e1b4b; color: #a5b4fc; }
:is(.dark) .btn-cancelada  { background: #450a0a; color: #fca5a5; }
:is(.dark) .btn-no-show    { background: #1f2937; color: #9ca3af; }

/* Notas */
.notas-text { font-size: 13px; color: var(--foreground); padding: 10px 12px; background: var(--muted); border-radius: var(--radius); }
.muted { color: var(--muted-foreground) !important; }

/* Estado badges */
.estado-badge { display: inline-block; padding: 4px 12px; border-radius: 999px; font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: .04em; }
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

/* Forms */
.field { display: flex; flex-direction: column; gap: 5px; }
.field label { font-size: 12px; font-weight: 600; color: var(--foreground); }
.field input, .field select { padding: 8px 10px; border: 1.5px solid var(--border); border-radius: var(--radius); background: var(--background); color: var(--foreground); font-size: 13px; }
.field input:focus, .field select:focus { outline: none; border-color: var(--primary); }
.fields-row { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
.input-prefix { display: flex; }
.input-prefix span { padding: 8px 8px; background: var(--muted); border: 1.5px solid var(--border); border-right: none; border-radius: var(--radius) 0 0 var(--radius); color: var(--muted-foreground); font-size: 13px; }
.input-prefix input { border-radius: 0 var(--radius) var(--radius) 0; flex: 1; min-width: 0; }
.btn-sm { font-size: 12px; padding: 6px 12px; }

@media (max-width: 560px) { .info-grid { grid-template-columns: 1fr; } }
</style>
