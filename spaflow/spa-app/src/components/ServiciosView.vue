<template>
  <div class="view-page">
    <!-- Header -->
    <div class="page-header">
      <div>
        <h1 class="font-spa-display">Servicios</h1>
        <p class="page-sub">Catálogo de servicios del spa</p>
      </div>
      <button class="btn-primary" @click="openForm()">
        <Plus class="h-4 w-4" /> Nuevo servicio
      </button>
    </div>

    <!-- Stats -->
    <div class="stats-row">
      <div class="stat-pill">
        <Sparkles class="h-4 w-4 text-primary" />
        <span class="stat-val">{{ servicios.length }}</span>
        <span class="stat-lbl">Total</span>
      </div>
      <div class="stat-pill" v-for="cat in statsCategoria" :key="cat.value">
        <span>{{ cat.emoji }}</span>
        <span class="stat-val">{{ cat.count }}</span>
        <span class="stat-lbl">{{ cat.label }}</span>
      </div>
    </div>

    <!-- Filtros -->
    <div class="filters-bar">
      <div class="search-wrap">
        <Search class="search-icon h-4 w-4" />
        <input v-model="q" placeholder="Buscar servicio..." class="search-input" />
      </div>
      <div class="filter-tabs">
        <button
          v-for="cat in [{ value: '', label: 'Todos', emoji: '🌿' }, ...CATEGORIAS_SERVICIO]"
          :key="cat.value"
          :class="['tab-btn', filtroCategoria === cat.value && 'active']"
          @click="filtroCategoria = cat.value"
        >
          {{ cat.emoji }} {{ cat.label }}
        </button>
      </div>
      <label class="toggle-label">
        <input type="checkbox" v-model="verInactivos" />
        Ver inactivos
      </label>
    </div>

    <!-- Tabla -->
    <div class="card-spa table-wrap">
      <div v-if="loading" class="empty-state">
        <div class="spinner" /><p>Cargando servicios...</p>
      </div>
      <div v-else-if="errorMsg" class="empty-state text-destructive">⚠️ {{ errorMsg }}</div>
      <div v-else-if="filtrados.length === 0" class="empty-state">
        <Sparkles class="h-8 w-8 op-30" />
        <p>No hay servicios en esta categoría</p>
        <button class="btn-primary" @click="openForm()">Crear el primero</button>
      </div>
      <table v-else class="spa-table">
        <thead>
          <tr>
            <th>Servicio</th>
            <th>Categoría</th>
            <th>Duración</th>
            <th>Precio</th>
            <th>Estado</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="s in filtrados" :key="s.id" :class="!s.activo && 'row-inactive'">
            <td>
              <div class="svc-name">{{ s.nombre }}</div>
              <div v-if="s.descripcion" class="svc-desc">{{ s.descripcion }}</div>
            </td>
            <td>
              <span class="cat-badge">
                {{ getCat(s.categoria)?.emoji }} {{ getCat(s.categoria)?.label }}
              </span>
            </td>
            <td>
              <span class="duration-pill">
                <Clock class="h-3 w-3" /> {{ s.duracion_min }} min
              </span>
            </td>
            <td class="price-cell">{{ fmt(s.precio) }}</td>
            <td>
              <button
                class="estado-badge"
                :class="s.activo ? 'badge-confirmada' : 'badge-cancelada'"
                @click="toggleActivo(s)"
                :title="s.activo ? 'Click para desactivar' : 'Click para activar'"
              >
                {{ s.activo ? 'Activo' : 'Inactivo' }}
              </button>
            </td>
            <td class="actions-cell">
              <button class="icon-btn" title="Editar" @click="openForm(s)">
                <Pencil class="h-4 w-4" />
              </button>
              <button class="icon-btn danger" title="Eliminar" @click="confirmarEliminar(s)">
                <Trash2 class="h-4 w-4" />
              </button>
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
            <h2 class="font-spa-display">{{ editando ? 'Editar servicio' : 'Nuevo servicio' }}</h2>
            <button class="icon-btn" @click="showForm = false"><X class="h-5 w-5" /></button>
          </div>

          <form @submit.prevent="guardar" class="modal-form">
            <div class="field">
              <label>Nombre *</label>
              <input v-model="form.nombre" required placeholder="Ej. Masaje Sueco" />
            </div>
            <div class="field">
              <label>Descripción</label>
              <textarea v-model="form.descripcion" rows="2" placeholder="Breve descripción del servicio..." />
            </div>
            <div class="fields-row">
              <div class="field">
                <label>Categoría *</label>
                <select v-model="form.categoria" required>
                  <option v-for="cat in CATEGORIAS_SERVICIO" :key="cat.value" :value="cat.value">
                    {{ cat.emoji }} {{ cat.label }}
                  </option>
                </select>
              </div>
              <div class="field">
                <label>Duración (min) *</label>
                <input v-model.number="form.duracion_min" type="number" min="5" step="5" required />
              </div>
            </div>
            <div class="fields-row">
              <div class="field">
                <label>Precio *</label>
                <div class="input-prefix">
                  <span>$</span>
                  <input v-model.number="form.precio" type="number" min="0" step="0.01" required />
                </div>
              </div>
              <div class="field field-check">
                <label class="check-label">
                  <input type="checkbox" v-model="form.activo" />
                  Servicio activo
                </label>
              </div>
            </div>

            <div v-if="formError" class="form-error">{{ formError }}</div>

            <div class="modal-footer">
              <button type="button" class="btn-ghost" @click="showForm = false">Cancelar</button>
              <button type="submit" class="btn-primary" :disabled="saving">
                <Loader2 v-if="saving" class="h-4 w-4 animate-spin" />
                {{ editando ? 'Guardar cambios' : 'Crear servicio' }}
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
import { useServicios, CATEGORIAS_SERVICIO } from '../composables/useServicios'
import type { Servicio, CategoriaServicio } from '../composables/useServicios'
import {
  Sparkles, Plus, Pencil, Trash2, X, Clock, Search, Loader2
} from 'lucide-vue-next'

const { servicios, loading, errorMsg, fetchServicios, crearServicio, actualizarServicio, toggleActivoServicio, eliminarServicio } = useServicios()

const q = ref('')
const filtroCategoria = ref<string>('')
const verInactivos = ref(false)

const filtrados = computed(() => {
  let list = servicios.value
  if (!verInactivos.value) list = list.filter(s => s.activo)
  if (filtroCategoria.value) list = list.filter(s => s.categoria === filtroCategoria.value)
  if (q.value.trim()) {
    const term = q.value.toLowerCase()
    list = list.filter(s => s.nombre.toLowerCase().includes(term) || (s.descripcion ?? '').toLowerCase().includes(term))
  }
  return list
})

const statsCategoria = computed(() =>
  CATEGORIAS_SERVICIO.map(cat => ({
    ...cat,
    count: servicios.value.filter(s => s.categoria === cat.value && s.activo).length
  })).filter(c => c.count > 0)
)

function getCat(v: CategoriaServicio) {
  return CATEGORIAS_SERVICIO.find(c => c.value === v)
}

function fmt(n: number) {
  return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(n)
}

// ── Form ─────────────────────────────────────────────────────────
const showForm = ref(false)
const saving = ref(false)
const formError = ref<string | null>(null)
const editando = ref<Servicio | null>(null)

const form = ref({
  nombre: '',
  descripcion: '',
  categoria: 'MASAJE' as CategoriaServicio,
  duracion_min: 60,
  precio: 0,
  activo: true,
  imagen_url: null as string | null,
})

function openForm(s?: Servicio) {
  editando.value = s ?? null
  formError.value = null
  if (s) {
    form.value = { nombre: s.nombre, descripcion: s.descripcion ?? '', categoria: s.categoria, duracion_min: s.duracion_min, precio: s.precio, activo: s.activo, imagen_url: s.imagen_url }
  } else {
    form.value = { nombre: '', descripcion: '', categoria: 'MASAJE', duracion_min: 60, precio: 0, activo: true, imagen_url: null }
  }
  showForm.value = true
}

async function guardar() {
  formError.value = null
  saving.value = true
  try {
    if (editando.value) {
      await actualizarServicio(editando.value.id, form.value)
    } else {
      await crearServicio(form.value)
    }
    showForm.value = false
  } catch (e: any) {
    formError.value = e.message ?? 'Error al guardar'
  } finally {
    saving.value = false
  }
}

async function toggleActivo(s: Servicio) {
  await toggleActivoServicio(s.id, !s.activo)
}

async function confirmarEliminar(s: Servicio) {
  if (!confirm(`¿Eliminar "${s.nombre}"? Esta acción no se puede deshacer.`)) return
  await eliminarServicio(s.id)
}

onMounted(() => fetchServicios(false))
</script>

<style scoped>
.view-page { padding: 24px; max-width: 1100px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px; gap: 12px; }
.page-header h1 { font-size: 26px; font-weight: 700; color: var(--foreground); margin: 0; }
.page-sub { color: var(--muted-foreground); font-size: 14px; margin: 4px 0 0; }

/* Stats */
.stats-row { display: flex; gap: 10px; flex-wrap: wrap; margin-bottom: 18px; }
.stat-pill { display: flex; align-items: center; gap: 8px; padding: 8px 16px; background: var(--secondary); border-radius: 999px; font-size: 13px; }
.stat-val { font-weight: 700; color: var(--primary); }
.stat-lbl { color: var(--muted-foreground); }

/* Filters */
.filters-bar { display: flex; gap: 12px; align-items: center; flex-wrap: wrap; margin-bottom: 16px; }
.search-wrap { position: relative; flex: 1; min-width: 200px; max-width: 320px; }
.search-icon { position: absolute; left: 10px; top: 50%; transform: translateY(-50%); color: var(--muted-foreground); pointer-events: none; }
.search-input { width: 100%; padding: 8px 12px 8px 34px; border: 1.5px solid var(--border); border-radius: var(--radius); background: var(--card); color: var(--foreground); font-size: 14px; box-sizing: border-box; }
.search-input:focus { outline: none; border-color: var(--primary); }
.filter-tabs { display: flex; gap: 6px; flex-wrap: wrap; }
.tab-btn { padding: 6px 14px; border-radius: 999px; border: 1.5px solid var(--border); background: var(--card); color: var(--foreground); font-size: 12px; font-weight: 600; cursor: pointer; transition: all .15s; }
.tab-btn.active { background: var(--primary); color: white; border-color: var(--primary); }
.tab-btn:hover:not(.active) { background: var(--muted); }
.toggle-label { display: flex; align-items: center; gap: 6px; font-size: 13px; color: var(--muted-foreground); cursor: pointer; }

/* Table */
.table-wrap { padding: 0; overflow-x: auto; }
.spa-table { width: 100%; border-collapse: collapse; min-width: 600px; }
.spa-table th { padding: 12px 16px; text-align: left; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .06em; color: var(--muted-foreground); border-bottom: 2px solid var(--border); }
.spa-table td { padding: 14px 16px; border-bottom: 1px solid var(--border); vertical-align: middle; }
.spa-table tbody tr:hover { background: var(--muted); }
.row-inactive td { opacity: .55; }

.svc-name { font-weight: 600; font-size: 14px; color: var(--foreground); }
.svc-desc { font-size: 12px; color: var(--muted-foreground); margin-top: 2px; }

.cat-badge { display: inline-flex; align-items: center; gap: 4px; padding: 3px 10px; border-radius: 999px; background: var(--secondary); color: var(--secondary-foreground); font-size: 11px; font-weight: 700; }
.duration-pill { display: inline-flex; align-items: center; gap: 4px; font-size: 13px; color: var(--muted-foreground); }
.price-cell { font-weight: 700; font-size: 15px; color: var(--foreground); }
.estado-badge { cursor: pointer; border: none; }

.actions-cell { display: flex; gap: 6px; justify-content: flex-end; }
.icon-btn { display: inline-flex; align-items: center; justify-content: center; width: 32px; height: 32px; border-radius: 8px; border: 1px solid var(--border); background: var(--card); color: var(--muted-foreground); cursor: pointer; transition: all .15s; }
.icon-btn:hover { background: var(--muted); color: var(--foreground); }
.icon-btn.danger:hover { background: #fee2e2; color: #dc2626; border-color: #dc2626; }
:is(.dark) .icon-btn.danger:hover { background: #450a0a; color: #f87171; border-color: #f87171; }

.empty-state { padding: 60px 24px; text-align: center; display: flex; flex-direction: column; align-items: center; gap: 12px; color: var(--muted-foreground); }
.spinner { width: 28px; height: 28px; border: 3px solid var(--border); border-top-color: var(--primary); border-radius: 50%; animation: spin .6s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }

/* Modal */
.modal-backdrop { position: fixed; inset: 0; background: rgba(0,0,0,.45); backdrop-filter: blur(4px); z-index: 200; display: flex; align-items: center; justify-content: center; padding: 16px; }
.modal-box { background: var(--card); border-radius: calc(var(--radius) + 4px); width: 100%; max-width: 520px; box-shadow: 0 20px 60px rgba(0,0,0,.25); }
.modal-header { display: flex; align-items: center; justify-content: space-between; padding: 20px 24px 0; }
.modal-header h2 { font-size: 20px; font-weight: 700; color: var(--foreground); margin: 0; }
.modal-form { padding: 20px 24px 24px; display: flex; flex-direction: column; gap: 14px; }
.modal-footer { display: flex; justify-content: flex-end; gap: 10px; padding-top: 8px; border-top: 1px solid var(--border); margin-top: 4px; }

.field { display: flex; flex-direction: column; gap: 6px; }
.field label { font-size: 13px; font-weight: 600; color: var(--foreground); }
.field input, .field select, .field textarea {
  padding: 9px 12px; border: 1.5px solid var(--border); border-radius: var(--radius);
  background: var(--background); color: var(--foreground); font-size: 14px; font-family: inherit;
}
.field input:focus, .field select:focus, .field textarea:focus { outline: none; border-color: var(--primary); }
.fields-row { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
.input-prefix { display: flex; }
.input-prefix span { padding: 9px 10px; background: var(--muted); border: 1.5px solid var(--border); border-right: none; border-radius: var(--radius) 0 0 var(--radius); color: var(--muted-foreground); font-size: 14px; }
.input-prefix input { border-radius: 0 var(--radius) var(--radius) 0; flex: 1; min-width: 0; }
.field-check { justify-content: flex-end; padding-bottom: 4px; }
.check-label { display: flex; align-items: center; gap: 8px; font-size: 14px; font-weight: 600; cursor: pointer; }
.form-error { padding: 10px 14px; background: #fee2e2; color: #dc2626; border-radius: var(--radius); font-size: 13px; }
:is(.dark) .form-error { background: #450a0a; color: #f87171; }

@media (max-width: 640px) {
  .view-page { padding: 16px; }
  .fields-row { grid-template-columns: 1fr; }
  .filter-tabs { display: none; }
}
</style>
