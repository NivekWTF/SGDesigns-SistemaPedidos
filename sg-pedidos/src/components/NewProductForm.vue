<template>
  <div class="modal-overlay" @click.self="close">
    <div class="modal-card">
      <header class="modal-header">
        <h3>Nuevo producto</h3>
        <button class="close" @click="close">✕</button>
      </header>

      <form @submit.prevent="handleCreate">
        <div>
          <label>Nombre</label>
          <input v-model="form.nombre" required />
        </div>

        <div>
          <label>Descripción</label>
          <input v-model="form.descripcion" />
        </div>

        <div>
          <label>Unidad</label>
          <input v-model="form.unidad" />
        </div>

        <div>
          <label>Precio base</label>
          <input v-model.number="form.precio_base" type="number" min="0" step="0.01" />
        </div>

        <div class="form-actions">
          <button type="submit" class="btn-primary">Crear</button>
          <button type="button" @click="close">Cancelar</button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { reactive } from 'vue'
import { useProductos } from '../composables/useProductos'

const emit = defineEmits(['created','close'])
const { crearProducto } = useProductos()

const form = reactive({ nombre: '', descripcion: '', unidad: '', precio_base: 0, activo: true })

async function handleCreate(){
  if(!form.nombre) return
  await crearProducto({ ...form })
  emit('created')
}

function close(){ emit('close') }
</script>

<style scoped>
.modal-overlay{position:fixed;inset:0;background:rgba(0,0,0,0.3);display:flex;align-items:center;justify-content:center;padding:24px;z-index:60}
.modal-card{background:#fff;border-radius:8px;padding:16px;width:480px}
.modal-header{display:flex;justify-content:space-between;align-items:center}
.close{background:none;border:none;font-size:1.1rem}
.form-actions{display:flex;gap:8px;justify-content:flex-end;margin-top:12px}
.btn-primary{background:#059669;color:#fff;padding:8px 12px;border-radius:6px;border:none}
</style>
