<template>
  <div class="p-6 products-page">
    <header class="page-header">
      <div>
        <h1 class="page-title">Productos</h1>
        <p class="page-sub">Gestiona tus productos</p>
      </div>
      <!-- header actions moved below the list title -->
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

    <!-- form moved to modal -->
    <NewProductForm v-if="showNewProduct" :initialProduct="editingProduct" @close="showNewProduct = false; editingProduct = null" @created="onCreatedProduct" />

    <!-- LISTADO -->
    <section class="mt-8 list-section">
      <h2>Listado</h2>

      <div class="list-controls" style="display:flex;justify-content:space-between;align-items:center;margin-top:12px;margin-bottom:8px">
        <div class="search" style="flex:1;max-width:60%">
          <input v-model="searchTerm" placeholder="Buscar por nombre..." />
        </div>
        <button type="button" class="btn-primary" @click="openNewProduct">+ Nuevo producto</button>
      </div>

      <p v-if="loading">Cargando...</p>
      <p v-else-if="errorMsg">⚠️ {{ errorMsg }}</p>

      <div v-else class="orders-table">
        <div class="orders-row header">
          <div @click="setSort('nombre')" style="cursor:pointer">Nombre</div>
          <div>Unidad</div>
          <div @click="setSort('precio')" style="cursor:pointer">Precio base</div>
          <div>Costo material</div>
          <div>Stock</div>
          <div>Activo</div>
          <div>Acciones</div>
        </div>

        <div v-for="p in paginatedProductos" :key="p.id" class="orders-row">
          <div>
            {{ p.nombre }}
          </div>
          <div>{{ p.unidad || '-' }}</div>
          <div>{{ formatCurrency(p.precio_base) }}</div>
          <div>{{ formatCurrency(p.costo_material ?? 0) }}</div>
          <div>
            <span :class="['stock-badge', stockClass(p.stock)]">{{ typeof p.stock === 'number' ? p.stock : '-' }}</span>
          </div>
          <div>{{ p.activo ? 'Sí' : 'No' }}</div>
          <div class="actions">
            <button class="btn-delete" @click="editar(p)">Editar</button>
            <button class="btn-delete" @click="borrar(p.id)">Eliminar</button>
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
import { useProductos } from '../composables/useProductos'
import { useFormat } from '../composables/useFormat'
import NewProductForm from './NewProductForm.vue'

const {
  productos,
  loading,
  errorMsg,
  fetchProductos,
  crearProducto,
  actualizarProducto,
  eliminarProducto
} = useProductos()

const { formatCurrency } = useFormat()

const form = reactive({
  nombre: '',
  descripcion: '',
  unidad: '',
  precio_base: 0,
  activo: true
})

const editandoId = ref<string | null>(null)
const editingProduct = ref<any | null>(null)
const searchTerm = ref('')

const filteredProductos = computed(() => {
  const q = (searchTerm.value || '').toLowerCase().trim()
  if (!q) return productos.value
  return productos.value.filter(p => (p.nombre || '').toLowerCase().includes(q))
})

// Sorting & Pagination
const page = ref(1)
const pageSize = ref(10)
const sortBy = ref<'nombre'|'precio'>('nombre')
const sortDir = ref<'asc'|'desc'>('asc')

function setSort(column: typeof sortBy.value) {
  if (sortBy.value === column) {
    sortDir.value = sortDir.value === 'asc' ? 'desc' : 'asc'
  } else {
    sortBy.value = column
    sortDir.value = 'asc'
  }
}

const sortedProductos = computed(() => {
  const list = [...filteredProductos.value]
  list.sort((a,b) => {
    let va: any = ''
    let vb: any = ''
    if (sortBy.value === 'nombre') { va = (a.nombre||'').toLowerCase(); vb = (b.nombre||'').toLowerCase() }
    if (sortBy.value === 'precio') { va = a.precio_base || 0; vb = b.precio_base || 0 }
    if (va < vb) return sortDir.value === 'asc' ? -1 : 1
    if (va > vb) return sortDir.value === 'asc' ? 1 : -1
    return 0
  })
  return list
})

const totalPages = computed(() => Math.max(1, Math.ceil(sortedProductos.value.length / pageSize.value)))
const paginatedProductos = computed(() => {
  const start = (page.value - 1) * pageSize.value
  return sortedProductos.value.slice(start, start + pageSize.value)
})

function prevPage(){ if(page.value > 1) page.value-- }
function nextPage(){ if(page.value < totalPages.value) page.value++ }

const activosCount = computed(() => productos.value.filter(p => p.activo).length)
const inactivosCount = computed(() => productos.value.filter(p => !p.activo).length)

function stockClass(stock: number | null | undefined) {
  if (typeof stock !== 'number') return 'stock-neutral'
  if (stock === 0) return 'stock-zero'
  if (stock <= 2) return 'stock-low'
  if (stock > 4) return 'stock-ok'
  return 'stock-neutral'
}

// creation moved to modal

const showNewProduct = ref(false)

function openNewProduct(){ editingProduct.value = null; showNewProduct.value = true }

async function onCreatedProduct(){
  showNewProduct.value = false
  await fetchProductos()
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
  // open modal prefilled for editing
  editingProduct.value = p
  showNewProduct.value = true
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
.page-header { display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;flex-wrap:wrap;gap:8px }
.page-title { margin:0;font-size:1.25rem }
.page-sub { margin:0;color:#666 }
.header-actions { display:flex;gap:12px;align-items:center;flex-wrap:wrap }
.search input { width:100%;max-width:400px;padding:12px 12px;border:1px solid #ddd;border-radius:6px;box-sizing:border-box }
.btn-primary { background:#059669;color:white;padding:8px 12px;border-radius:6px;border:none;white-space:nowrap }
.stats-grid { display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:12px;margin:12px 0 }
.stat-card { background:#fff;border:1px solid #eee;padding:12px;border-radius:8px }
.stat-num { font-weight:700;font-size:1.1rem }
.stat-label { color:#666 }
.orders-table { margin-top:12px;border-top:1px solid #eee;overflow-x:auto;-webkit-overflow-scrolling:touch }
.orders-row { display:grid;grid-template-columns: 2fr 1fr 1fr 1fr 1fr 1fr;align-items:center;padding:12px;border-bottom:1px solid #f3f3f3;min-width:600px }
.orders-row.header { font-weight:600;color:#444;background:#fafafa }

@media (max-width: 768px) {
  .page-header { flex-direction:column;align-items:flex-start }
  .header-actions { width:100% }
  .search { width:100% }
  .search input { max-width:none;width:100% }
  .stats-grid { grid-template-columns:repeat(2,1fr);gap:8px }
}
.actions { display:flex;gap:8px;justify-content:flex-end }
.btn-delete { background:#fff;border:1px solid #eee;padding:6px 8px;border-radius:6px }
.low-stock{color:#b91c1c;font-weight:700;margin-left:8px;font-size:0.85rem}
.stock-badge{display:inline-block;padding:6px 8px;border-radius:8px;color:#fff;font-weight:700}
.stock-zero{background:#ef4444}
.stock-low{background:#f59e0b}
.stock-ok{background:#16a34a}
.stock-neutral{background:#94a3b8;color:#fff}

/* Dark mode */
:is(.dark) .products-page{background:transparent}
:is(.dark) .page-title{color:#e2e8f0}
:is(.dark) .page-sub{color:#94a3b8}
:is(.dark) .stat-card{background:#111c2e;border-color:#1e293b}
:is(.dark) .stat-num{color:#e2e8f0}
:is(.dark) .stat-label{color:#94a3b8}
:is(.dark) .search input{background:#0f1729;border-color:#334155;color:#e2e8f0}
:is(.dark) .search input::placeholder{color:#475569}
:is(.dark) .orders-table{border-top-color:#1e293b}
:is(.dark) .orders-row{border-bottom-color:#1e293b;color:#cbd5e1}
:is(.dark) .orders-row.header{background:#0f1729;color:#94a3b8}
:is(.dark) .btn-delete{background:#0f1729;border-color:#334155;color:#cbd5e1}
:is(.dark) .btn-primary{background:#059669}
:is(.dark) .pagination button{background:#0f1729;border-color:#334155;color:#cbd5e1}
:is(.dark) .pagination select{background:#0f1729;border-color:#334155;color:#cbd5e1}
:is(.dark) .pagination{color:#94a3b8}
</style>
