<template>
  <div class="modal-overlay" @click.self="close">
    <div class="modal-card">
      <header class="modal-header--accent">
        <div class="modal-title">
          <div class="logo-pill">📦</div>
          <div>
            <h3>{{ props.initialProduct ? 'Editar producto' : 'Nuevo producto' }}</h3>
            <div class="subtitle">Agregar un producto al catálogo</div>
          </div>
        </div>
        <button class="close" @click="close">✕</button>
      </header>

        <form @submit.prevent="handleCreate" class="form-grid">
          <div class="col">
          <label class="label">Nombre</label>
          <input v-model="form.nombre" required class="input" />

          <label class="label">Descripción</label>
          <input v-model="form.descripcion" class="input" />

          <label class="label">Unidad</label>
          <input v-model="form.unidad" class="input" />

          <label class="label">Precio base</label>
          <input v-model.number="form.precio_base" type="number" min="0" step="0.01" class="input" />

          <label class="label">Costo de material</label>
          <input v-model.number="form.costo_material" type="number" min="0" step="0.01" class="input" />

          <label class="label">Stock</label>
          <input v-model.number="form.stock" type="number" min="0" step="1" class="input" />

          <!-- Stock Group Selector -->
          <label class="label">Grupo de stock vinculado</label>
          <div class="stock-group-selector">
            <select v-model="form.stock_group_id" class="input">
              <option :value="null">— Sin grupo (stock independiente)</option>
              <option v-for="g in stockGroups" :key="g.id" :value="g.id">{{ g.nombre }}</option>
            </select>
            <button type="button" class="btn-new-group" @click="showNewGroupInput = !showNewGroupInput" title="Crear nuevo grupo">+</button>
          </div>

          <!-- Create new group inline -->
          <div v-if="showNewGroupInput" class="new-group-row">
            <input v-model="newGroupName" placeholder="Nombre del grupo (ej: Tabloide Etiqueta)" class="input" @keyup.enter="handleCreateGroup" />
            <button type="button" class="btn-create-group" @click="handleCreateGroup" :disabled="!newGroupName.trim()">Crear</button>
          </div>

          <!-- Show siblings in the same group -->
          <div v-if="form.stock_group_id && siblings.length > 0" class="group-siblings">
            <div class="siblings-header">🔗 Comparte stock con:</div>
            <div v-for="s in siblings" :key="s.id" class="sibling-chip">
              {{ s.nombre }}
              <span class="sibling-stock">stock: {{ typeof s.stock === 'number' ? s.stock : '-' }}</span>
            </div>
          </div>

          <div v-if="form.stock_group_id && siblings.length === 0" class="group-siblings">
            <div class="siblings-header">🔗 Este será el primer producto en el grupo</div>
          </div>

          <label class="label"><input type="checkbox" v-model="form.activo" /> Activo</label>
        </div>

        <div class="form-actions full-width">
          <button type="submit" class="btn-primary">{{ props.initialProduct ? 'Guardar' : 'Crear producto' }}</button>
          <button type="button" class="btn-ghost" @click="close">Cancelar</button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref, computed, onMounted } from 'vue'
import { useProductos } from '../composables/useProductos'

const emit = defineEmits(['created','close'])
const { crearProducto, actualizarProducto, stockGroups, fetchStockGroups, crearStockGroup, getGroupSiblings, productos } = useProductos()

const props = defineProps<{ initialProduct?: any | null }>()

const form = reactive({ nombre: '', descripcion: '', unidad: '', precio_base: 0, costo_material: 0, stock: 0, stock_group_id: null as string | null, activo: true })
const showNewGroupInput = ref(false)
const newGroupName = ref('')

if (props.initialProduct) {
  form.nombre = props.initialProduct.nombre || ''
  form.descripcion = props.initialProduct.descripcion || ''
  form.unidad = props.initialProduct.unidad || ''
  form.precio_base = props.initialProduct.precio_base || 0
  form.costo_material = typeof props.initialProduct.costo_material === 'number' ? props.initialProduct.costo_material : 0
  form.stock = typeof props.initialProduct.stock === 'number' ? props.initialProduct.stock : 0
  form.stock_group_id = props.initialProduct.stock_group_id || null
  form.activo = !!props.initialProduct.activo
}

onMounted(() => {
  fetchStockGroups()
})

const siblings = computed(() => {
  if (!form.stock_group_id) return []
  const currentId = props.initialProduct?.id
  return getGroupSiblings(form.stock_group_id, currentId)
})

async function handleCreateGroup() {
  const name = newGroupName.value.trim()
  if (!name) return
  try {
    const group = await crearStockGroup(name)
    if (group) {
      form.stock_group_id = group.id
    }
    newGroupName.value = ''
    showNewGroupInput.value = false
  } catch (e) {
    console.error('Failed to create stock group', e)
  }
}

async function handleCreate(){
  if(!form.nombre) return
  const payload = {
    nombre: form.nombre,
    descripcion: form.descripcion || undefined,
    unidad: form.unidad || undefined,
    precio_base: form.precio_base,
    costo_material: typeof form.costo_material === 'number' ? form.costo_material : undefined,
    activo: form.activo,
    stock: typeof form.stock === 'number' ? form.stock : undefined,
    stock_group_id: form.stock_group_id || null
  }
  if (props.initialProduct && props.initialProduct.id) {
    await actualizarProducto(props.initialProduct.id, payload)
  } else {
    await crearProducto(payload)
  }
  emit('created')
}

function close(){ emit('close') }
</script>

<style scoped>
.modal-overlay{position:fixed;inset:0;background:rgba(2,6,23,0.45);display:flex;align-items:center;justify-content:center;padding:24px;z-index:60}
.modal-card{background:linear-gradient(180deg,#ffffff,#fbfdff);border-radius:12px;padding:18px;width:520px;box-shadow:0 12px 36px rgba(2,6,23,0.12);max-height:90vh;overflow-y:auto}
.modal-header--accent{display:flex;justify-content:space-between;align-items:center;padding-bottom:8px;border-bottom:1px solid #eef2f5}
.modal-title{display:flex;gap:12px;align-items:center}
.logo-pill{width:44px;height:44px;border-radius:10px;background:#0ea5a4;color:white;display:flex;align-items:center;justify-content:center;font-weight:700}
.modal-header--accent h3{margin:0;font-size:1.05rem}
.subtitle{font-size:0.85rem;color:#475569}
.close{background:none;border:none;font-size:1.1rem;cursor:pointer}
.form-grid{display:block;padding-top:12px}
.col{display:flex;flex-direction:column;gap:10px}
.label{font-weight:600;color:#334155}
.input{padding:10px;border:1px solid #e6eef2;border-radius:8px;width:100%;box-sizing:border-box}
.form-actions.full-width{display:flex;gap:8px;justify-content:flex-end;margin-top:12px}
.btn-primary{background:#059669;color:#fff;padding:8px 12px;border-radius:8px;border:none;cursor:pointer}
.btn-ghost{background:transparent;border:1px solid #e6eef2;padding:8px 12px;border-radius:8px;cursor:pointer}

/* Stock group selector */
.stock-group-selector{display:flex;gap:6px;align-items:center}
.stock-group-selector select{flex:1}
.btn-new-group{width:36px;height:36px;border-radius:8px;border:1px solid #e6eef2;background:#f0fdf4;color:#059669;font-size:1.2rem;font-weight:700;cursor:pointer;display:flex;align-items:center;justify-content:center;flex-shrink:0;transition:all 0.2s}
.btn-new-group:hover{background:#059669;color:#fff}

.new-group-row{display:flex;gap:6px;align-items:center}
.new-group-row input{flex:1}
.btn-create-group{background:#059669;color:#fff;padding:8px 12px;border-radius:8px;border:none;cursor:pointer;white-space:nowrap;font-size:0.85rem}
.btn-create-group:disabled{opacity:0.5;cursor:not-allowed}

.group-siblings{background:#f0fdf4;border:1px solid #bbf7d0;border-radius:8px;padding:10px;display:flex;flex-direction:column;gap:6px}
.siblings-header{font-size:0.85rem;font-weight:600;color:#166534}
.sibling-chip{display:flex;justify-content:space-between;align-items:center;background:#dcfce7;padding:6px 10px;border-radius:6px;font-size:0.85rem;color:#166534}
.sibling-stock{font-size:0.8rem;color:#15803d;font-weight:600}

/* Dark mode */
:is(.dark) .modal-overlay{background:rgba(0,0,0,0.6)}
:is(.dark) .modal-card{background:linear-gradient(180deg,#111c2e,#0f1729);box-shadow:0 12px 36px rgba(0,0,0,0.3)}
:is(.dark) .modal-header--accent{border-bottom-color:#1e293b}
:is(.dark) .modal-header--accent h3{color:#e2e8f0}
:is(.dark) .subtitle{color:#94a3b8}
:is(.dark) .close{color:#94a3b8}
:is(.dark) .label{color:#94a3b8}
:is(.dark) .input{background:#0f1729;border-color:#334155;color:#e2e8f0}
:is(.dark) .btn-ghost{border-color:#334155;color:#cbd5e1}

:is(.dark) .btn-new-group{background:#0f2922;border-color:#1e3a34;color:#4ade80}
:is(.dark) .btn-new-group:hover{background:#059669;color:#fff}
:is(.dark) .group-siblings{background:#0f2922;border-color:#1e3a34}
:is(.dark) .siblings-header{color:#4ade80}
:is(.dark) .sibling-chip{background:#14392e;color:#86efac}
:is(.dark) .sibling-stock{color:#4ade80}
:is(.dark) .new-group-row input{background:#0f1729;border-color:#334155;color:#e2e8f0}
</style>
