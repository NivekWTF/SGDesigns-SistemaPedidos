<template>
  <div class="p-6 products-page">
    <header class="page-header">
      <div>
        <h1 class="page-title">Productos</h1>
        <p class="page-sub">Gestiona tus productos</p>
      </div>
      <div class="header-actions">
        <div class="search">
          <input v-model="searchTerm" placeholder="Buscar por nombre..." />
        </div>
        <button type="button" class="btn-primary" @click="scrollToForm">+ Add Producto</button>
      </div>
    </header>

    <section class="stats-grid">
      <div class="stat-card">
        <div class="stat-num">{{ productos.length }}</div>
        <div class="stat-label">Total Productos</div>
      </div>
      <div class="stat-card">
        <div class="stat-num">{{ activosCount }}</div>
        <div class="stat-label">Activos</div>
      </div>
      <div class="stat-card">
        <div class="stat-num">{{ inactivosCount }}</div>
        <div class="stat-label">Inactivos</div>
      </div>
      <div class="stat-card">
        <div class="stat-num">{{ productos.length }}</div>
        <div class="stat-label">Unidades</div>
      </div>
    </section>

    <!-- FORMULARIO -->
    <section class="mt-4" ref="createForm">
      <h2>{{ editandoId ? 'Editar producto' : 'Nuevo producto' }}</h2>
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
    <section class="mt-8 list-section">
      <h2>Listado</h2>

      <p v-if="loading">Cargando...</p>
      <p v-else-if="errorMsg">⚠️ {{ errorMsg }}</p>

      <div v-else class="orders-table">
        <div class="orders-row header">
          <div>Nombre</div>
          <div>Unidad</div>
          <div>Precio base</div>
          <div>Activo</div>
          <div>Acciones</div>
        </div>

        <div v-for="p in filteredProductos" :key="p.id" class="orders-row">
          <div>{{ p.nombre }}</div>
          <div>{{ p.unidad || '-' }}</div>
          <div>${{ p.precio_base }}</div>
          <div>{{ p.activo ? 'Sí' : 'No' }}</div>
          <div class="actions">
            <button class="btn-delete" @click="editar(p)">Editar</button>
            <button class="btn-delete" @click="borrar(p.id)">Eliminar</button>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref, computed } from 'vue'
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
const searchTerm = ref('')

const filteredProductos = computed(() => {
  const q = (searchTerm.value || '').toLowerCase().trim()
  if (!q) return productos.value
  return productos.value.filter(p => (p.nombre || '').toLowerCase().includes(q))
})

const activosCount = computed(() => productos.value.filter(p => p.activo).length)
const inactivosCount = computed(() => productos.value.filter(p => !p.activo).length)

const createForm = ref<HTMLElement | null>(null)

function scrollToForm() {
  const el = createForm.value as HTMLElement | null
  if (el && typeof el.scrollIntoView === 'function') el.scrollIntoView({ behavior: 'smooth' })
}

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
.orders-row { display:grid;grid-template-columns: 2fr 1fr 1fr 1fr 1fr;align-items:center;padding:12px;border-bottom:1px solid #f3f3f3 }
.orders-row.header { font-weight:600;color:#444;background:#fafafa }
.actions { display:flex;gap:8px;justify-content:flex-end }
.btn-delete { background:#fff;border:1px solid #eee;padding:6px 8px;border-radius:6px }
</style>
