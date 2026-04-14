<template>
  <div class="view-page">
    <div class="page-header">
      <div>
        <h1 class="font-spa-display">Personal</h1>
        <p class="page-sub">Terapeutas y horarios del spa</p>
      </div>
      <button class="btn-primary" @click="openForm()">
        <Plus class="h-4 w-4" /> Nuevo terapeuta
      </button>
    </div>

    <!-- Grid de terapeutas -->
    <div v-if="loading" class="empty-state"><div class="spinner" /><p>Cargando personal...</p></div>
    <div v-else-if="personal.length === 0" class="empty-state">
      <UserCheck class="h-10 w-10 op-30" />
      <p>Aún no hay personal registrado</p>
      <button class="btn-primary" @click="openForm()">Agregar terapeuta</button>
    </div>
    <div v-else class="personal-grid">
      <div v-for="t in personal" :key="t.id" class="terapeuta-card">
        <!-- Color badge + nombre -->
        <div class="card-top">
          <div class="avatar-circle" :style="{ background: t.color_agenda }">
            {{ initials(t.nombre) }}
          </div>
          <div class="card-info">
            <div class="terapeuta-nombre">{{ t.nombre }}</div>
            <div class="esp-chips">
              <span v-for="esp in t.especialidades" :key="esp" class="esp-chip">
                {{ getEspEmoji(esp) }} {{ esp }}
              </span>
            </div>
          </div>
          <div class="card-actions">
            <button class="icon-btn" @click="openForm(t)" title="Editar"><Pencil class="h-4 w-4" /></button>
            <button class="icon-btn" @click="openHorario(t)" title="Horario"><Calendar class="h-4 w-4" /></button>
            <button class="icon-btn danger" @click="confirmarEliminar(t)" title="Eliminar"><Trash2 class="h-4 w-4" /></button>
          </div>
        </div>
        <div v-if="t.telefono" class="card-meta"><Phone class="h-3 w-3" /> {{ t.telefono }}</div>
        <!-- Horario resumen -->
        <div class="horario-chips">
          <span v-for="d in [1,2,3,4,5,6,0]" :key="d"
            class="dia-chip"
            :class="tieneHorario(t.id, d) ? 'dia-active' : 'dia-off'"
          >{{ DIAS_SEMANA[d] }}</span>
        </div>
      </div>
    </div>

    <!-- Modal: Form terapeuta -->
    <Teleport to="body">
      <div v-if="showForm" class="modal-backdrop" @click.self="showForm = false">
        <div class="modal-box">
          <div class="modal-header">
            <h2 class="font-spa-display">{{ editando ? 'Editar terapeuta' : 'Nuevo terapeuta' }}</h2>
            <button class="icon-btn" @click="showForm = false"><X class="h-5 w-5" /></button>
          </div>
          <form @submit.prevent="guardar" class="modal-form">
            <div class="field">
              <label>Nombre *</label>
              <input v-model="form.nombre" required placeholder="Ej. Sofía Ramírez" />
            </div>
            <div class="field">
              <label>Teléfono</label>
              <input v-model="form.telefono" placeholder="5551234567" />
            </div>

            <div class="field">
              <label>Especialidades</label>
              <div class="esp-selector">
                <label v-for="cat in CATEGORIAS_SERVICIO" :key="cat.value" class="esp-check">
                  <input type="checkbox" :value="cat.value" v-model="form.especialidades" />
                  {{ cat.emoji }} {{ cat.label }}
                </label>
              </div>
            </div>

            <div class="field">
              <label>Color en agenda</label>
              <div class="color-grid">
                <button
                  v-for="cl in COLORES_AGENDA" :key="cl.value"
                  type="button"
                  class="color-swatch"
                  :style="{ background: cl.value }"
                  :class="form.color_agenda === cl.value && 'selected'"
                  :title="cl.label"
                  @click="form.color_agenda = cl.value"
                />
              </div>
            </div>

            <div class="field-check">
              <label class="check-label">
                <input type="checkbox" v-model="form.activo" /> Terapeuta activo
              </label>
            </div>

            <div v-if="formError" class="form-error">{{ formError }}</div>
            <div class="modal-footer">
              <button type="button" class="btn-ghost" @click="showForm = false">Cancelar</button>
              <button type="submit" class="btn-primary" :disabled="saving">
                <Loader2 v-if="saving" class="h-4 w-4 animate-spin" />
                {{ editando ? 'Guardar cambios' : 'Crear' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>

    <!-- Modal: Horario semanal -->
    <Teleport to="body">
      <div v-if="showHorario" class="modal-backdrop" @click.self="showHorario = false">
        <div class="modal-box modal-wide">
          <div class="modal-header">
            <h2 class="font-spa-display">Horario de {{ terapeutaHorario?.nombre }}</h2>
            <button class="icon-btn" @click="showHorario = false"><X class="h-5 w-5" /></button>
          </div>
          <div class="modal-form">
            <p class="hint-text">Configura los días y horarios laborales. Deja vacío el día para marcarlo como descanso.</p>
            <div class="horario-editor">
              <div v-for="(dia, idx) in horarioForm" :key="dia.dia_semana" class="horario-row">
                <label class="horario-dia-check">
                  <input type="checkbox" v-model="dia.activo" />
                  <span class="dia-label">{{ DIAS_SEMANA[dia.dia_semana] }}</span>
                </label>
                <template v-if="dia.activo">
                  <input type="time" v-model="dia.hora_inicio" class="time-input" />
                  <span class="time-sep">–</span>
                  <input type="time" v-model="dia.hora_fin" class="time-input" />
                </template>
                <span v-else class="descanso-label">Descanso</span>
              </div>
            </div>
            <div v-if="horarioError" class="form-error">{{ horarioError }}</div>
            <div class="modal-footer" style="border-top:none; padding-top:0">
              <button type="button" class="btn-ghost" @click="showHorario = false">Cancelar</button>
              <button class="btn-primary" @click="guardarHorario" :disabled="savingHorario">
                <Loader2 v-if="savingHorario" class="h-4 w-4 animate-spin" />
                Guardar horario
              </button>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { usePersonal, DIAS_SEMANA, COLORES_AGENDA } from '../composables/usePersonal'
import { CATEGORIAS_SERVICIO } from '../composables/useServicios'
import type { Terapeuta, CategoriaServicio } from '../composables/useServicios'
import { UserCheck, Plus, Pencil, Trash2, X, Calendar, Phone, Loader2 } from 'lucide-vue-next'

const {
  personal, loading, errorMsg,
  fetchPersonal, crearTerapeuta, actualizarTerapeuta, eliminarTerapeuta,
  fetchHorarios, guardarHorariosSemana
} = usePersonal()

// Horarios cacheados por personal_id
const horariosMap = ref<Record<string, Set<number>>>({})

async function cargarHorariosAll() {
  for (const t of personal.value) {
    const h = await fetchHorarios(t.id)
    horariosMap.value[t.id] = new Set(h.filter(x => x.activo).map(x => x.dia_semana))
  }
}

function tieneHorario(personalId: string, dia: number) {
  return horariosMap.value[personalId]?.has(dia) ?? false
}

function initials(nombre: string) {
  return nombre.split(' ').slice(0, 2).map(w => w[0]).join('').toUpperCase()
}

function getEspEmoji(cat: string) {
  return CATEGORIAS_SERVICIO.find(c => c.value === cat)?.emoji ?? '🌿'
}

// ── Form terapeuta ────────────────────────────────────────────────
const showForm = ref(false)
const saving = ref(false)
const formError = ref<string | null>(null)
const editando = ref<Terapeuta | null>(null)

const form = ref({
  nombre: '',
  telefono: null as string | null,
  especialidades: [] as string[],
  color_agenda: '#8b5cf6',
  activo: true,
  profile_id: null as string | null,
})

function openForm(t?: Terapeuta) {
  editando.value = t ?? null
  formError.value = null
  if (t) {
    form.value = { nombre: t.nombre, telefono: t.telefono, especialidades: [...t.especialidades], color_agenda: t.color_agenda, activo: t.activo, profile_id: t.profile_id }
  } else {
    form.value = { nombre: '', telefono: null, especialidades: [], color_agenda: '#8b5cf6', activo: true, profile_id: null }
  }
  showForm.value = true
}

async function guardar() {
  formError.value = null
  saving.value = true
  try {
    const payload = { ...form.value, especialidades: form.value.especialidades as any }
    if (editando.value) {
      await actualizarTerapeuta(editando.value.id, payload)
    } else {
      await crearTerapeuta(payload)
    }
    showForm.value = false
    await cargarHorariosAll()
  } catch (e: any) {
    formError.value = e.message ?? 'Error al guardar'
  } finally {
    saving.value = false
  }
}

async function confirmarEliminar(t: Terapeuta) {
  if (!confirm(`¿Eliminar a "${t.nombre}"? Esta acción no se puede deshacer.`)) return
  await eliminarTerapeuta(t.id)
}

// ── Horario semanal ───────────────────────────────────────────────
const showHorario = ref(false)
const savingHorario = ref(false)
const horarioError = ref<string | null>(null)
const terapeutaHorario = ref<Terapeuta | null>(null)

const horarioForm = ref<Array<{ dia_semana: number; hora_inicio: string; hora_fin: string; activo: boolean }>>([])

async function openHorario(t: Terapeuta) {
  terapeutaHorario.value = t
  horarioError.value = null
  const existentes = await fetchHorarios(t.id)
  const existMap: Record<number, typeof existentes[0]> = {}
  for (const h of existentes) existMap[h.dia_semana] = h

  // Lun–Dom (1 → 6 → 0)
  horarioForm.value = [1, 2, 3, 4, 5, 6, 0].map(d => ({
    dia_semana: d,
    hora_inicio: existMap[d]?.hora_inicio ?? '09:00',
    hora_fin:    existMap[d]?.hora_fin    ?? '19:00',
    activo:      existMap[d]?.activo      ?? (d !== 0),
  }))

  showHorario.value = true
}

async function guardarHorario() {
  if (!terapeutaHorario.value) return
  horarioError.value = null
  savingHorario.value = true
  try {
    const rows = horarioForm.value.map(r => ({
      dia_semana: r.dia_semana,
      hora_inicio: r.hora_inicio,
      hora_fin:    r.hora_fin,
      activo:      r.activo,
    }))
    await guardarHorariosSemana(terapeutaHorario.value.id, rows)
    // Actualizar el cache de horarios
    horariosMap.value[terapeutaHorario.value.id] = new Set(
      rows.filter(r => r.activo).map(r => r.dia_semana)
    )
    showHorario.value = false
  } catch (e: any) {
    horarioError.value = e.message ?? 'Error al guardar horario'
  } finally {
    savingHorario.value = false
  }
}

onMounted(async () => {
  await fetchPersonal(false)
  await cargarHorariosAll()
})
</script>

<style scoped>
.view-page { padding: 24px; max-width: 1100px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px; gap: 12px; }
.page-header h1 { font-size: 26px; font-weight: 700; color: var(--foreground); margin: 0; }
.page-sub { color: var(--muted-foreground); font-size: 14px; margin: 4px 0 0; }

/* Grid */
.personal-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 16px; }

.terapeuta-card {
  background: var(--card); border: 1px solid var(--border); border-radius: var(--radius);
  padding: 18px; display: flex; flex-direction: column; gap: 12px;
  transition: box-shadow .2s;
}
.terapeuta-card:hover { box-shadow: 0 4px 16px rgba(45,34,53,.1); }

.card-top { display: flex; align-items: flex-start; gap: 12px; }
.avatar-circle {
  width: 44px; height: 44px; border-radius: 12px; flex-shrink: 0;
  display: flex; align-items: center; justify-content: center;
  color: white; font-weight: 700; font-size: 16px; letter-spacing: .02em;
}
.card-info { flex: 1; min-width: 0; }
.terapeuta-nombre { font-weight: 700; font-size: 15px; color: var(--foreground); }
.esp-chips { display: flex; gap: 4px; flex-wrap: wrap; margin-top: 4px; }
.esp-chip { font-size: 10px; font-weight: 700; padding: 2px 7px; border-radius: 999px; background: var(--secondary); color: var(--secondary-foreground); }

.card-actions { display: flex; gap: 4px; }
.card-meta { display: flex; align-items: center; gap: 6px; font-size: 13px; color: var(--muted-foreground); }

/* Horario chips */
.horario-chips { display: flex; gap: 4px; }
.dia-chip { padding: 3px 7px; border-radius: 999px; font-size: 11px; font-weight: 700; }
.dia-active { background: var(--primary); color: white; }
.dia-off { background: var(--muted); color: var(--muted-foreground); }

/* Horario editor */
.horario-editor { display: flex; flex-direction: column; gap: 10px; }
.horario-row { display: flex; align-items: center; gap: 12px; }
.horario-dia-check { display: flex; align-items: center; gap: 8px; min-width: 80px; font-weight: 600; font-size: 14px; cursor: pointer; }
.dia-label { min-width: 36px; }
.time-input { padding: 8px; border: 1.5px solid var(--border); border-radius: var(--radius); background: var(--background); color: var(--foreground); font-size: 14px; width: 110px; }
.time-sep { color: var(--muted-foreground); }
.descanso-label { color: var(--muted-foreground); font-size: 13px; font-style: italic; }
.hint-text { font-size: 13px; color: var(--muted-foreground); margin: 0 0 8px; }

/* Color selector */
.color-grid { display: flex; gap: 10px; flex-wrap: wrap; }
.color-swatch { width: 32px; height: 32px; border-radius: 8px; border: 3px solid transparent; cursor: pointer; transition: transform .15s; }
.color-swatch:hover { transform: scale(1.15); }
.color-swatch.selected { border-color: white; box-shadow: 0 0 0 3px var(--primary); }

/* Esp selector */
.esp-selector { display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; }
.esp-check { display: flex; align-items: center; gap: 6px; font-size: 13px; font-weight: 600; cursor: pointer; }

/* Common */
.icon-btn { display: inline-flex; align-items: center; justify-content: center; width: 32px; height: 32px; border-radius: 8px; border: 1px solid var(--border); background: transparent; color: var(--muted-foreground); cursor: pointer; transition: all .15s; }
.icon-btn:hover { background: var(--muted); color: var(--foreground); }
.icon-btn.danger:hover { background: #fee2e2; color: #dc2626; border-color: #dc2626; }
:is(.dark) .icon-btn.danger:hover { background: #450a0a; color: #f87171; border-color: #f87171; }

.empty-state { padding: 60px 24px; text-align: center; display: flex; flex-direction: column; align-items: center; gap: 12px; color: var(--muted-foreground); }
.spinner { width: 28px; height: 28px; border: 3px solid var(--border); border-top-color: var(--primary); border-radius: 50%; animation: spin .6s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }

.modal-backdrop { position: fixed; inset: 0; background: rgba(0,0,0,.45); backdrop-filter: blur(4px); z-index: 200; display: flex; align-items: center; justify-content: center; padding: 16px; }
.modal-box { background: var(--card); border-radius: calc(var(--radius) + 4px); width: 100%; max-width: 500px; box-shadow: 0 20px 60px rgba(0,0,0,.25); max-height: 90vh; overflow-y: auto; }
.modal-wide { max-width: 560px; }
.modal-header { display: flex; align-items: center; justify-content: space-between; padding: 20px 24px 0; }
.modal-header h2 { font-size: 20px; font-weight: 700; color: var(--foreground); margin: 0; }
.modal-form { padding: 20px 24px 24px; display: flex; flex-direction: column; gap: 14px; }
.modal-footer { display: flex; justify-content: flex-end; gap: 10px; padding-top: 12px; border-top: 1px solid var(--border); }

.field { display: flex; flex-direction: column; gap: 6px; }
.field label { font-size: 13px; font-weight: 600; color: var(--foreground); }
.field input, .field select { padding: 9px 12px; border: 1.5px solid var(--border); border-radius: var(--radius); background: var(--background); color: var(--foreground); font-size: 14px; }
.field input:focus, .field select:focus { outline: none; border-color: var(--primary); }
.field-check { display: flex; align-items: center; }
.check-label { display: flex; align-items: center; gap: 8px; font-size: 14px; font-weight: 600; cursor: pointer; }
.form-error { padding: 10px 14px; background: #fee2e2; color: #dc2626; border-radius: var(--radius); font-size: 13px; }
:is(.dark) .form-error { background: #450a0a; color: #f87171; }

@media (max-width: 600px) {
  .view-page { padding: 16px; }
  .personal-grid { grid-template-columns: 1fr; }
  .esp-selector { grid-template-columns: repeat(2, 1fr); }
}
</style>
