<template>
  <div class="modal-overlay" @click.self="close">
    <div class="modal-card">
      <header class="modal-header">
        <h3>Nuevo cliente</h3>
        <button class="close" @click="close">✕</button>
      </header>

      <form @submit.prevent="handleCreate">
        <div>
          <label>Nombre</label>
          <input v-model="form.nombre" required />
        </div>

        <div>
          <label>Teléfono</label>
          <input v-model="form.telefono" />
        </div>

        <div>
          <label>Correo</label>
          <input v-model="form.correo" type="email" />
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
import { useClientes } from '../composables/useClientes'

const emit = defineEmits(['created','close'])
const { crearCliente } = useClientes()

const form = reactive({ nombre: '', telefono: '', correo: '' })

async function handleCreate(){
  if(!form.nombre) return
  await crearCliente({ ...form })
  emit('created')
}

function close(){ emit('close') }
</script>

<style scoped>
.modal-overlay{position:fixed;inset:0;background:rgba(0,0,0,0.3);display:flex;align-items:center;justify-content:center;padding:24px;z-index:60}
.modal-card{background:#fff;border-radius:8px;padding:16px;width:420px}
.modal-header{display:flex;justify-content:space-between;align-items:center}
.close{background:none;border:none;font-size:1.1rem}
.form-actions{display:flex;gap:8px;justify-content:flex-end;margin-top:12px}
.btn-primary{background:#059669;color:#fff;padding:8px 12px;border-radius:6px;border:none}
</style>
