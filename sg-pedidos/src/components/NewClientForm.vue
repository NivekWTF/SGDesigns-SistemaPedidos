<template>
  <div class="modal-overlay" @click.self="close">
    <div class="modal-card">
        <header class="modal-header--accent">
          <div class="modal-title">
            <div class="logo-pill">👤</div>
            <div>
              <h3>Nuevo cliente</h3>
              <div class="subtitle">Agregar un cliente rápidamente</div>
            </div>
          </div>
          <button class="close" @click="close">✕</button>
        </header>

        <form @submit.prevent="handleCreate" class="form-grid">
          <div class="col">
            <label class="label">Nombre</label>
            <input v-model="form.nombre" required class="input" />

            <label class="label">Teléfono</label>
            <input v-model="form.telefono" class="input" />

            <label class="label">Correo</label>
            <input v-model="form.correo" type="email" class="input" />
          </div>

          <div class="form-actions full-width">
            <button type="submit" class="btn-primary">Crear cliente</button>
            <button type="button" class="btn-ghost" @click="close">Cancelar</button>
          </div>
        </form>
      </div>
  </div>
</template>

<script setup lang="ts">
import { reactive } from 'vue'
import { useClientes } from '../composables/useClientes'

const emit = defineEmits(['created','close'])
const { crearCliente, actualizarCliente } = useClientes()

const props = defineProps<{ initialClient?: any | null }>()

const form = reactive({ nombre: '', telefono: '', correo: '' })

if (props.initialClient) {
  form.nombre = props.initialClient.nombre || ''
  form.telefono = props.initialClient.telefono || ''
  form.correo = props.initialClient.correo || ''
}

async function handleCreate(){
  if(!form.nombre) return
  if (props.initialClient && props.initialClient.id) {
    await actualizarCliente(props.initialClient.id, { ...form })
  } else {
    await crearCliente({ ...form })
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
