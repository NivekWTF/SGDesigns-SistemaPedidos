<template>
  <div class="p-6 clients-page">
    <header class="page-header">
      <div>
        <h1 class="page-title">Clientes</h1>
        <p class="page-sub">Gestiona tus clientes</p>
      </div>
      <div class="header-actions">
        <div class="search">
          <input v-model="searchTerm" placeholder="Buscar por nombre, correo..." />
        </div>
        <button type="button" class="btn-primary" @click="scrollToForm">+ Add Cliente</button>
      </div>
    </header>

    <section class="stats-grid">
      <div class="stat-card">
        <div class="stat-num">{{ clientes.length }}</div>
        <div class="stat-label">Total Clientes</div>
      </div>
      <div class="stat-card">
        <div class="stat-num">{{ phoneCount }}</div>
        <div class="stat-label">Con teléfono</div>
      </div>
      <div class="stat-card">
        <div class="stat-num">{{ emailCount }}</div>
        <div class="stat-label">Con correo</div>
      </div>
      <div class="stat-card">
        <div class="stat-num">{{ clientes.length }}</div>
        <div class="stat-label">Activos</div>
      </div>
    </section>

    <!-- FORMULARIO -->
    <section class="mt-4" ref="createForm">
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
    <section class="mt-8 list-section">
      <h2>Listado</h2>

      <p v-if="loading">Cargando...</p>
      <p v-else-if="errorMsg">⚠️ {{ errorMsg }}</p>

      <div v-else class="orders-table">
        <div class="orders-row header">
          <div>Nombre</div>
          <div>Teléfono</div>
          <div>Correo</div>
          <div>Fecha</div>
          <div>Acciones</div>
        </div>

        <div v-for="c in filteredClientes" :key="c.id" class="orders-row">
          <div>{{ c.nombre }}</div>
          <div>{{ c.telefono || '-' }}</div>
          <div>{{ c.correo || '-' }}</div>
          <div>{{ formatDate(c.created_at) }}</div>
          <div class="actions">
            <button class="btn-delete" @click="editar(c)">Editar</button>
            <button class="btn-delete" @click="borrar(c.id)">Eliminar</button>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref, computed } from 'vue'
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
const searchTerm = ref('')

const filteredClientes = computed(() => {
  const q = (searchTerm.value || '').toLowerCase().trim()
  if (!q) return clientes.value
  return clientes.value.filter(c => (c.nombre || '').toLowerCase().includes(q) || (c.correo || '').toLowerCase().includes(q))
})

const phoneCount = computed(() => clientes.value.filter(c => c.telefono).length)
const emailCount = computed(() => clientes.value.filter(c => c.correo).length)

const createForm = ref<HTMLElement | null>(null)

function scrollToForm() {
  const el = createForm.value as HTMLElement | null
  if (el && typeof el.scrollIntoView === 'function') el.scrollIntoView({ behavior: 'smooth' })
}

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

<style scoped>
.page-header { display:flex;justify-content:space-between;align-items:center;margin-bottom:12px }
.page-title { margin:0;font-size:1.25rem }
.page-sub { margin:0;color:#666 }
.header-actions { display:flex;gap:12px;align-items:center }
.search input { padding:8px 12px;border:1px solid #ddd;border-radius:6px }
.btn-primary { background:#059669;color:white;padding:8px 12px;border-radius:6px;border:none }
.stats-grid { display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin:12px 0 }
.stat-card { background:#fff;border:1px solid #eee;padding:12px;border-radius:8px }
.stat-num { font-weight:700;font-size:1.1rem }
.stat-label { color:#666 }
.orders-table { margin-top:12px;border-top:1px solid #eee }
.orders-row { display:grid;grid-template-columns: 2fr 1fr 2fr 1fr 1fr;align-items:center;padding:12px;border-bottom:1px solid #f3f3f3 }
.orders-row.header { font-weight:600;color:#444;background:#fafafa }
.actions { display:flex;gap:8px;justify-content:flex-end }
.btn-delete { background:#fff;border:1px solid #eee;padding:6px 8px;border-radius:6px }
</style>
