<template>
  <div class="p-6 clients-page">
    <header class="page-header">
      <div>
        <h1 class="page-title">Clientes</h1>
        <p class="page-sub">Gestiona tus clientes</p>
      </div>
        <!-- header actions moved below list title -->
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
    <!-- form moved to modal -->
    <NewClientForm v-if="showNewClient" :initialClient="editingClient" @close="showNewClient = false; editingClient = null" @created="onCreatedClient" />

    <!-- LISTADO -->
    <section class="mt-8 list-section">
      <h2>Listado</h2>

      <div class="list-controls" style="display:flex;justify-content:space-between;align-items:center;margin-top:12px;margin-bottom:8px">
        <div class="search" style="flex:1;max-width:60%">
          <input v-model="searchTerm" placeholder="Buscar por nombre, correo..." />
        </div>
        <button type="button" class="btn-primary" @click="openNewClient">+ Add Cliente</button>
      </div>

      <p v-if="loading">Cargando...</p>
      <p v-else-if="errorMsg">⚠️ {{ errorMsg }}</p>

      <div v-else class="orders-table">
        <div class="orders-row header">
          <div @click="setSort('nombre')" style="cursor:pointer">Nombre</div>
          <div>Teléfono</div>
          <div @click="setSort('correo')" style="cursor:pointer">Correo</div>
          <div @click="setSort('fecha')" style="cursor:pointer">Fecha</div>
          <div>Acciones</div>
        </div>

        <div v-for="c in paginatedClientes" :key="c.id" class="orders-row">
          <div>{{ c.nombre }}</div>
          <div>{{ c.telefono || '-' }}</div>
          <div>{{ c.correo || '-' }}</div>
          <div>{{ formatDate(c.created_at) }}</div>
          <div class="actions">
            <button class="btn-delete" @click="editar(c)">Editar</button>
            <button class="btn-delete" @click="borrar(c.id)">Eliminar</button>
          </div>
        </div>
        <div class="pagination" style="display:flex;gap:8px;align-items:center;justify-content:flex-end;padding:12px">
          <div>
            <button @click="prevPage" :disabled="page===1">Anterior</button>
            <button @click="nextPage" :disabled="page>=totalPages">Siguiente</button>
          </div>
          <div> Página {{ page }} / {{ totalPages }} </div>
          <div>
            <select v-model.number="pageSize">
              <option :value="5">5</option>
              <option :value="10">10</option>
              <option :value="20">20</option>
            </select>
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
import NewClientForm from './NewClientForm.vue'

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
const editingClient = ref<any | null>(null)
const searchTerm = ref('')

const filteredClientes = computed(() => {
  const q = (searchTerm.value || '').toLowerCase().trim()
  if (!q) return clientes.value
  return clientes.value.filter(c => (c.nombre || '').toLowerCase().includes(q) || (c.correo || '').toLowerCase().includes(q))
})

// Sorting & Pagination
const page = ref(1)
const pageSize = ref(10)
const sortBy = ref<'nombre'|'correo'|'fecha'>('nombre')
const sortDir = ref<'asc'|'desc'>('asc')

function setSort(column: typeof sortBy.value) {
  if (sortBy.value === column) {
    sortDir.value = sortDir.value === 'asc' ? 'desc' : 'asc'
  } else {
    sortBy.value = column
    sortDir.value = 'asc'
  }
}

const sortedClientes = computed(() => {
  const list = [...filteredClientes.value]
  list.sort((a,b) => {
    let va: any = ''
    let vb: any = ''
    if (sortBy.value === 'nombre') { va = (a.nombre||'').toLowerCase(); vb = (b.nombre||'').toLowerCase() }
    if (sortBy.value === 'correo') { va = (a.correo||'').toLowerCase(); vb = (b.correo||'').toLowerCase() }
    if (sortBy.value === 'fecha') { va = a.created_at || ''; vb = b.created_at || '' }
    if (va < vb) return sortDir.value === 'asc' ? -1 : 1
    if (va > vb) return sortDir.value === 'asc' ? 1 : -1
    return 0
  })
  return list
})

const totalPages = computed(() => Math.max(1, Math.ceil(sortedClientes.value.length / pageSize.value)))
const paginatedClientes = computed(() => {
  const start = (page.value - 1) * pageSize.value
  return sortedClientes.value.slice(start, start + pageSize.value)
})

function prevPage(){ if(page.value > 1) page.value-- }
function nextPage(){ if(page.value < totalPages.value) page.value++ }

const phoneCount = computed(() => clientes.value.filter(c => c.telefono).length)
const emailCount = computed(() => clientes.value.filter(c => c.correo).length)

// createForm/scroll helper removed; creation happens on modal

const showNewClient = ref(false)


function openNewClient(){ editingClient.value = null; showNewClient.value = true }

async function onCreatedClient(){
  showNewClient.value = false
  await fetchClientes()
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
  // open modal prefilled for editing
  editingClient.value = c
  showNewClient.value = true
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
.search input { width: 80vh; padding:12px 12px;border:1px solid #ddd;border-radius:6px }
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
