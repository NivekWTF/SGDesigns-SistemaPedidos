<template>
  <div class="view-page">
    <div class="page-header">
      <div>
        <h1 class="font-spa-display">Paquetes</h1>
        <p class="page-sub">Combos y promociones de servicios</p>
      </div>
      <button class="btn-primary" @click="openForm()"><Plus class="h-4 w-4" /> Nuevo paquete</button>
    </div>

    <div v-if="loading" class="empty-state"><div class="spinner"/><p>Cargando...</p></div>
    <div v-else-if="paquetes.length === 0" class="empty-state">
      <Gift class="h-10 w-10 op-30"/><p>Sin paquetes creados aún</p>
      <button class="btn-primary" @click="openForm()">Crear el primero</button>
    </div>

    <div v-else class="paquetes-grid">
      <div v-for="p in paquetes" :key="p.id" class="paquete-card" :class="!p.activo && 'inactive'">
        <div class="paquete-top">
          <div class="paquete-nombre">{{ p.nombre }}</div>
          <div class="paquete-actions">
            <button class="icon-btn" @click="openForm(p)"><Pencil class="h-4 w-4"/></button>
            <button class="icon-btn danger" @click="del(p)"><Trash2 class="h-4 w-4"/></button>
          </div>
        </div>
        <div v-if="p.descripcion" class="paquete-desc">{{ p.descripcion }}</div>

        <div class="servicios-list">
          <div v-for="ps in p.paquete_servicios" :key="ps.id" class="servicio-item">
            <span class="item-cat">{{ getCatEmoji(ps.servicios?.categoria) }}</span>
            <span class="item-nombre">{{ ps.servicios?.nombre }}</span>
            <span class="item-dur">{{ ps.servicios?.duracion_min }} min</span>
            <span v-if="ps.cantidad > 1" class="item-qty">×{{ ps.cantidad }}</span>
          </div>
        </div>

        <div class="paquete-footer">
          <div class="paquete-meta">
            <Clock class="h-3.5 w-3.5"/>
            {{ totalDuracion(p) }} min
          </div>
          <div v-if="p.vigencia_dias" class="paquete-meta">
            <CalendarDays class="h-3.5 w-3.5"/>
            {{ p.vigencia_dias }} días de vigencia
          </div>
          <div class="paquete-precio">{{ fmt(p.precio) }}</div>
        </div>
      </div>
    </div>

    <!-- Modal -->
    <Teleport to="body">
      <div v-if="showForm" class="modal-backdrop" @click.self="showForm = false">
        <div class="modal-box modal-wide">
          <div class="modal-header">
            <h2 class="font-spa-display">{{ editando ? 'Editar paquete' : 'Nuevo paquete' }}</h2>
            <button class="icon-btn" @click="showForm = false"><X class="h-5 w-5"/></button>
          </div>
          <form @submit.prevent="guardar" class="modal-form">
            <div class="field">
              <label>Nombre *</label>
              <input v-model="form.nombre" required placeholder="Ej. Escapada de bienestar"/>
            </div>
            <div class="field">
              <label>Descripción</label>
              <textarea v-model="form.descripcion" rows="2" placeholder="Descripción del paquete..."/>
            </div>
            <div class="fields-row">
              <div class="field">
                <label>Precio *</label>
                <div class="input-prefix">
                  <span>$</span>
                  <input v-model.number="form.precio" type="number" min="0" step="0.01" required/>
                </div>
              </div>
              <div class="field">
                <label>Vigencia (días)</label>
                <input v-model.number="form.vigencia_dias" type="number" min="1" placeholder="Sin vencimiento"/>
              </div>
            </div>

            <!-- Servicios incluidos -->
            <div class="field">
              <label>Servicios incluidos *</label>
              <div class="servicios-selector">
                <div v-if="servicios.length === 0" class="hint-text">Primero agrega servicios al catálogo</div>
                <label v-for="s in serviciosActivos" :key="s.id" class="servicio-check">
                  <input type="checkbox" :value="s.id" v-model="formItemIds"/>
                  <span class="svc-check-info">
                    <span>{{ getCatEmoji(s.categoria) }} {{ s.nombre }}</span>
                    <span class="svc-check-meta">{{ s.duracion_min }} min · {{ fmt(s.precio) }}</span>
                  </span>
                </label>
              </div>
            </div>

            <div class="field-check">
              <label class="check-label"><input type="checkbox" v-model="form.activo"/> Paquete activo</label>
            </div>

            <div v-if="formError" class="form-error">{{ formError }}</div>
            <div class="modal-footer">
              <button type="button" class="btn-ghost" @click="showForm = false">Cancelar</button>
              <button type="submit" class="btn-primary" :disabled="saving">
                <Loader2 v-if="saving" class="h-4 w-4 animate-spin"/>
                {{ editando ? 'Guardar cambios' : 'Crear paquete' }}
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
import { usePaquetes } from '../composables/usePaquetes'
import { useServicios, CATEGORIAS_SERVICIO } from '../composables/useServicios'
import type { Paquete } from '../composables/usePaquetes'
import { Gift, Plus, Pencil, Trash2, X, Clock, CalendarDays, Loader2 } from 'lucide-vue-next'

const { paquetes, loading, errorMsg, fetchPaquetes, crearPaquete, actualizarPaquete, eliminarPaquete } = usePaquetes()
const { servicios, fetchServicios } = useServicios()

const serviciosActivos = computed(() => servicios.value.filter(s => s.activo))

function getCatEmoji(cat?: string) {
  return CATEGORIAS_SERVICIO.find(c => c.value === cat)?.emoji ?? '🌿'
}
function fmt(n: number) {
  return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN' }).format(n)
}
function totalDuracion(p: Paquete) {
  return (p.paquete_servicios ?? []).reduce((sum, ps) => sum + (ps.servicios?.duracion_min ?? 0) * ps.cantidad, 0)
}

const showForm = ref(false)
const saving = ref(false)
const formError = ref<string | null>(null)
const editando = ref<Paquete | null>(null)
const formItemIds = ref<string[]>([])

const form = ref({ nombre: '', descripcion: '', precio: 0, vigencia_dias: null as number | null, activo: true })

function openForm(p?: Paquete) {
  editando.value = p ?? null
  formError.value = null
  formItemIds.value = p?.paquete_servicios?.map(ps => ps.servicio_id) ?? []
  form.value = p
    ? { nombre: p.nombre, descripcion: p.descripcion ?? '', precio: p.precio, vigencia_dias: p.vigencia_dias, activo: p.activo }
    : { nombre: '', descripcion: '', precio: 0, vigencia_dias: null, activo: true }
  showForm.value = true
}

async function guardar() {
  if (formItemIds.value.length === 0) { formError.value = 'Agrega al menos un servicio'; return }
  formError.value = null
  saving.value = true
  const items = formItemIds.value.map(id => ({ servicio_id: id, cantidad: 1 }))
  try {
    if (editando.value) {
      await actualizarPaquete(editando.value.id, form.value, items)
    } else {
      await crearPaquete(form.value, items)
    }
    showForm.value = false
  } catch (e: any) {
    formError.value = e.message ?? 'Error al guardar'
  } finally {
    saving.value = false
  }
}

async function del(p: Paquete) {
  if (!confirm(`¿Eliminar "${p.nombre}"?`)) return
  await eliminarPaquete(p.id)
}

onMounted(async () => { await fetchServicios(true); await fetchPaquetes() })
</script>

<style scoped>
.view-page { padding: 24px; max-width: 1100px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px; gap: 12px; }
.page-header h1 { font-size: 26px; font-weight: 700; color: var(--foreground); margin: 0; }
.page-sub { color: var(--muted-foreground); font-size: 14px; margin: 4px 0 0; }

.paquetes-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 16px; }
.paquete-card { background: var(--card); border: 1px solid var(--border); border-radius: var(--radius); padding: 20px; display: flex; flex-direction: column; gap: 12px; transition: box-shadow .2s; }
.paquete-card:hover { box-shadow: 0 4px 20px rgba(45,34,53,.12); }
.paquete-card.inactive { opacity: .55; }
.paquete-top { display: flex; align-items: center; justify-content: space-between; gap: 8px; }
.paquete-nombre { font-weight: 700; font-size: 16px; color: var(--foreground); }
.paquete-desc { font-size: 13px; color: var(--muted-foreground); }
.paquete-actions { display: flex; gap: 4px; }

.servicios-list { display: flex; flex-direction: column; gap: 6px; border-top: 1px solid var(--border); padding-top: 10px; }
.servicio-item { display: flex; align-items: center; gap: 8px; font-size: 13px; }
.item-cat { font-size: 14px; }
.item-nombre { flex: 1; color: var(--foreground); font-weight: 500; }
.item-dur { color: var(--muted-foreground); font-size: 12px; }
.item-qty { background: var(--secondary); color: var(--secondary-foreground); padding: 1px 6px; border-radius: 999px; font-size: 11px; font-weight: 700; }

.paquete-footer { display: flex; align-items: center; gap: 12px; border-top: 1px solid var(--border); padding-top: 10px; }
.paquete-meta { display: flex; align-items: center; gap: 4px; font-size: 12px; color: var(--muted-foreground); }
.paquete-precio { margin-left: auto; font-weight: 800; font-size: 18px; color: var(--primary); }

/* Selector servicios */
.servicios-selector { border: 1.5px solid var(--border); border-radius: var(--radius); max-height: 220px; overflow-y: auto; }
.servicio-check { display: flex; align-items: center; gap: 10px; padding: 10px 14px; cursor: pointer; border-bottom: 1px solid var(--border); transition: background .12s; }
.servicio-check:last-child { border-bottom: none; }
.servicio-check:hover { background: var(--muted); }
.svc-check-info { display: flex; flex-direction: column; flex: 1; }
.svc-check-meta { font-size: 11px; color: var(--muted-foreground); }

/* Common */
.icon-btn { display: inline-flex; align-items: center; justify-content: center; width: 32px; height: 32px; border-radius: 8px; border: 1px solid var(--border); background: transparent; color: var(--muted-foreground); cursor: pointer; transition: all .15s; }
.icon-btn:hover { background: var(--muted); color: var(--foreground); }
.icon-btn.danger:hover { background: #fee2e2; color: #dc2626; border-color: #dc2626; }
:is(.dark) .icon-btn.danger:hover { background: #450a0a; color: #f87171; border-color: #f87171; }
.empty-state { padding: 60px; text-align: center; display: flex; flex-direction: column; align-items: center; gap: 12px; color: var(--muted-foreground); }
.spinner { width: 28px; height: 28px; border: 3px solid var(--border); border-top-color: var(--primary); border-radius: 50%; animation: spin .6s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
.modal-backdrop { position: fixed; inset: 0; background: rgba(0,0,0,.45); backdrop-filter: blur(4px); z-index: 200; display: flex; align-items: center; justify-content: center; padding: 16px; }
.modal-box { background: var(--card); border-radius: calc(var(--radius) + 4px); width: 100%; max-width: 500px; box-shadow: 0 20px 60px rgba(0,0,0,.25); max-height: 92vh; overflow-y: auto; }
.modal-wide { max-width: 560px; }
.modal-header { display: flex; align-items: center; justify-content: space-between; padding: 20px 24px 0; }
.modal-header h2 { font-size: 20px; font-weight: 700; color: var(--foreground); margin: 0; }
.modal-form { padding: 20px 24px 24px; display: flex; flex-direction: column; gap: 14px; }
.modal-footer { display: flex; justify-content: flex-end; gap: 10px; padding-top: 8px; border-top: 1px solid var(--border); }
.field { display: flex; flex-direction: column; gap: 6px; }
.field label { font-size: 13px; font-weight: 600; color: var(--foreground); }
.field input, .field select, .field textarea { padding: 9px 12px; border: 1.5px solid var(--border); border-radius: var(--radius); background: var(--background); color: var(--foreground); font-size: 14px; font-family: inherit; }
.field input:focus, .field select:focus { outline: none; border-color: var(--primary); }
.fields-row { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
.input-prefix { display: flex; }
.input-prefix span { padding: 9px 10px; background: var(--muted); border: 1.5px solid var(--border); border-right: none; border-radius: var(--radius) 0 0 var(--radius); color: var(--muted-foreground); font-size: 14px; }
.input-prefix input { border-radius: 0 var(--radius) var(--radius) 0; flex: 1; min-width: 0; }
.field-check { display: flex; align-items: center; }
.check-label { display: flex; align-items: center; gap: 8px; font-size: 14px; font-weight: 600; cursor: pointer; }
.form-error { padding: 10px 14px; background: #fee2e2; color: #dc2626; border-radius: var(--radius); font-size: 13px; }
:is(.dark) .form-error { background: #450a0a; color: #f87171; }
.hint-text { padding: 12px; font-size: 13px; color: var(--muted-foreground); }
</style>
