<template>
  <div class="p-4">
    <h1>Clientes</h1>

    <!-- FORMULARIO -->
    <section class="mt-4">
      <h2>{{ editandoId ? 'Editar cliente' : 'Nuevo cliente' }}</h2>

      <form @submit.prevent="handleSubmit">
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

        <button type="submit">
          {{ editandoId ? 'Guardar cambios' : 'Crear cliente' }}
        </button>
        <button v-if="editandoId" type="button" @click="cancelarEdicion">
          Cancelar
        </button>
      </form>
    </section>

    <!-- LISTADO -->
    <section class="mt-8">
      <h2>Listado</h2>

      <p v-if="loading">Cargando...</p>
      <p v-else-if="errorMsg">⚠️ {{ errorMsg }}</p>

      <table v-else>
        <thead>
          <tr>
            <th>Nombre</th>
            <th>Teléfono</th>
            <th>Correo</th>
            <th>Fecha alta</th>
            <th>Acciones</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="c in clientes" :key="c.id">
            <td>{{ c.nombre }}</td>
            <td>{{ c.telefono || '-' }}</td>
            <td>{{ c.correo || '-' }}</td>
            <td>{{ formatDate(c.created_at) }}</td>
            <td>
              <button @click="editar(c)">Editar</button>
              <button @click="borrar(c.id)">Eliminar</button>
            </td>
          </tr>
        </tbody>
      </table>
    </section>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { useClientes } from '../composables/useClientes'
import { useFormat } from '../composables/useFormat'

const {
  clientes,
  loading,
  errorMsg,
  fetchClientes,
  crearCliente,
  actualizarCliente,
  eliminarCliente
} = useClientes()

const form = reactive({
  nombre: '',
  telefono: '',
  correo: ''
})

const editandoId = ref<string | null>(null)

onMounted(() => {
  fetchClientes()
})

const { formatDate } = useFormat()

function resetForm() {
  form.nombre = ''
  form.telefono = ''
  form.correo = ''
}

async function handleSubmit() {
  if (!form.nombre) return

  if (editandoId.value) {
    await actualizarCliente(editandoId.value, { ...form })
  } else {
    await crearCliente({ ...form })
  }

  resetForm()
  editandoId.value = null
}

function editar(c: any) {
  editandoId.value = c.id
  form.nombre = c.nombre
  form.telefono = c.telefono || ''
  form.correo = c.correo || ''
}

function cancelarEdicion() {
  editandoId.value = null
  resetForm()
}

async function borrar(id: string) {
  if (!confirm('¿Eliminar este cliente?')) return
  await eliminarCliente(id)
}
</script>
