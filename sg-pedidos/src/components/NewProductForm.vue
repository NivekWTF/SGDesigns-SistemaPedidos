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
import { reactive } from 'vue'
import { useProductos } from '../composables/useProductos'

const emit = defineEmits(['created','close'])
const { crearProducto, actualizarProducto } = useProductos()

const props = defineProps<{ initialProduct?: any | null }>()

const form = reactive({ nombre: '', descripcion: '', unidad: '', precio_base: 0, costo_material: 0, stock: 0, activo: true })

if (props.initialProduct) {
  form.nombre = props.initialProduct.nombre || ''
  form.descripcion = props.initialProduct.descripcion || ''
  form.unidad = props.initialProduct.unidad || ''
  form.precio_base = props.initialProduct.precio_base || 0
  form.costo_material = typeof props.initialProduct.costo_material === 'number' ? props.initialProduct.costo_material : 0
  form.stock = typeof props.initialProduct.stock === 'number' ? props.initialProduct.stock : 0
  form.activo = !!props.initialProduct.activo
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
    stock: typeof form.stock === 'number' ? form.stock : undefined
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
.modal-card{background:linear-gradient(180deg,#ffffff,#fbfdff);border-radius:12px;padding:18px;width:520px;box-shadow:0 12px 36px rgba(2,6,23,0.12)}
.modal-header--accent{display:flex;justify-content:space-between;align-items:center;padding-bottom:8px;border-bottom:1px solid #eef2f5}
.modal-title{display:flex;gap:12px;align-items:center}
.logo-pill{width:44px;height:44px;border-radius:10px;background:#0ea5a4;color:white;display:flex;align-items:center;justify-content:center;font-weight:700}
.modal-header--accent h3{margin:0;font-size:1.05rem}
.subtitle{font-size:0.85rem;color:#475569}
.close{background:none;border:none;font-size:1.1rem}
.form-grid{display:block;padding-top:12px}
.col{display:flex;flex-direction:column;gap:10px}
.label{font-weight:600;color:#334155}
.input{padding:10px;border:1px solid #e6eef2;border-radius:8px;width:100%;box-sizing:border-box}
.form-actions.full-width{display:flex;gap:8px;justify-content:flex-end;margin-top:12px}
.btn-primary{background:#059669;color:#fff;padding:8px 12px;border-radius:8px;border:none}
.btn-ghost{background:transparent;border:1px solid #e6eef2;padding:8px 12px;border-radius:8px}
</style>
