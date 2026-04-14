<template>
  <Teleport to="body">
    <div class="wizard-backdrop">
      <div class="wizard-box">

        <!-- Header -->
        <div class="wizard-header">
          <div>
            <h2 class="font-spa-display">Nueva cita</h2>
            <p class="wizard-sub">Paso {{ paso }} de 4 — {{ pasoLabel }}</p>
          </div>
          <button class="icon-btn" @click="$emit('close')"><X class="h-5 w-5" /></button>
        </div>

        <!-- Stepper -->
        <div class="stepper">
          <div v-for="n in 4" :key="n" class="step-item">
            <div class="step-circle" :class="n < paso ? 'done' : n === paso ? 'active' : ''">
              <Check v-if="n < paso" class="h-3 w-3" />
              <span v-else>{{ n }}</span>
            </div>
            <div class="step-connector" v-if="n < 4" :class="n < paso && 'done'" />
          </div>
        </div>

        <!-- Paso 1: Cliente -->
        <div v-if="paso === 1" class="paso-body">
          <h3>¿Quién es la cliente?</h3>
          <div class="search-wrap">
            <Search class="search-icon h-4 w-4" />
            <input v-model="clienteBusq" @input="buscarClientes" class="search-input"
              placeholder="Buscar por nombre o teléfono..." />
          </div>
          <div class="resultados" v-if="clientesResultados.length > 0">
            <button
              v-for="c in clientesResultados" :key="c.id"
              class="resultado-item" :class="sel.clienteId === c.id && 'selected'"
              @click="seleccionarCliente(c)"
            >
              <div class="resultado-avatar" :style="avatarStyle(c.nombre)">{{ initials(c.nombre) }}</div>
              <div>
                <div class="resultado-nombre">{{ c.nombre }}</div>
                <div class="resultado-meta">{{ c.telefono ?? c.correo ?? '' }}</div>
              </div>
              <Check v-if="sel.clienteId === c.id" class="h-4 w-4 ml-auto text-primary" />
            </button>
          </div>
          <div v-else-if="clienteBusq.length >= 2" class="empty-search">
            <p>No encontramos "{{ clienteBusq }}"</p>
            <button class="btn-ghost" @click="crearClienteRapido">+ Crear nuevo cliente</button>
          </div>
          <!-- Mini form crear cliente -->
          <div v-if="showNuevoCliente" class="nuevo-cliente-form">
            <div class="fields-row">
              <div class="field"><label>Nombre *</label><input v-model="nuevoCliente.nombre" required /></div>
              <div class="field"><label>Teléfono</label><input v-model="nuevoCliente.telefono" /></div>
            </div>
            <div class="field"><label>Correo</label><input v-model="nuevoCliente.correo" type="email" /></div>
            <div class="field"><label>Alergias / Notas</label><input v-model="nuevoCliente.notas_preferencias" /></div>
            <button class="btn-primary btn-sm" @click="guardarNuevoCliente" :disabled="!nuevoCliente.nombre">
              Guardar y seleccionar
            </button>
          </div>
        </div>

        <!-- Paso 2: Servicios -->
        <div v-if="paso === 2" class="paso-body">
          <h3>¿Qué servicios?</h3>
          <div class="filter-tabs">
            <button
              v-for="cat in [{ value: '', label: 'Todos', emoji: '🌿' }, ...CATEGORIAS_SERVICIO]"
              :key="cat.value"
              :class="['tab-btn', filtroSvc === cat.value && 'active']"
              @click="filtroSvc = cat.value"
            >{{ cat.emoji }} {{ cat.label }}</button>
          </div>
          <div class="servicios-lista">
            <button
              v-for="s in serviciosFiltrados" :key="s.id"
              class="svc-item" :class="serviceSelected(s.id) && 'selected'"
              @click="toggleServicio(s)"
            >
              <div class="svc-info">
                <span class="svc-nombre">{{ s.nombre }}</span>
                <span class="svc-meta">{{ s.duracion_min }} min · {{ fmt(s.precio) }}</span>
              </div>
              <div class="svc-check-icon"><Check v-if="serviceSelected(s.id)" class="h-4 w-4" /></div>
            </button>
          </div>
          <div v-if="sel.servicios.length > 0" class="servicios-seleccionados">
            <p class="sel-label">Seleccionados ({{ sel.servicios.length }})</p>
            <div class="sel-chips">
              <span v-for="s in sel.servicios" :key="s.id" class="sel-chip">
                {{ s.nombre }}
                <button @click="toggleServicio(s)" class="chip-remove">×</button>
              </span>
            </div>
            <div class="sel-totales">
              <span><Clock class="h-3.5 w-3.5" /> {{ totalDuracion }} min</span>
              <span class="sep">·</span>
              <span class="font-bold">{{ fmt(totalPrecio) }}</span>
            </div>
          </div>
        </div>

        <!-- Paso 3: Terapeuta & Fecha/Hora -->
        <div v-if="paso === 3" class="paso-body">
          <h3>¿Cuándo y con quién?</h3>
          <div class="fields-row">
            <div class="field">
              <label>Fecha *</label>
              <input type="date" v-model="sel.fecha" :min="hoy" @change="cargarSlots" />
            </div>
            <div class="field">
              <label>Terapeuta</label>
              <select v-model="sel.personalId" @change="cargarSlots">
                <option value="">Cualquiera disponible</option>
                <option v-for="t in personal" :key="t.id" :value="t.id">{{ t.nombre }}</option>
              </select>
            </div>
          </div>

          <!-- Slots disponibles -->
          <div v-if="loadingSlots" class="hint-text mt-2">
            <div class="spinner-sm"/> Consultando disponibilidad...
          </div>
          <div v-else-if="sel.fecha" class="slots-wrap">
            <p class="hint-text">Selecciona un horario disponible:</p>
            <div v-if="slots.length === 0" class="empty-slots">
              Sin disponibilidad para este día. Prueba otra fecha o terapeuta.
            </div>
            <div v-else class="slots-grid">
              <button
                v-for="sl in slots" :key="sl.slot_inicio"
                class="slot-btn"
                :class="sel.slotInicio === sl.slot_inicio && 'selected'"
                @click="seleccionarSlot(sl)"
              >
                {{ fmtHora(sl.slot_inicio) }}
              </button>
            </div>
          </div>

          <div class="field mt-4">
            <label>Notas de la cita</label>
            <textarea v-model="sel.notas" rows="2" placeholder="Indicaciones especiales, preferencias..."/>
          </div>
        </div>

        <!-- Paso 4: Pago inicial (anticipo) -->
        <div v-if="paso === 4" class="paso-body">
          <h3>Resumen y pago inicial</h3>
          <div class="resumen-card">
            <div class="resumen-row"><span>Cliente</span><span class="rval">{{ clienteSeleccionado?.nombre }}</span></div>
            <div class="resumen-row">
              <span>Servicios</span>
              <span class="rval">{{ sel.servicios.map(s => s.nombre).join(', ') }}</span>
            </div>
            <div class="resumen-row">
              <span>Fecha & hora</span>
              <span class="rval">{{ fmtFechaHora(sel.slotInicio) }}</span>
            </div>
            <div class="resumen-row">
              <span>Terapeuta</span>
              <span class="rval">{{ personalSeleccionado?.nombre ?? 'Por asignar' }}</span>
            </div>
            <div class="resumen-row font-bold total-row">
              <span>Total</span><span class="rval text-primary">{{ fmt(totalPrecio) }}</span>
            </div>
          </div>

          <div class="field">
            <label>¿Se registra anticipo ahora?</label>
            <div class="anticipo-toggle">
              <button :class="['anti-btn', !tieneAnticipo && 'active']" @click="tieneAnticipo = false">No, solo agendar</button>
              <button :class="['anti-btn', tieneAnticipo && 'active']" @click="tieneAnticipo = true">Sí, registrar pago</button>
            </div>
          </div>

          <template v-if="tieneAnticipo">
            <div class="fields-row">
              <div class="field">
                <label>Monto anticipo</label>
                <div class="input-prefix">
                  <span>$</span>
                  <input v-model.number="anticipo.monto" type="number" min="0" :max="totalPrecio" step="0.01" />
                </div>
              </div>
              <div class="field">
                <label>Método de pago</label>
                <select v-model="anticipo.metodo">
                  <option value="EFECTIVO">💵 Efectivo</option>
                  <option value="TRANSFERENCIA">🏦 Transferencia</option>
                  <option value="TARJETA">💳 Tarjeta</option>
                  <option value="OTRO">Otro</option>
                </select>
              </div>
            </div>
          </template>

          <div v-if="errorGuardar" class="form-error mt-2">{{ errorGuardar }}</div>
        </div>

        <!-- Footer con navegación -->
        <div class="wizard-footer">
          <button class="btn-ghost" @click="pasoAnterior" :disabled="paso === 1">
            <ChevronLeft class="h-4 w-4"/> Atrás
          </button>
          <div class="footer-right">
            <span class="paso-indicator">{{ paso }}/4</span>
            <button v-if="paso < 4" class="btn-primary" @click="pasoSiguiente" :disabled="!puedeSiguiente">
              Siguiente <ChevronRight class="h-4 w-4"/>
            </button>
            <button v-else class="btn-primary" @click="confirmarCita" :disabled="guardando">
              <Loader2 v-if="guardando" class="h-4 w-4 animate-spin"/>
              Confirmar cita
            </button>
          </div>
        </div>

      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { X, Check, Search, Clock, ChevronLeft, ChevronRight, Loader2 } from 'lucide-vue-next'
import { useClientes } from '../composables/useClientes'
import type { Cliente } from '../composables/useClientes'
import { useServicios, CATEGORIAS_SERVICIO } from '../composables/useServicios'
import type { Servicio } from '../composables/useServicios'
import { usePersonal } from '../composables/usePersonal'
import { useCitas } from '../composables/useCitas'
import type { SlotDisponible } from '../composables/useCitas'

const props = defineProps<{ fechaInicial?: string | null }>()
const emit = defineEmits(['close', 'created'])

const paso = ref(1)
const pasoLabels = ['Seleccionar cliente', 'Servicios', 'Fecha y hora', 'Resumen y pago']
const pasoLabel = computed(() => pasoLabels[paso.value - 1])
const hoy = new Date().toISOString().slice(0, 10)

// ── Composables ──────────────────────────────────────────────────
const { buscarClientes: buscarFn, crearCliente } = useClientes()
const { servicios, fetchServicios } = useServicios()
const { personal, fetchPersonal } = usePersonal()
const { crearCita, getDisponibilidad } = useCitas()

// ── Selección ─────────────────────────────────────────────────────
const sel = ref({
  clienteId: '',
  servicios: [] as Servicio[],
  fecha: props.fechaInicial?.slice(0, 10) ?? hoy,
  personalId: '',
  slotInicio: '',
  slotFin:    '',
  notas: '',
})

const clienteSeleccionado = ref<Cliente | null>(null)
const personalSeleccionado = computed(() => personal.value.find(t => t.id === sel.value.personalId) ?? null)

// ── Paso 1: Cliente ───────────────────────────────────────────────
const clienteBusq = ref('')
const clientesResultados = ref<Cliente[]>([])
const showNuevoCliente = ref(false)
const nuevoCliente = ref({ nombre: '', telefono: '', correo: '', notas_preferencias: '' })

let busqTimeout: ReturnType<typeof setTimeout>
async function buscarClientes() {
  clearTimeout(busqTimeout)
  if (clienteBusq.value.length < 2) { clientesResultados.value = []; return }
  busqTimeout = setTimeout(async () => {
    clientesResultados.value = await buscarFn(clienteBusq.value)
  }, 300)
}

function seleccionarCliente(c: Cliente) {
  clienteSeleccionado.value = c
  sel.value.clienteId = c.id
  clienteBusq.value = c.nombre
  clientesResultados.value = []
  showNuevoCliente.value = false
}

function crearClienteRapido() {
  nuevoCliente.value = { nombre: clienteBusq.value, telefono: '', correo: '', notas_preferencias: '' }
  showNuevoCliente.value = true
}

async function guardarNuevoCliente() {
  const c = await crearCliente({
    nombre: nuevoCliente.value.nombre,
    telefono: nuevoCliente.value.telefono || null,
    correo: nuevoCliente.value.correo || null,
    notas_preferencias: nuevoCliente.value.notas_preferencias || null,
    fecha_nacimiento: null, genero: null, alergias: null,
  })
  seleccionarCliente(c)
  showNuevoCliente.value = false
}

// ── Paso 2: Servicios ─────────────────────────────────────────────
const filtroSvc = ref('')
const serviciosFiltrados = computed(() => {
  let list = servicios.value.filter(s => s.activo)
  if (filtroSvc.value) list = list.filter(s => s.categoria === filtroSvc.value)
  return list
})

function serviceSelected(id: string) { return sel.value.servicios.some(s => s.id === id) }
function toggleServicio(s: Servicio) {
  const idx = sel.value.servicios.findIndex(x => x.id === s.id)
  if (idx !== -1) sel.value.servicios.splice(idx, 1)
  else sel.value.servicios.push(s)
}
const totalDuracion = computed(() => sel.value.servicios.reduce((sum, s) => sum + s.duracion_min, 0))
const totalPrecio   = computed(() => sel.value.servicios.reduce((sum, s) => sum + s.precio, 0))

// ── Paso 3: Slots ─────────────────────────────────────────────────
const slots = ref<SlotDisponible[]>([])
const loadingSlots = ref(false)

async function cargarSlots() {
  if (!sel.value.fecha || totalDuracion.value === 0) return
  loadingSlots.value = true
  sel.value.slotInicio = ''
  sel.value.slotFin = ''
  try {
    if (sel.value.personalId) {
      slots.value = await getDisponibilidad(sel.value.personalId, sel.value.fecha, totalDuracion.value)
    } else {
      // Sin terapeuta: combinar slots de todos
      const all: SlotDisponible[] = []
      for (const t of personal.value) {
        const s = await getDisponibilidad(t.id, sel.value.fecha, totalDuracion.value)
        for (const slot of s) {
          if (!all.find(x => x.slot_inicio === slot.slot_inicio)) all.push(slot)
        }
      }
      slots.value = all.sort((a, b) => a.slot_inicio.localeCompare(b.slot_inicio))
    }
  } catch { slots.value = [] }
  finally { loadingSlots.value = false }
}

function seleccionarSlot(sl: SlotDisponible) {
  sel.value.slotInicio = sl.slot_inicio
  sel.value.slotFin    = sl.slot_fin
}

// ── Paso 4: Anticipo ──────────────────────────────────────────────
const tieneAnticipo = ref(false)
const anticipo = ref({ monto: 0, metodo: 'EFECTIVO' as const })
const guardando = ref(false)
const errorGuardar = ref<string | null>(null)

async function confirmarCita() {
  guardando.value = true
  errorGuardar.value = null
  try {
    await crearCita({
      cliente_id: sel.value.clienteId,
      personal_id: sel.value.personalId || null,
      fecha_inicio: sel.value.slotInicio,
      fecha_fin:    sel.value.slotFin,
      notas: sel.value.notas || undefined,
      items: sel.value.servicios.map(s => ({
        servicio_id: s.id,
        cantidad: 1,
        precio_unitario: s.precio,
      })),
      pago_inicial: tieneAnticipo.value && anticipo.value.monto > 0
        ? { monto: anticipo.value.monto, metodo: anticipo.value.metodo, es_anticipo: true }
        : undefined,
    })
    emit('created')
  } catch (e: any) {
    errorGuardar.value = e.message ?? 'Error al guardar la cita'
  } finally {
    guardando.value = false
  }
}

// ── Navegación ────────────────────────────────────────────────────
const puedeSiguiente = computed(() => {
  if (paso.value === 1) return !!sel.value.clienteId
  if (paso.value === 2) return sel.value.servicios.length > 0
  if (paso.value === 3) return !!sel.value.slotInicio
  return true
})

function pasoSiguiente() {
  if (!puedeSiguiente.value) return
  if (paso.value === 2) cargarSlots()
  paso.value++
}
function pasoAnterior() { if (paso.value > 1) paso.value-- }

// ── Helpers ───────────────────────────────────────────────────────
const AVATAR_COLORS = ['#8b5cf6','#ec4899','#f59e0b','#10b981','#3b82f6']
function avatarStyle(n: string) { return { background: AVATAR_COLORS[n.charCodeAt(0) % AVATAR_COLORS.length] } }
function initials(n: string) { return n.split(' ').slice(0,2).map(w=>w[0]).join('').toUpperCase() }
function fmt(n: number) { return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(n) }
function fmtHora(d: string) { return new Date(d).toLocaleTimeString('es-MX', { hour: '2-digit', minute: '2-digit', hour12: false }) }
function fmtFechaHora(d: string) {
  if (!d) return '—'
  return new Date(d).toLocaleString('es-MX', { weekday: 'long', day: 'numeric', month: 'long', hour: '2-digit', minute: '2-digit' })
}

onMounted(async () => {
  await Promise.all([fetchServicios(true), fetchPersonal(true)])
})
</script>

<style scoped>
.wizard-backdrop { position: fixed; inset: 0; background: rgba(0,0,0,.5); backdrop-filter: blur(6px); z-index: 300; display: flex; align-items: center; justify-content: center; padding: 16px; }
.wizard-box { background: var(--card); border-radius: 16px; width: 100%; max-width: 580px; max-height: 92vh; overflow-y: auto; box-shadow: 0 24px 80px rgba(0,0,0,.3); display: flex; flex-direction: column; }

/* Header */
.wizard-header { display: flex; align-items: center; justify-content: space-between; padding: 24px 24px 0; }
.wizard-header h2 { font-size: 22px; font-weight: 700; color: var(--foreground); margin: 0; }
.wizard-sub { font-size: 13px; color: var(--muted-foreground); margin: 4px 0 0; }
.icon-btn { display: inline-flex; align-items: center; justify-content: center; width: 34px; height: 34px; border-radius: 8px; border: 1px solid var(--border); background: transparent; color: var(--muted-foreground); cursor: pointer; transition: all .15s; }
.icon-btn:hover { background: var(--muted); color: var(--foreground); }

/* Stepper */
.stepper { display: flex; align-items: center; padding: 20px 24px; }
.step-item { display: flex; align-items: center; flex: 1; }
.step-circle {
  width: 28px; height: 28px; border-radius: 50%; display: flex; align-items: center; justify-content: center;
  background: var(--muted); color: var(--muted-foreground); font-size: 12px; font-weight: 700; flex-shrink: 0; transition: all .2s;
}
.step-circle.active { background: var(--primary); color: white; }
.step-circle.done { background: #10b981; color: white; }
.step-connector { flex: 1; height: 2px; background: var(--border); margin: 0 4px; transition: background .2s; }
.step-connector.done { background: #10b981; }
.step-item:last-child .step-connector { display: none; }

/* Body */
.paso-body { padding: 0 24px 16px; flex: 1; display: flex; flex-direction: column; gap: 14px; }
.paso-body h3 { font-size: 16px; font-weight: 700; color: var(--foreground); margin: 0; }

/* Search */
.search-wrap { position: relative; }
.search-icon { position: absolute; left: 10px; top: 50%; transform: translateY(-50%); color: var(--muted-foreground); pointer-events: none; }
.search-input { width: 100%; padding: 10px 12px 10px 34px; border: 1.5px solid var(--border); border-radius: var(--radius); background: var(--background); color: var(--foreground); font-size: 14px; box-sizing: border-box; }
.search-input:focus { outline: none; border-color: var(--primary); }

/* Resultados clientes */
.resultados { border: 1.5px solid var(--border); border-radius: var(--radius); overflow: hidden; max-height: 240px; overflow-y: auto; }
.resultado-item { width: 100%; display: flex; align-items: center; gap: 10px; padding: 10px 14px; background: transparent; border: none; border-bottom: 1px solid var(--border); cursor: pointer; text-align: left; transition: background .1s; }
.resultado-item:last-child { border-bottom: none; }
.resultado-item:hover { background: var(--muted); }
.resultado-item.selected { background: color-mix(in srgb, var(--primary) 10%, transparent); }
.resultado-avatar { width: 32px; height: 32px; border-radius: 8px; display: flex; align-items: center; justify-content: center; color: white; font-weight: 700; font-size: 12px; flex-shrink: 0; }
.resultado-nombre { font-weight: 600; font-size: 14px; color: var(--foreground); }
.resultado-meta { font-size: 12px; color: var(--muted-foreground); }
.ml-auto { margin-left: auto; }
.text-primary { color: var(--primary); }
.empty-search { text-align: center; padding: 16px; display: flex; flex-direction: column; gap: 8px; align-items: center; color: var(--muted-foreground); font-size: 14px; }

/* Nuevo cliente rápido */
.nuevo-cliente-form { background: var(--muted); border-radius: var(--radius); padding: 14px; display: flex; flex-direction: column; gap: 10px; }

/* Servicios */
.filter-tabs { display: flex; gap: 6px; flex-wrap: wrap; }
.tab-btn { padding: 5px 12px; border-radius: 999px; border: 1.5px solid var(--border); background: var(--card); color: var(--foreground); font-size: 11px; font-weight: 700; cursor: pointer; transition: all .15s; }
.tab-btn.active { background: var(--primary); color: white; border-color: var(--primary); }

.servicios-lista { display: flex; flex-direction: column; gap: 4px; max-height: 260px; overflow-y: auto; border: 1.5px solid var(--border); border-radius: var(--radius); }
.svc-item { display: flex; align-items: center; padding: 12px 14px; background: transparent; border: none; border-bottom: 1px solid var(--border); cursor: pointer; text-align: left; transition: background .1s; }
.svc-item:last-child { border-bottom: none; }
.svc-item:hover { background: var(--muted); }
.svc-item.selected { background: color-mix(in srgb, var(--primary) 10%, transparent); }
.svc-info { flex: 1; display: flex; flex-direction: column; gap: 2px; }
.svc-nombre { font-weight: 600; font-size: 14px; color: var(--foreground); }
.svc-meta { font-size: 12px; color: var(--muted-foreground); }
.svc-check-icon { width: 20px; display: flex; justify-content: center; color: var(--primary); }

.servicios-seleccionados { background: var(--muted); border-radius: var(--radius); padding: 12px 14px; }
.sel-label { font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .06em; color: var(--muted-foreground); margin: 0 0 8px; }
.sel-chips { display: flex; gap: 6px; flex-wrap: wrap; margin-bottom: 8px; }
.sel-chip { display: inline-flex; align-items: center; gap: 4px; padding: 3px 8px 3px 10px; border-radius: 999px; background: var(--primary); color: white; font-size: 12px; font-weight: 600; }
.chip-remove { background: none; border: none; color: inherit; cursor: pointer; padding: 0 0 0 2px; font-size: 14px; line-height: 1; }
.sel-totales { display: flex; align-items: center; gap: 8px; font-size: 13px; color: var(--muted-foreground); }
.sep { color: var(--border); }
.font-bold { font-weight: 700; color: var(--foreground); }

/* Slots */
.slots-wrap { display: flex; flex-direction: column; gap: 8px; }
.slots-grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 8px; }
.slot-btn { padding: 8px; border: 1.5px solid var(--border); border-radius: var(--radius); background: var(--background); color: var(--foreground); font-size: 13px; font-weight: 600; cursor: pointer; transition: all .15s; text-align: center; }
.slot-btn:hover { border-color: var(--primary); color: var(--primary); }
.slot-btn.selected { background: var(--primary); color: white; border-color: var(--primary); }
.empty-slots { padding: 20px; text-align: center; color: var(--muted-foreground); font-size: 14px; }
.spinner-sm { display: inline-block; width: 16px; height: 16px; border: 2px solid var(--border); border-top-color: var(--primary); border-radius: 50%; animation: spin .6s linear infinite; margin-right: 8px; vertical-align: middle; }
@keyframes spin { to { transform: rotate(360deg); } }
.hint-text { font-size: 13px; color: var(--muted-foreground); margin: 0; display: flex; align-items: center; }
.mt-2 { margin-top: 8px; }
.mt-4 { margin-top: 16px; }

/* Resumen */
.resumen-card { background: var(--muted); border-radius: var(--radius); padding: 16px; display: flex; flex-direction: column; gap: 10px; }
.resumen-row { display: flex; justify-content: space-between; gap: 12px; font-size: 14px; }
.resumen-row span:first-child { color: var(--muted-foreground); flex-shrink: 0; }
.rval { font-weight: 600; color: var(--foreground); text-align: right; }
.total-row { padding-top: 10px; border-top: 1px solid var(--border); font-size: 16px; }

/* Anticipo */
.anticipo-toggle { display: flex; border: 1.5px solid var(--border); border-radius: var(--radius); overflow: hidden; }
.anti-btn { flex: 1; padding: 9px; background: transparent; border: none; color: var(--muted-foreground); font-size: 13px; font-weight: 600; cursor: pointer; transition: all .15s; }
.anti-btn.active { background: var(--primary); color: white; }

/* Footer */
.wizard-footer { display: flex; align-items: center; justify-content: space-between; padding: 16px 24px; border-top: 1px solid var(--border); flex-shrink: 0; }
.footer-right { display: flex; align-items: center; gap: 12px; }
.paso-indicator { font-size: 12px; color: var(--muted-foreground); }

/* Forms */
.field { display: flex; flex-direction: column; gap: 6px; }
.field label { font-size: 13px; font-weight: 600; color: var(--foreground); }
.field input, .field select, .field textarea { padding: 9px 12px; border: 1.5px solid var(--border); border-radius: var(--radius); background: var(--background); color: var(--foreground); font-size: 14px; font-family: inherit; }
.field input:focus, .field select:focus, .field textarea:focus { outline: none; border-color: var(--primary); }
.fields-row { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
.input-prefix { display: flex; }
.input-prefix span { padding: 9px 10px; background: var(--muted); border: 1.5px solid var(--border); border-right: none; border-radius: var(--radius) 0 0 var(--radius); color: var(--muted-foreground); font-size: 14px; }
.input-prefix input { border-radius: 0 var(--radius) var(--radius) 0; flex: 1; min-width: 0; }
.form-error { padding: 10px 14px; background: #fee2e2; color: #dc2626; border-radius: var(--radius); font-size: 13px; }
:is(.dark) .form-error { background: #450a0a; color: #f87171; }
.btn-sm { font-size: 13px; padding: 7px 14px; }

@media (max-width: 600px) {
  .slots-grid { grid-template-columns: repeat(3, 1fr); }
  .fields-row { grid-template-columns: 1fr; }
}
</style>
