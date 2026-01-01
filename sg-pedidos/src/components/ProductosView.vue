<template>
  <div class="p-4">
    <h1>Productos</h1>

    <!-- FORMULARIO -->
    <section class="mt-4">
      <h2>{{ editandoId ? 'Editar producto' : 'Nuevo producto' }}</h2>

      <form @submit.prevent="handleSubmit">
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
          <input v-model="form.unidad" placeholder="pz, m2, etc." />
        </div>

        <div>
          <label>Precio base</label>
          <input v-model.number="form.precio_base" type="number" min="0" step="0.01" />
        </div>

        <div>
          <label>
            <input type="checkbox" v-model="form.activo" />
            Activo
          </label>
        </div>

        <button type="submit">
          {{ editandoId ? 'Guardar cambios' : 'Crear producto' }}
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
            <th>Unidad</th>
            <th>Precio base</th>
            <th>Activo</th>
            <th>Acciones</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="p in productos" :key="p.id">
            <td>{{ p.nombre }}</td>
            <td>{{ p.unidad || '-' }}</td>
            <td>${{ p.precio_base }}</td>
            <td>{{ p.activo ? 'Sí' : 'No' }}</td>
            <td>
              <button @click="editar(p)">Editar</button>
              <button @click="borrar(p.id)">Eliminar</button>
            </td>
          </tr>
        </tbody>
      </table>
    </section>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { useProductos } from '../composables/useProductos'

const {
  productos,
  loading,
  errorMsg,
  fetchProductos,
  crearProducto,
  actualizarProducto,
  eliminarProducto
} = useProductos()

const form = reactive({
  nombre: '',
  descripcion: '',
  unidad: '',
  precio_base: 0,
  activo: true
})

const editandoId = ref<string | null>(null)

onMounted(() => {
  fetchProductos()
})

function resetForm() {
  form.nombre = ''
  form.descripcion = ''
  form.unidad = ''
  form.precio_base = 0
  form.activo = true
}

async function handleSubmit() {
  if (!form.nombre) return

  const payload = {
    nombre: form.nombre,
    descripcion: form.descripcion || undefined,
    unidad: form.unidad || undefined,
    precio_base: form.precio_base,
    activo: form.activo
  }

  if (editandoId.value) {
    await actualizarProducto(editandoId.value, payload)
  } else {
    await crearProducto(payload)
  }

  resetForm()
  editandoId.value = null
}

function editar(p: any) {
  editandoId.value = p.id
  form.nombre = p.nombre
  form.descripcion = p.descripcion || ''
  form.unidad = p.unidad || ''
  form.precio_base = p.precio_base || 0
  form.activo = p.activo
}

function cancelarEdicion() {
  editandoId.value = null
  resetForm()
}

async function borrar(id: string) {
  if (!confirm('¿Eliminar este producto?')) return
  await eliminarProducto(id)
}
</script>
