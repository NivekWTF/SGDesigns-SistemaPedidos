<template>
  <div class="view-page">
    <div class="page-header">
      <div>
        <h1 class="font-spa-display">Clientes</h1>
        <p class="page-sub">Directorio de clientas del spa</p>
      </div>
      <button class="btn-primary" @click="openForm()">
        <Plus class="h-4 w-4" /> Nueva clienta
      </button>
    </div>

    <!-- Stats -->
    <div class="stats-row">
      <div class="stat-pill"><Users class="h-4 w-4 text-primary" /><span class="stat-val">{{ clientes.length }}</span><span class="stat-lbl">Total</span></div>
      <div class="stat-pill"><span>📞</span><span class="stat-val">{{ clientes.filter(c => c.telefono).length }}</span><span class="stat-lbl">Con teléfono</span></div>
      <div class="stat-pill"><span>🌸</span><span class="stat-val">{{ clientes.filter(c => c.fecha_ultima_visita).length }}</span><span class="stat-lbl">Han visitado</span></div>
    </div>

    <!-- Búsqueda -->
    <div class="filters-bar">
      <div class="search-wrap">
        <Search class="search-icon h-4 w-4" />
        <input v-model="q" placeholder="Buscar por nombre, teléfono o correo..." class="search-input"
          @keyup.enter="buscar" />
      </div>
    </div>

    <!-- Tabla -->
    <div class="card-spa table-wrap">
      <div v-if="loading" class="empty-state"><div class="spinner" /><p>Cargando clientes...</p></div>
      <div v-else-if="filtrados.length === 0" class="empty-state">
        <Users class="h-8 w-8 op-30" />
        <p>No hay clientes registradas</p>
        <button class="btn-primary" @click="openForm()">Agregar la primera</button>
      </div>
      <table v-else class="spa-table">
        <thead>
          <tr>
            <th>Cliente</th>
            <th>Contacto</th>
            <th>Última visita</th>
            <th>Notas / Alergias</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="c in filtrados" :key="c.id">
            <td>
              <div class="cliente-row">
                <div class="cliente-avatar" :style="avatarStyle(c.nombre)">{{ initials(c.nombre) }}</div>
                <div>
                  <div class="cliente-nombre">{{ c.nombre }}</div>
                  <div v-if="c.genero" class="cliente-meta">{{ generoLabel(c.genero) }}</div>
                </div>
              </div>
            </td>
            <td>
              <div v-if="c.telefono" class="contact-row"><Phone class="h-3.5 w-3.5" /> {{ c.telefono }}</div>
              <div v-if="c.correo" class="contact-row"><Mail class="h-3.5 w-3.5" /> {{ c.correo }}</div>
              <span v-if="!c.telefono && !c.correo" class="muted">—</span>
            </td>
            <td>
              <span v-if="c.fecha_ultima_visita" class="date-pill">
                <CalendarDays class="h-3 w-3" /> {{ fmtDate(c.fecha_ultima_visita) }}
              </span>
              <span v-else class="muted">Sin visitas</span>
            </td>
            <td>
              <div v-if="c.alergias" class="alert-chip">⚠️ {{ c.alergias }}</div>
              <div v-if="c.notas_preferencias" class="notes-text">{{ c.notas_preferencias }}</div>
              <span v-if="!c.alergias && !c.notas_preferencias" class="muted">—</span>
            </td>
            <td class="actions-cell">
              <button class="icon-btn" @click="openForm(c)" title="Editar"><Pencil class="h-4 w-4" /></button>
              <button class="icon-btn danger" @click="confirmarEliminar(c)" title="Eliminar"><Trash2 class="h-4 w-4" /></button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Modal Form -->
    <Teleport to="body">
      <div v-if="showForm" class="modal-backdrop" @click.self="showForm = false">
        <div class="modal-box">
          <div class="modal-header">
            <h2 class="font-spa-display">{{ editando ? 'Editar cliente' : 'Nueva cliente' }}</h2>
            <button class="icon-btn" @click="showForm = false"><X class="h-5 w-5" /></button>
          </div>
          <form @submit.prevent="guardar" class="modal-form">
            <div class="field">
              <label>Nombre *</label>
              <input v-model="form.nombre" required placeholder="Ej. María García" />
            </div>
            <div class="fields-row">
              <div class="field">
                <label>Teléfono</label>
                <input v-model="form.telefono" placeholder="5551234567" />
              </div>
              <div class="field">
                <label>Correo</label>
                <input v-model="form.correo" type="email" placeholder="maria@email.com" />
              </div>
            </div>
            <div class="fields-row">
              <div class="field">
                <label>Fecha de nacimiento</label>
                <input v-model="form.fecha_nacimiento" type="date" />
              </div>
              <div class="field">
                <label>Género</label>
                <select v-model="form.genero">
                  <option value="">Sin especificar</option>
                  <option value="F">Femenino</option>
                  <option value="M">Masculino</option>
                  <option value="O">Otro</option>
                </select>
              </div>
            </div>
            <div class="field">
              <label>⚠️ Alergias / Contraindicaciones</label>
              <input v-model="form.alergias" placeholder="Ej. Alérgica a la lavanda, problemas lumbares..." />
            </div>
            <div class="field">
              <label>🌸 Preferencias y notas</label>
              <textarea v-model="form.notas_preferencias" rows="2"
                placeholder="Ej. Prefiere poca presión, aromas florales, terapeuta femenina..." />
            </div>
            <div v-if="formError" class="form-error">{{ formError }}</div>
            <div class="modal-footer">
              <button type="button" class="btn-ghost" @click="showForm = false">Cancelar</button>
              <button type="submit" class="btn-primary" :disabled="saving">
                <Loader2 v-if="saving" class="h-4 w-4 animate-spin" />
                {{ editando ? 'Guardar cambios' : 'Crear cliente' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useClientes } from '../composables/useClientes'
import type { Cliente, ClienteInput } from '../composables/useClientes'
import { Users, Plus, Pencil, Trash2, X, Search, Phone, Mail, CalendarDays, Loader2 } from 'lucide-vue-next'

const { clientes, loading, errorMsg, fetchClientes, buscarClientes, crearCliente, actualizarCliente, eliminarCliente } = useClientes()

const q = ref('')
const showForm = ref(false)
const saving = ref(false)
const formError = ref<string | null>(null)
const editando = ref<Cliente | null>(null)

const filtrados = computed(() => {
  if (!q.value.trim()) return clientes.value
  const term = q.value.toLowerCase()
  return clientes.value.filter(c =>
    c.nombre.toLowerCase().includes(term) ||
    (c.telefono ?? '').includes(term) ||
    (c.correo ?? '').toLowerCase().includes(term)
  )
})

async function buscar() {
  if (q.value.trim().length >= 2) {
    const res = await buscarClientes(q.value)
    clientes.value.splice(0, clientes.value.length, ...res)
  } else {
    await fetchClientes()
  }
}

const AVATAR_COLORS = ['#8b5cf6','#ec4899','#f59e0b','#10b981','#3b82f6','#ef4444','#06b6d4','#8b5e3c']
function avatarStyle(nombre: string) {
  const idx = nombre.charCodeAt(0) % AVATAR_COLORS.length
  return { background: AVATAR_COLORS[idx] }
}
function initials(nombre: string) {
  return nombre.split(' ').slice(0, 2).map(w => w[0]).join('').toUpperCase()
}
function generoLabel(g: string) {
  return g === 'F' ? 'Femenino' : g === 'M' ? 'Masculino' : 'Otro'
}
function fmtDate(d: string) {
  return new Date(d).toLocaleDateString('es-MX', { day: 'numeric', month: 'short', year: 'numeric' })
}

const emptyForm = (): ClienteInput => ({
  nombre: '', telefono: null, correo: null,
  fecha_nacimiento: null, genero: null,
  alergias: null, notas_preferencias: null,
})

const form = ref<ClienteInput>(emptyForm())

function openForm(c?: Cliente) {
  editando.value = c ?? null
  formError.value = null
  form.value = c
    ? { nombre: c.nombre, telefono: c.telefono, correo: c.correo,
        fecha_nacimiento: c.fecha_nacimiento, genero: c.genero,
        alergias: c.alergias, notas_preferencias: c.notas_preferencias }
    : emptyForm()
  showForm.value = true
}

async function guardar() {
  formError.value = null
  saving.value = true
  try {
    if (editando.value) {
      await actualizarCliente(editando.value.id, form.value)
    } else {
      await crearCliente(form.value)
    }
    showForm.value = false
  } catch (e: any) {
    formError.value = e.message ?? 'Error al guardar'
  } finally {
    saving.value = false
  }
}

async function confirmarEliminar(c: Cliente) {
  if (!confirm(`¿Eliminar a "${c.nombre}"?`)) return
  await eliminarCliente(c.id)
}

onMounted(() => fetchClientes())
</script>

<style scoped>
.view-page { padding: 24px; max-width: 1100px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px; gap: 12px; }
.page-header h1 { font-size: 26px; font-weight: 700; color: var(--foreground); margin: 0; }
.page-sub { color: var(--muted-foreground); font-size: 14px; margin: 4px 0 0; }

.stats-row { display: flex; gap: 10px; flex-wrap: wrap; margin-bottom: 18px; }
.stat-pill { display: flex; align-items: center; gap: 8px; padding: 8px 16px; background: var(--secondary); border-radius: 999px; font-size: 13px; }
.stat-val { font-weight: 700; color: var(--primary); }
.stat-lbl { color: var(--muted-foreground); }

.filters-bar { margin-bottom: 16px; }
.search-wrap { position: relative; max-width: 420px; }
.search-icon { position: absolute; left: 10px; top: 50%; transform: translateY(-50%); color: var(--muted-foreground); pointer-events: none; }
.search-input { width: 100%; padding: 9px 12px 9px 34px; border: 1.5px solid var(--border); border-radius: var(--radius); background: var(--card); color: var(--foreground); font-size: 14px; box-sizing: border-box; }
.search-input:focus { outline: none; border-color: var(--primary); }

.table-wrap { padding: 0; overflow-x: auto; }
.spa-table { width: 100%; border-collapse: collapse; min-width: 700px; }
.spa-table th { padding: 12px 16px; text-align: left; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .06em; color: var(--muted-foreground); border-bottom: 2px solid var(--border); }
.spa-table td { padding: 14px 16px; border-bottom: 1px solid var(--border); vertical-align: top; }
.spa-table tbody tr:hover { background: var(--muted); transition: background .1s; }

.cliente-row { display: flex; align-items: center; gap: 10px; }
.cliente-avatar { width: 36px; height: 36px; border-radius: 10px; flex-shrink: 0; display: flex; align-items: center; justify-content: center; color: white; font-weight: 700; font-size: 13px; }
.cliente-nombre { font-weight: 600; font-size: 14px; color: var(--foreground); }
.cliente-meta { font-size: 12px; color: var(--muted-foreground); }

.contact-row { display: flex; align-items: center; gap: 5px; font-size: 13px; color: var(--muted-foreground); }
.date-pill { display: inline-flex; align-items: center; gap: 4px; font-size: 12px; color: var(--muted-foreground); }
.alert-chip { display: inline-block; font-size: 12px; padding: 2px 8px; border-radius: 6px; background: #fef3c7; color: #92400e; margin-bottom: 4px; }
:is(.dark) .alert-chip { background: #451a03; color: #fde68a; }
.notes-text { font-size: 12px; color: var(--muted-foreground); font-style: italic; }
.muted { color: var(--muted-foreground); font-size: 13px; }

.actions-cell { display: flex; gap: 6px; justify-content: flex-end; }
.icon-btn { display: inline-flex; align-items: center; justify-content: center; width: 32px; height: 32px; border-radius: 8px; border: 1px solid var(--border); background: transparent; color: var(--muted-foreground); cursor: pointer; transition: all .15s; }
.icon-btn:hover { background: var(--muted); color: var(--foreground); }
.icon-btn.danger:hover { background: #fee2e2; color: #dc2626; border-color: #dc2626; }
:is(.dark) .icon-btn.danger:hover { background: #450a0a; color: #f87171; border-color: #f87171; }

.empty-state { padding: 60px 24px; text-align: center; display: flex; flex-direction: column; align-items: center; gap: 12px; color: var(--muted-foreground); }
.spinner { width: 28px; height: 28px; border: 3px solid var(--border); border-top-color: var(--primary); border-radius: 50%; animation: spin .6s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }

.modal-backdrop { position: fixed; inset: 0; background: rgba(0,0,0,.45); backdrop-filter: blur(4px); z-index: 200; display: flex; align-items: center; justify-content: center; padding: 16px; }
.modal-box { background: var(--card); border-radius: calc(var(--radius) + 4px); width: 100%; max-width: 520px; box-shadow: 0 20px 60px rgba(0,0,0,.25); max-height: 90vh; overflow-y: auto; }
.modal-header { display: flex; align-items: center; justify-content: space-between; padding: 20px 24px 0; }
.modal-header h2 { font-size: 20px; font-weight: 700; color: var(--foreground); margin: 0; }
.modal-form { padding: 20px 24px 24px; display: flex; flex-direction: column; gap: 14px; }
.modal-footer { display: flex; justify-content: flex-end; gap: 10px; padding-top: 8px; border-top: 1px solid var(--border); margin-top: 4px; }

.field { display: flex; flex-direction: column; gap: 6px; }
.field label { font-size: 13px; font-weight: 600; color: var(--foreground); }
.field input, .field select, .field textarea { padding: 9px 12px; border: 1.5px solid var(--border); border-radius: var(--radius); background: var(--background); color: var(--foreground); font-size: 14px; font-family: inherit; }
.field input:focus, .field select:focus, .field textarea:focus { outline: none; border-color: var(--primary); }
.fields-row { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
.form-error { padding: 10px 14px; background: #fee2e2; color: #dc2626; border-radius: var(--radius); font-size: 13px; }
:is(.dark) .form-error { background: #450a0a; color: #f87171; }

@media (max-width: 640px) {
  .view-page { padding: 16px; }
  .fields-row { grid-template-columns: 1fr; }
}
</style>
