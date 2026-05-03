<template>
  <div class="modal-overlay">
    <div class="wizard-card">
      <header class="wizard-header">
        <div class="wizard-steps">
          <div :class="stepClasses(1)">1. Cliente</div>
          <div :class="stepClasses(2)">2. Productos</div>
          <div :class="stepClasses(3)">3. Revisión</div>
        </div>
        <button class="close" @click="close">✕</button>
      </header>

      <section class="wizard-body">
        <!-- STEP 1: Select client -->
        <div v-if="step === 1" class="step-panel">
          <div class="step-actions">
            <input v-model="clientSearch" placeholder="Buscar cliente..." class="input" />
            <div style="display:flex;gap:8px;align-items:center">
              <button class="btn-new-client" @click="showQuickClient = !showQuickClient">
                <span class="btn-new-client__icon">＋</span> Nuevo cliente
              </button>
              <button class="btn-primary" :disabled="!selectedClient" @click="nextStep">Siguiente</button>
            </div>
          </div>

          <!-- Quick-create client inline form -->
          <transition name="slide-down">
            <div v-if="showQuickClient" class="quick-client-form">
              <div class="quick-client-form__header">
                <div class="quick-client-form__title">
                  <span class="quick-client-form__icon">👤</span>
                  <span>Crear cliente rápido</span>
                </div>
                <button class="quick-client-form__close" @click="showQuickClient = false">✕</button>
              </div>
              <form @submit.prevent="handleQuickCreateClient" class="quick-client-form__body">
                <div class="quick-client-form__fields">
                  <div class="quick-client-form__field">
                    <label class="quick-client-form__label">Nombre *</label>
                    <input v-model="quickClientForm.nombre" required class="input" placeholder="Nombre del cliente" />
                  </div>
                  <div class="quick-client-form__field">
                    <label class="quick-client-form__label">Teléfono</label>
                    <input v-model="quickClientForm.telefono" class="input" placeholder="Ej: 614 123 4567" />
                  </div>
                  <div class="quick-client-form__field">
                    <label class="quick-client-form__label">Correo</label>
                    <input v-model="quickClientForm.correo" type="email" class="input" placeholder="correo@ejemplo.com" />
                  </div>
                </div>
                <div class="quick-client-form__actions">
                  <button type="submit" class="btn-primary" :disabled="quickClientSubmitting || !quickClientForm.nombre">
                    {{ quickClientSubmitting ? 'Creando...' : '✓ Crear y seleccionar' }}
                  </button>
                  <button type="button" class="btn-ghost" @click="showQuickClient = false">Cancelar</button>
                </div>
                <div v-if="quickClientError" class="quick-client-form__error">{{ quickClientError }}</div>
                <div v-if="quickClientSuccess" class="quick-client-form__success">✓ Cliente creado y seleccionado</div>
              </form>
            </div>
          </transition>

          <div class="cards-grid">
            <div
              v-for="c in paginatedClients"
              :key="c.id"
              :class="clientCardClasses(c.id)"
              @click="selectClient(c)">
              <div class="card-title">{{ c.nombre }}</div>
              <div class="card-sub">{{ c.telefono || '-' }} · {{ c.correo || '-' }}</div>
            </div>
          </div>

          <div class="pagination-row">
            <div class="pagination-info">
              Mostrando {{ ((pageClients-1)*perPageClients)+1 }} - {{ Math.min((pageClients*perPageClients), filteredClients.length) }} de {{ filteredClients.length }} clientes
            </div>
            <div class="pagination-controls">
              <button class="btn-outline" :disabled="pageClients===1" @click="prevPageClients">Anterior</button>
              <button class="btn-outline" :disabled="pageClients===totalPagesClients" @click="nextPageClients">Siguiente</button>
              <select v-model.number="perPageClients" class="input" style="width:120px;margin-left:8px">
                <option :value="6">6 / pág</option>
                <option :value="12">12 / pág</option>
                <option :value="24">24 / pág</option>
              </select>
            </div>
          </div>
        </div>

        <!-- STEP 2: Select products -->
        <div v-if="step === 2" class="step-panel">
          <div class="step-actions">
            <input v-model="productSearch" placeholder="Buscar producto..." class="input" />
            <div>
              <button class="btn-outline" @click="openProductList">Ver productos</button>
              <button class="btn-primary" :disabled="items.length === 0" @click="nextStep">Siguiente</button>
              <button class="btn-ghost" @click="prevStep">Atrás</button>
            </div>
          </div>

          <!-- Quick-add stock inline form -->
          <transition name="slide-down">
            <div v-if="showQuickStock" class="quick-stock-form">
              <div class="quick-stock-form__header">
                <div class="quick-stock-form__title">
                  <span class="quick-stock-form__icon">📦</span>
                  <span>Agregar stock — {{ quickStockProduct?.nombre }}</span>
                </div>
                <button class="quick-stock-form__close" @click="showQuickStock = false">✕</button>
              </div>
              <form @submit.prevent="handleQuickAddStock" class="quick-stock-form__body">
                <div class="quick-stock-form__fields">
                  <div class="quick-stock-form__field">
                    <label class="quick-stock-form__label">Stock actual</label>
                    <div class="quick-stock-form__value">{{ quickStockProduct?.stock ?? 0 }}</div>
                  </div>
                  <div class="quick-stock-form__field">
                    <label class="quick-stock-form__label">Cantidad a agregar *</label>
                    <input v-model.number="quickStockQty" type="number" min="1" step="1" required class="input" placeholder="Ej: 10" />
                  </div>
                  <div class="quick-stock-form__field">
                    <label class="quick-stock-form__label">Nuevo stock</label>
                    <div class="quick-stock-form__value quick-stock-form__value--highlight">{{ (quickStockProduct?.stock ?? 0) + (quickStockQty || 0) }}</div>
                  </div>
                </div>
                <div class="quick-stock-form__actions">
                  <button type="submit" class="btn-primary" :disabled="quickStockSubmitting || !quickStockQty || quickStockQty <= 0">
                    {{ quickStockSubmitting ? 'Guardando...' : '✓ Agregar stock' }}
                  </button>
                  <button type="button" class="btn-ghost" @click="showQuickStock = false">Cancelar</button>
                </div>
                <div v-if="quickStockError" class="quick-stock-form__error">{{ quickStockError }}</div>
                <div v-if="quickStockSuccess" class="quick-stock-form__success">✓ Stock actualizado correctamente</div>
              </form>
            </div>
          </transition>

          <div class="cards-grid">
            <div v-for="p in paginatedProducts" :key="p.id" class="card">
                  <div class="card-title">{{ p.nombre }}</div>
                  <div class="card-sub">{{ p.unidad || '-' }} · {{ formatCurrency(p.precio_base) }}</div>
                  <div class="card-stock-row">
                    <span :class="['stock-badge-mini', stockBadgeClass(p.stock)]">Stock: {{ typeof p.stock === 'number' ? p.stock : '—' }}</span>
                    <button v-if="typeof p.stock === 'number' && p.stock <= 2" class="btn-restock" @click="openQuickStock(p)" type="button">＋ Stock</button>
                  </div>
              <div class="card-actions">
                <input type="number" v-model.number="productQty[p.id]" min="0.01" step="0.01" class="qty" />
                <button class="btn-primary" @click="addProductToItems(p)">Agregar</button>
              </div>
            </div>
          </div>

          <div class="pagination-row">
            <div class="pagination-info">
              Mostrando {{ ((page-1)*perPage)+1 }} - {{ Math.min((page*perPage), filteredProducts.length) }} de {{ filteredProducts.length }} productos
            </div>
            <div class="pagination-controls">
              <button class="btn-outline" :disabled="page===1" @click="prevPage">Anterior</button>
              <button class="btn-outline" :disabled="page===totalPages" @click="nextPage">Siguiente</button>
              <select v-model.number="perPage" class="input" style="width:120px;margin-left:8px">
                <option :value="6">6 / pág</option>
                <option :value="12">12 / pág</option>
                <option :value="24">24 / pág</option>
              </select>
            </div>
          </div>

          <div class="items-panel" v-if="items.length">
            <h4>Items agregados</h4>
            <div v-for="(it, idx) in items" :key="idx" class="item-row">
              <div class="item-name">{{ it.nombre || it.producto_id }}</div>
              <div class="item-cant">x{{ it.cantidad }}</div>
              <div class="item-price">
                <input v-model.number="items[idx].precio_unitario" type="number" min="0" step="0.01" class="input small" />
              </div>
              <button class="btn-danger" @click="removeItem(idx)">Eliminar</button>
            </div>
          </div>
        </div>

        <!-- STEP 3: Review -->
        <div v-if="step === 3" class="step-panel">
          <h3>Revisión y pago</h3>

          <!-- Stock error banner -->
          <div v-if="stockErrors.length" class="stock-error-banner">
            <div class="stock-error-header">
              <span class="stock-error-icon">⚠️</span>
              <strong>Stock insuficiente</strong>
            </div>
            <p class="stock-error-desc">No se puede crear el pedido. Los siguientes productos no tienen stock suficiente:</p>
            <ul class="stock-error-list">
              <li v-for="(err, i) in stockErrors" :key="i">
                <strong>{{ err.nombre }}</strong> — Disponible: <span class="stock-available">{{ err.disponible }}</span>, Requerido: <span class="stock-required">{{ err.requerido }}</span>
                <button class="btn-restock-inline" @click="openQuickStockByName(err.nombre)" type="button">＋ Agregar stock</button>
              </li>
            </ul>

            <!-- Quick-add stock form inside error banner -->
            <transition name="slide-down">
              <div v-if="showQuickStockReview" class="quick-stock-form quick-stock-form--review">
                <div class="quick-stock-form__header">
                  <div class="quick-stock-form__title">
                    <span class="quick-stock-form__icon">📦</span>
                    <span>Agregar stock — {{ quickStockProduct?.nombre }}</span>
                  </div>
                  <button class="quick-stock-form__close" @click="showQuickStockReview = false">✕</button>
                </div>
                <form @submit.prevent="handleQuickAddStockReview" class="quick-stock-form__body">
                  <div class="quick-stock-form__fields">
                    <div class="quick-stock-form__field">
                      <label class="quick-stock-form__label">Stock actual</label>
                      <div class="quick-stock-form__value">{{ quickStockProduct?.stock ?? 0 }}</div>
                    </div>
                    <div class="quick-stock-form__field">
                      <label class="quick-stock-form__label">Cantidad a agregar *</label>
                      <input v-model.number="quickStockQty" type="number" min="1" step="1" required class="input" placeholder="Ej: 10" />
                    </div>
                    <div class="quick-stock-form__field">
                      <label class="quick-stock-form__label">Nuevo stock</label>
                      <div class="quick-stock-form__value quick-stock-form__value--highlight">{{ (quickStockProduct?.stock ?? 0) + (quickStockQty || 0) }}</div>
                    </div>
                  </div>
                  <div class="quick-stock-form__actions">
                    <button type="submit" class="btn-primary" :disabled="quickStockSubmitting || !quickStockQty || quickStockQty <= 0">
                      {{ quickStockSubmitting ? 'Guardando...' : '✓ Agregar stock' }}
                    </button>
                    <button type="button" class="btn-ghost" @click="showQuickStockReview = false">Cancelar</button>
                  </div>
                  <div v-if="quickStockError" class="quick-stock-form__error">{{ quickStockError }}</div>
                  <div v-if="quickStockSuccess" class="quick-stock-form__success">✓ Stock actualizado — vuelve a confirmar el pedido</div>
                </form>
              </div>
            </transition>
          </div>

          <div class="review-section">
            <div>Cliente: <strong>{{ selectedClient?.nombre }}</strong></div>
            <div class="review-items">
              <div v-for="(it, idx) in items" :key="idx" class="review-item">
                <div>{{ it.nombre || it.producto_id }}</div>
                <div>x{{ it.cantidad }}</div>
                <div>${{ (it.cantidad * it.precio_unitario).toFixed(2) }}</div>
              </div>
            </div>

            <div class="review-total">
              <div>Total:</div>
              <div class="total-amount">${{ total.toFixed(2) }}</div>
            </div>

            <div class="review-rest">
              <div>Restan:</div>
              <div class="rest-amount">${{ Math.max(0, total - (anticipo || 0)).toFixed(2) }}</div>
            </div>

            <div class="notes-card">
              <div class="notes-card__header">
                <span class="notes-card__icon">📝</span>
                <span class="notes-card__title">Indicaciones del pedido</span>
                <span class="notes-card__counter" :class="{ 'notes-card__counter--warn': notas.length > 450 }">{{ notas.length }} / 500</span>
              </div>

              <div class="quick-tags">
                <div class="quick-tags__label">Etiquetas rápidas</div>
                <div class="quick-tags__grid">
                  <button
                    v-for="tag in quickTags"
                    :key="tag.text"
                    :class="['qtag', { 'qtag--active': activeQuickTags.has(tag.text) }]"
                    @click="toggleTag(tag)"
                    type="button"
                  >
                    <span class="qtag__emoji">{{ tag.emoji }}</span>
                    <span>{{ tag.text }}</span>
                  </button>
                </div>
              </div>

              <div class="notes-textarea-wrap">
                <textarea
                  ref="notesTextarea"
                  v-model="notas"
                  class="notes-textarea"
                  maxlength="500"
                  rows="3"
                  placeholder="Ej: Imprimir en vinil adhesivo blanco, corte a 5cm, entregar antes del viernes..."
                  @input="autoResize"
                ></textarea>
              </div>
            </div>

            <div class="attachments-row">
              <label>📎 Archivos de referencia</label>
              <p class="attachments-hint">Sube fotos de referencia, logos del cliente, diseños o archivos relevantes para este pedido.</p>
              <FileUploader
                bucket="pedido-attachments"
                :folder="attachmentFolder"
                :maxFiles="10"
                :existingFiles="existingAttachments"
                @uploaded="onFileUploaded"
                @deleted="onFileDeleted"
              />
            </div>

            <div class="anticipo-row">
              <label>Anticipo</label>
              <input type="number" v-model.number="anticipo" min="0" step="0.01" class="input" />
            </div>

            <div class="anticipo-row">
              <label>Metodo de pago</label>
              <select v-model="anticipoMetodo" class="input">
                <option value="Efectivo">Efectivo</option>
                <option value="Transferencia">Transferencia</option>
                <option value="Tarjeta">Tarjeta</option>
                <option value="Otro">Otro</option>
              </select>
            </div>

            <div class="wizard-actions">
              <button class="btn-primary" @click="confirmOrder" :disabled="submitting">
                {{ submitting ? 'Guardando...' : 'Confirmar pedido' }}
              </button>
              <button class="btn-ghost" @click="prevStep">Atrás</button>
            </div>
          </div>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useClientes } from '../composables/useClientes'
import { useProductos } from '../composables/useProductos'
import { usePedidos } from '../composables/usePedidos'
import { supabase } from '../lib/supabase'
import { useFormat } from '../composables/useFormat'
import { getMaterialRules } from '../lib/costs'
import FileUploader from './FileUploader.vue'

const emit = defineEmits(['created','close'])
const props = defineProps<{ initialPedido?: any | null }>()

const step = ref(1)

const { clientes, fetchClientes, crearCliente } = useClientes()
const { productos, fetchProductos, actualizarProducto } = useProductos()
const { formatCurrency } = useFormat()
const { crearPedido, actualizarPedidoCompleto } = usePedidos()

const clientSearch = ref('')
const productSearch = ref('')

// pagination
const page = ref(1)
const perPage = ref(12)

watch(productSearch, () => { page.value = 1 })

const selectedClient = ref<any | null>(null)
const productQty = ref<Record<string, number>>({})
const items = ref<Array<any>>([])
const anticipo = ref(0)
const anticipoMetodo = ref('Efectivo')
const notas = ref('')
const submitting = ref(false)
const stockErrors = ref<Array<{ nombre: string; disponible: number; requerido: number }>>([])
const notesTextarea = ref<HTMLTextAreaElement | null>(null)

// --- Quick-create client ---
const showQuickClient = ref(false)
const quickClientSubmitting = ref(false)
const quickClientError = ref('')
const quickClientSuccess = ref(false)
const quickClientForm = ref({ nombre: '', telefono: '', correo: '' })

async function handleQuickCreateClient() {
  if (!quickClientForm.value.nombre) return
  quickClientSubmitting.value = true
  quickClientError.value = ''
  quickClientSuccess.value = false
  try {
    const newClient = await crearCliente({
      nombre: quickClientForm.value.nombre,
      telefono: quickClientForm.value.telefono || undefined,
      correo: quickClientForm.value.correo || undefined
    } as any)
    // Auto-select the newly created client
    selectedClient.value = newClient
    quickClientSuccess.value = true
    // Reset form
    quickClientForm.value = { nombre: '', telefono: '', correo: '' }
    // Refresh clients list
    await fetchClientes()
    // Hide form after a brief success flash
    setTimeout(() => {
      showQuickClient.value = false
      quickClientSuccess.value = false
    }, 1200)
  } catch (err: any) {
    quickClientError.value = err?.message || 'Error al crear el cliente'
  } finally {
    quickClientSubmitting.value = false
  }
}

// --- Quick-add stock ---
const showQuickStock = ref(false)
const showQuickStockReview = ref(false)
const quickStockProduct = ref<any | null>(null)
const quickStockQty = ref<number>(0)
const quickStockSubmitting = ref(false)
const quickStockError = ref('')
const quickStockSuccess = ref(false)

function stockBadgeClass(stock: number | null | undefined) {
  if (typeof stock !== 'number') return 'stock-badge--neutral'
  if (stock === 0) return 'stock-badge--zero'
  if (stock <= 2) return 'stock-badge--low'
  return 'stock-badge--ok'
}

function openQuickStock(product: any) {
  quickStockProduct.value = product
  quickStockQty.value = 0
  quickStockError.value = ''
  quickStockSuccess.value = false
  showQuickStock.value = true
  showQuickStockReview.value = false
}

function openQuickStockByName(nombre: string) {
  const product = productos.value.find((p: any) => (p.nombre || '').toLowerCase() === nombre.toLowerCase())
  if (!product) return
  quickStockProduct.value = product
  quickStockQty.value = 0
  quickStockError.value = ''
  quickStockSuccess.value = false
  showQuickStockReview.value = true
  showQuickStock.value = false
}

async function handleQuickAddStock() {
  if (!quickStockProduct.value || !quickStockQty.value || quickStockQty.value <= 0) return
  quickStockSubmitting.value = true
  quickStockError.value = ''
  quickStockSuccess.value = false
  try {
    const prod = quickStockProduct.value
    const newStock = (prod.stock ?? 0) + quickStockQty.value
    await actualizarProducto(prod.id, { nombre: prod.nombre, precio_base: prod.precio_base, stock: newStock })
    quickStockSuccess.value = true
    await fetchProductos()
    // Update local ref
    quickStockProduct.value = productos.value.find((p: any) => p.id === prod.id) || null
    quickStockQty.value = 0
    setTimeout(() => {
      showQuickStock.value = false
      quickStockSuccess.value = false
    }, 1200)
  } catch (err: any) {
    quickStockError.value = err?.message || 'Error al actualizar stock'
  } finally {
    quickStockSubmitting.value = false
  }
}

async function handleQuickAddStockReview() {
  if (!quickStockProduct.value || !quickStockQty.value || quickStockQty.value <= 0) return
  quickStockSubmitting.value = true
  quickStockError.value = ''
  quickStockSuccess.value = false
  try {
    const prod = quickStockProduct.value
    const newStock = (prod.stock ?? 0) + quickStockQty.value
    await actualizarProducto(prod.id, { nombre: prod.nombre, precio_base: prod.precio_base, stock: newStock })
    quickStockSuccess.value = true
    await fetchProductos()
    quickStockProduct.value = productos.value.find((p: any) => p.id === prod.id) || null
    quickStockQty.value = 0
    // Clear stock errors so user can retry
    stockErrors.value = []
    setTimeout(() => {
      showQuickStockReview.value = false
      quickStockSuccess.value = false
    }, 1500)
  } catch (err: any) {
    quickStockError.value = err?.message || 'Error al actualizar stock'
  } finally {
    quickStockSubmitting.value = false
  }
}

// --- Quick tags for notes ---
const quickTags = [
  { emoji: '🔥', text: 'Urgente' },
  { emoji: '🖨️', text: 'Doble cara' },
  { emoji: '✨', text: 'Acabado brillante' },
  { emoji: '🌫️', text: 'Acabado mate' },
  { emoji: '✂️', text: 'Corte especial' },
  { emoji: '🎨', text: 'Full color' },
  { emoji: '📐', text: 'Tamaño personalizado' },
  { emoji: '🎁', text: 'Envolver para regalo' },
  { emoji: '📞', text: 'Llamar antes de entregar' },
  { emoji: '🚚', text: 'Envío a domicilio' },
]

const activeQuickTags = ref<Set<string>>(new Set())

function toggleTag(tag: { emoji: string; text: string }) {
  const label = `${tag.emoji} ${tag.text}`
  if (activeQuickTags.value.has(tag.text)) {
    activeQuickTags.value.delete(tag.text)
    notas.value = notas.value.replace(label, '').replace(/\s{2,}/g, ' ').replace(/^[,;·\s]+|[,;·\s]+$/g, '').trim()
  } else {
    activeQuickTags.value.add(tag.text)
    const sep = notas.value.trim() ? ' · ' : ''
    notas.value = (notas.value.trim() + sep + label).slice(0, 500)
  }
}

function autoResize() {
  const el = notesTextarea.value
  if (!el) return
  el.style.height = 'auto'
  el.style.height = Math.min(el.scrollHeight, 200) + 'px'
}

// --- File attachments ---
interface StagedFile {
  url: string
  nombre_archivo: string
  tipo?: string | null
  tamanio_bytes?: number | null
}
const stagedFiles = ref<StagedFile[]>([])
const existingAttachments = ref<StagedFile[]>([])
const attachmentFolder = computed(() => {
  if (props.initialPedido?.id) return props.initialPedido.id
  return 'temp_' + Date.now()
})

function onFileUploaded(file: StagedFile) {
  stagedFiles.value.push(file)
}

function onFileDeleted(file: StagedFile) {
  stagedFiles.value = stagedFiles.value.filter(f => f.url !== file.url)
  existingAttachments.value = existingAttachments.value.filter(f => f.url !== file.url)
  // Also delete from DB if it has an id
  if ((file as any).id) {
    supabase.from('pedido_archivos').delete().eq('id', (file as any).id).then(() => {})
  }
}

onMounted(async () => {
  await fetchClientes()
  await fetchProductos()

  // if initialPedido provided, prefill fields for editing
  if (props.initialPedido) {
    const ped = props.initialPedido
    selectedClient.value = ped.clientes || { id: ped.cliente_id, nombre: ped.clientes?.nombre }
    items.value = (ped.pedido_items || []).map((it:any) => ({
      producto_id: it.producto_id,
      nombre: it.productos?.nombre || it.descripcion_personalizada || '',
      cantidad: it.cantidad,
      precio_unitario: it.precio_unitario,
      descripcion: it.descripcion_personalizada || ''
    }))
    notas.value = ped.notas || ''
    // open at review step
    step.value = 3
  }
})

const filteredClients = computed(() => {
  const q = (clientSearch.value || '').toLowerCase().trim()
  if (!q) return clientes.value
  return clientes.value.filter((c:any) => (c.nombre||'').toLowerCase().includes(q) || (c.correo||'').toLowerCase().includes(q))
})

// clients pagination
const pageClients = ref(1)
const perPageClients = ref(12)

watch(clientSearch, () => { pageClients.value = 1 })

const totalPagesClients = computed(() => Math.max(1, Math.ceil((filteredClients.value || []).length / perPageClients.value)))

const paginatedClients = computed(() => {
  const start = (pageClients.value - 1) * perPageClients.value
  return (filteredClients.value || []).slice(start, start + perPageClients.value)
})

function prevPageClients(){ if(pageClients.value > 1) pageClients.value-- }
function nextPageClients(){ if(pageClients.value < totalPagesClients.value) pageClients.value++ }

const filteredProducts = computed(() => {
  const q = (productSearch.value || '').toLowerCase().trim()
  if (!q) return productos.value
  return productos.value.filter((p:any) => (p.nombre||'').toLowerCase().includes(q))
})

const totalPages = computed(() => Math.max(1, Math.ceil((filteredProducts.value || []).length / perPage.value)))

const paginatedProducts = computed(() => {
  const start = (page.value - 1) * perPage.value
  return (filteredProducts.value || []).slice(start, start + perPage.value)
})

function prevPage(){ if(page.value > 1) page.value-- }
function nextPage(){ if(page.value < totalPages.value) page.value++ }

function selectClient(c:any){ selectedClient.value = c }

function stepClasses(currentStep: number) {
  return step.value === currentStep ? ['step', 'active'] : ['step']
}

function clientCardClasses(clientId: string) {
  return selectedClient.value?.id === clientId ? ['card', 'selected'] : ['card']
}

function nextStep(){ if(step.value < 3) step.value++ }
function prevStep(){ if(step.value > 1) step.value-- }

function openProductList(){ /* no-op: products already visible */ }

function addProductToItems(p:any){
  const qty = Number(productQty.value[p.id]) || 1
  // prevent adding inactive products
  if (p.activo === false) {
    alert('No se puede agregar un producto inactivo: ' + p.nombre)
    return
  }
  // if stock known, validate availability
  if (typeof p.stock === 'number' && p.stock < qty) {
    alert(`Stock insuficiente para ${p.nombre}. Disponible: ${p.stock}`)
    return
  }
  items.value.push({ producto_id: p.id, nombre: p.nombre, cantidad: qty, precio_unitario: p.precio_base })
}

function removeItem(i:number){ items.value.splice(i,1) }

const total = computed(() => items.value.reduce((acc, it) => acc + (it.cantidad * (it.precio_unitario||0)), 0))

/**
 * Validate stock availability before submitting the order.
 * Aggregates demand from items + auto-computed material consumos,
 * then compares against current product stock.
 * Returns an array of errors (empty = all OK).
 */
function validateStock(): Array<{ nombre: string; disponible: number; requerido: number }> {
  const demand: Record<string, { nombre: string; total: number }> = {}

  // Build a lookup map: producto_id -> product object
  const prodMap: Record<string, any> = {}
  for (const p of productos.value) {
    prodMap[p.id] = p
  }

  // 1) Accumulate demand from order items
  for (const it of items.value) {
    if (!it.producto_id) continue
    if (!demand[it.producto_id]) {
      const prod = prodMap[it.producto_id]
      demand[it.producto_id] = { nombre: prod?.nombre || it.nombre || it.producto_id, total: 0 }
    }
    demand[it.producto_id].total += Number(it.cantidad) || 0
  }

  // 2) Accumulate demand from material consumos (same logic as crearPedido in usePedidos.ts)
  for (const it of items.value) {
    if (!it.producto_id) continue
    const prod = prodMap[it.producto_id]
    const nombre = prod?.nombre || it.nombre || ''
    const rules = getMaterialRules(nombre)
    for (const rule of rules) {
      // Find the material product by pattern matching
      const material = productos.value.find(
        (p: any) => (p.nombre || '').toLowerCase().includes(rule.materialPattern.toLowerCase())
      )
      if (material) {
        const consumed = Math.ceil((Number(it.cantidad) || 0) / rule.unitsPerMaterial)
        if (!demand[material.id]) {
          demand[material.id] = { nombre: material.nombre, total: 0 }
        }
        demand[material.id].total += consumed
      }
    }
  }

  // 3) Compare demand against available stock
  const errors: Array<{ nombre: string; disponible: number; requerido: number }> = []
  for (const [prodId, info] of Object.entries(demand)) {
    const prod = prodMap[prodId]
    const available = typeof prod?.stock === 'number' ? prod.stock : null
    if (available !== null && available < info.total) {
      errors.push({
        nombre: info.nombre,
        disponible: available,
        requerido: info.total
      })
    }
  }

  return errors
}

async function confirmOrder(){
  if(!selectedClient.value){ alert('Selecciona un cliente'); step.value = 1; return }
  if(items.value.length === 0){ alert('Añade al menos un item'); step.value = 2; return }

  // --- UI-level stock validation ---
  stockErrors.value = []
  // Refresh products to get latest stock levels
  await fetchProductos()
  const errors = validateStock()
  if (errors.length > 0) {
    stockErrors.value = errors
    return
  }

  submitting.value = true
  try {
    const payloadItems = items.value.map(it=>({ producto_id: it.producto_id, cantidad: it.cantidad, precio_unitario: it.precio_unitario, descripcion_personalizada: it.descripcion || '' }))

    if (props.initialPedido && props.initialPedido.id) {
      // edit existing pedido
      await actualizarPedidoCompleto(props.initialPedido.id, { notas: notas.value, items: payloadItems })
      // if an anticipo value was provided while editing, insert it as a pago (anticipo)
      if (anticipo.value && Number(anticipo.value) > 0) {
        try {
          const { error: pagoErr } = await supabase.from('pagos').insert([{ pedido_id: props.initialPedido.id, monto: Number(anticipo.value), metodo: anticipoMetodo.value, es_anticipo: true, creado_en: new Date().toISOString() }])
          if (pagoErr) console.warn('No se pudo insertar pago (anticipo):', pagoErr)
        } catch (e) {
          console.warn('Error al insertar pago (anticipo):', e)
        }
      }
    } else {
      const created = await crearPedido({
        cliente_id: selectedClient.value.id,
        notas: notas.value,
        items: payloadItems,
        anticipo: anticipo.value > 0 ? anticipo.value : undefined,
        anticipo_metodo: anticipo.value > 0 ? anticipoMetodo.value : undefined
      })
      // El stock ya fue descontado atómicamente por el RPC create_pedido_with_stock.
      // Refrescamos la lista local de productos para reflejar los nuevos niveles de stock.
      await fetchProductos()

      // Save file attachment records to pedido_archivos
      const pedidoId = created?.id
      if (pedidoId && stagedFiles.value.length > 0) {
        const archivos = stagedFiles.value.map(f => ({
          pedido_id: pedidoId,
          url: f.url,
          nombre_archivo: f.nombre_archivo,
          tipo: f.tipo || null,
          tamanio_bytes: f.tamanio_bytes || null
        }))
        await supabase.from('pedido_archivos').insert(archivos)
      }
    }

    emit('created')
    close()
  } catch (err: any) {
    // If the DB still rejects (race condition), show a friendly message
    const msg = err?.message || String(err)
    if (msg.toLowerCase().includes('stock')) {
      stockErrors.value = [{ nombre: 'Error del servidor', disponible: 0, requerido: 0 }]
    } else {
      alert('Error al crear pedido: ' + msg)
    }
  } finally {
    submitting.value = false
  }
}

function close(){ emit('close') }
</script>

<style scoped>
.modal-overlay{position:fixed;inset:0;background:rgba(2,6,23,0.45);display:flex;align-items:center;justify-content:center;padding:24px;z-index:70}
.wizard-card{width:1000px;max-width:96vw;background:#fff;border-radius:12px;overflow:auto;box-shadow:0 16px 48px rgba(2,6,23,0.2);max-height:92vh;box-sizing:border-box}
.wizard-header{display:flex;justify-content:space-between;align-items:center;padding:16px 20px;border-bottom:1px solid #eef2f5;flex-wrap:wrap;gap:8px}
.wizard-steps{display:flex;gap:8px;flex-wrap:wrap}
.step{padding:6px 10px;border-radius:8px;background:#f8fafc;color:#475569}
.step.active{background:#0ea5a4;color:#fff}
.wizard-body{padding:16px}
.step-actions{display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;gap:12px}
.input{padding:8px 10px;border:1px solid #e6eef2;border-radius:8px}
.textarea{min-height:84px;padding:10px;border:1px solid #e6eef2;border-radius:8px;resize:vertical}

/* Notes card */
.notes-card{border:1px solid #e2e8f0;border-radius:12px;padding:16px;background:linear-gradient(135deg,#f8fafc 0%,#f0fdfa 100%);transition:border-color 0.2s}
.notes-card:focus-within{border-color:#0ea5a4;box-shadow:0 0 0 3px rgba(14,165,164,0.08)}
.notes-card__header{display:flex;align-items:center;gap:8px;margin-bottom:12px}
.notes-card__icon{font-size:1.15rem}
.notes-card__title{font-weight:700;font-size:0.95rem;color:#1e293b;flex:1}
.notes-card__counter{font-size:0.78rem;color:#94a3b8;font-weight:500;font-variant-numeric:tabular-nums}
.notes-card__counter--warn{color:#f59e0b;font-weight:600}

.quick-tags{margin-bottom:12px}
.quick-tags__label{font-size:0.78rem;color:#94a3b8;font-weight:600;text-transform:uppercase;letter-spacing:0.5px;margin-bottom:6px}
.quick-tags__grid{display:flex;flex-wrap:wrap;gap:6px}
.qtag{display:inline-flex;align-items:center;gap:4px;padding:5px 10px;border-radius:20px;border:1px solid #e2e8f0;background:#fff;color:#475569;font-size:0.82rem;font-weight:500;cursor:pointer;transition:all 0.18s ease;user-select:none}
.qtag:hover{border-color:#0ea5a4;background:#f0fdfa;transform:translateY(-1px)}
.qtag--active{background:linear-gradient(135deg,#0ea5a4,#0d9488);color:#fff;border-color:transparent;box-shadow:0 2px 8px rgba(14,165,164,0.25)}
.qtag--active:hover{filter:brightness(1.08)}
.qtag__emoji{font-size:0.9rem;line-height:1}

.notes-textarea-wrap{position:relative}
.notes-textarea{width:100%;min-height:64px;max-height:200px;padding:10px 12px;border:1px solid #e2e8f0;border-radius:8px;resize:none;font-family:inherit;font-size:0.9rem;line-height:1.5;color:#1e293b;background:#fff;transition:border-color 0.2s;box-sizing:border-box;overflow-y:auto}
.notes-textarea::placeholder{color:#94a3b8}
.notes-textarea:focus{outline:none;border-color:#0ea5a4}
.cards-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:12px}
.card{padding:12px;border-radius:8px;border:1px solid #f1f5f9;background:#fff;cursor:pointer}
.card.selected{border-color:#0ea5a4;box-shadow:0 6px 18px rgba(14,165,164,0.08)}
.card-title{font-weight:700}
.card-sub{font-size:0.9rem;color:#64748b}
.card-actions{display:flex;gap:8px;align-items:center;margin-top:8px}
.qty{width:64px;padding:6px;border:1px solid #e6eef2;border-radius:6px}
.items-panel{margin-top:12px}
.item-row{display:flex;gap:12px;align-items:center;padding:8px 0;border-bottom:1px dashed #f3f7fa}
.item-name{flex:1}
.item-cant{width:60px;text-align:center}
.item-price{width:120px;text-align:right}
.btn-primary{background:#059669;color:#fff;padding:8px 12px;border-radius:8px;border:none}
.btn-primary:disabled{opacity:0.6;cursor:not-allowed}
.btn-outline{background:#fff;border:1px solid #e6eef2;padding:8px 10px;border-radius:8px}
.btn-ghost{background:transparent;border:1px solid #e6eef2;padding:8px 10px;border-radius:8px}
.btn-danger{background:#fff;border:1px solid #ffdddd;color:#ef4444;padding:6px 8px;border-radius:8px}
.review-section{display:flex;flex-direction:column;gap:12px}
.review-items{border:1px solid #f1f5f9;padding:12px;border-radius:8px}
.review-item{display:flex;justify-content:space-between;padding:6px 0}
.review-total{display:flex;justify-content:space-between;font-weight:700}
.review-rest{display:flex;justify-content:space-between;font-weight:700;margin-top:6px}
.rest-amount{color:#0b6f4b;font-weight:800}
.anticipo-row{display:flex;gap:12px;align-items:center}
.attachments-row{display:flex;flex-direction:column;gap:6px}
.attachments-row label{font-weight:600;color:#334155;font-size:0.95rem}
.attachments-hint{margin:0;color:#64748b;font-size:0.85rem}
.wizard-actions{display:flex;gap:8px;justify-content:flex-end}
.pagination-row{display:flex;justify-content:space-between;align-items:center;margin-top:12px}
.pagination-info{color:#475569;font-size:0.95rem}
.pagination-controls{display:flex;align-items:center;gap:8px}

/* Stock error banner */
.stock-error-banner{background:linear-gradient(135deg,#fef2f2,#fff1f2);border:1px solid #fca5a5;border-left:4px solid #ef4444;border-radius:10px;padding:16px 20px;margin-bottom:16px;animation:shake 0.4s ease-in-out}
.stock-error-header{display:flex;align-items:center;gap:8px;font-size:1.05rem;color:#b91c1c;margin-bottom:6px}
.stock-error-icon{font-size:1.3rem}
.stock-error-desc{margin:0 0 10px;color:#7f1d1d;font-size:0.92rem}
.stock-error-list{margin:0;padding-left:20px;list-style:none}
.stock-error-list li{position:relative;padding:6px 0;color:#991b1b;font-size:0.93rem;border-bottom:1px dashed #fecaca}
.stock-error-list li:last-child{border-bottom:none}
.stock-error-list li::before{content:'✕';position:absolute;left:-18px;color:#ef4444;font-weight:700}
.stock-available{color:#16a34a;font-weight:700}
.stock-required{color:#dc2626;font-weight:700}

@keyframes shake{0%,100%{transform:translateX(0)}20%{transform:translateX(-6px)}40%{transform:translateX(6px)}60%{transform:translateX(-4px)}80%{transform:translateX(4px)}}

@media (max-width: 768px) {
  .wizard-card{max-width:100vw;border-radius:0}
  .modal-overlay{padding:0}
  .wizard-header{padding:12px 14px}
  .wizard-body{padding:12px}
  .step{padding:4px 8px;font-size:0.85rem}
  .cards-grid{grid-template-columns:repeat(2,1fr);gap:8px}
  .item-row{flex-wrap:wrap;gap:6px}
  .item-cant{width:50px}
  .item-price{width:auto;min-width:80px}
  .anticipo-row{flex-wrap:wrap}
  .wizard-actions{flex-wrap:wrap}
  .step-actions{flex-wrap:wrap}
  .quick-client-form__fields{grid-template-columns:1fr}
  .quick-client-form{padding:12px 14px}
  .btn-new-client{font-size:0.82rem;padding:6px 10px}
}

/* New client button */
.btn-new-client{display:inline-flex;align-items:center;gap:6px;padding:8px 14px;border-radius:8px;border:1px dashed #0ea5a4;background:linear-gradient(135deg,#f0fdfa,#ecfdf5);color:#0d9488;font-weight:600;font-size:0.9rem;cursor:pointer;transition:all 0.2s ease}
.btn-new-client:hover{background:linear-gradient(135deg,#ccfbf1,#d1fae5);border-style:solid;transform:translateY(-1px);box-shadow:0 4px 12px rgba(14,165,164,0.15)}
.btn-new-client__icon{font-size:1.1rem;font-weight:700}

/* Quick-create client inline form */
.quick-client-form{border:1px solid #0ea5a4;border-radius:12px;padding:16px 20px;margin-bottom:16px;background:linear-gradient(135deg,#f0fdfa 0%,#ecfdf5 100%);box-shadow:0 4px 16px rgba(14,165,164,0.1);overflow:hidden}
.quick-client-form__header{display:flex;justify-content:space-between;align-items:center;margin-bottom:12px}
.quick-client-form__title{display:flex;align-items:center;gap:8px;font-weight:700;font-size:0.95rem;color:#0d6d6e}
.quick-client-form__icon{font-size:1.2rem}
.quick-client-form__close{background:none;border:none;font-size:1rem;color:#64748b;cursor:pointer;padding:4px 8px;border-radius:6px;transition:background 0.15s}
.quick-client-form__close:hover{background:rgba(0,0,0,0.05)}
.quick-client-form__body{display:flex;flex-direction:column;gap:12px}
.quick-client-form__fields{display:grid;grid-template-columns:repeat(3,1fr);gap:12px}
.quick-client-form__field{display:flex;flex-direction:column;gap:4px}
.quick-client-form__label{font-weight:600;font-size:0.82rem;color:#334155;text-transform:uppercase;letter-spacing:0.3px}
.quick-client-form__actions{display:flex;gap:8px;justify-content:flex-end}
.quick-client-form__error{background:#fef2f2;border:1px solid #fca5a5;color:#b91c1c;padding:8px 12px;border-radius:8px;font-size:0.88rem;margin-top:4px}
.quick-client-form__success{background:#f0fdf4;border:1px solid #86efac;color:#166534;padding:8px 12px;border-radius:8px;font-size:0.88rem;margin-top:4px;display:flex;align-items:center;gap:6px;animation:fadeIn 0.3s ease}

/* Slide-down transition */
.slide-down-enter-active{transition:all 0.3s ease;max-height:300px}
.slide-down-leave-active{transition:all 0.25s ease;max-height:300px}
.slide-down-enter-from{opacity:0;max-height:0;margin-bottom:0;padding-top:0;padding-bottom:0;transform:translateY(-10px)}
.slide-down-leave-to{opacity:0;max-height:0;margin-bottom:0;padding-top:0;padding-bottom:0;transform:translateY(-10px)}

@keyframes fadeIn{from{opacity:0;transform:translateY(-4px)}to{opacity:1;transform:translateY(0)}}

/* Dark mode */
:is(.dark) .modal-overlay{background:rgba(0,0,0,0.6)}
:is(.dark) .wizard-card{background:#111c2e;box-shadow:0 16px 48px rgba(0,0,0,0.4)}
:is(.dark) .wizard-header{border-bottom-color:#1e293b}
:is(.dark) .step{background:#0f1729;color:#94a3b8}
:is(.dark) .step.active{background:#0ea5a4;color:#fff}
:is(.dark) .close{color:#94a3b8}
:is(.dark) .wizard-body{color:#cbd5e1}
:is(.dark) .input{background:#0f1729;border-color:#334155;color:#e2e8f0}
:is(.dark) .textarea{background:#0f1729;border-color:#334155;color:#e2e8f0}
:is(.dark) .cards-grid .card{background:#0f1729;border-color:#1e293b}
:is(.dark) .cards-grid .card:hover{border-color:#334155}
:is(.dark) .cards-grid .card.selected{border-color:#0ea5a4}
:is(.dark) .card-title{color:#e2e8f0}
:is(.dark) .card-sub{color:#94a3b8}
:is(.dark) .qty{background:#0f1729;border-color:#334155;color:#e2e8f0}
:is(.dark) .items-panel{color:#cbd5e1}
:is(.dark) .items-panel h4{color:#e2e8f0}
:is(.dark) .item-row{border-bottom-color:#1e293b}
:is(.dark) .item-name{color:#e2e8f0}
:is(.dark) .item-cant{color:#94a3b8}
:is(.dark) .btn-outline{background:#0f1729;border-color:#334155;color:#cbd5e1}
:is(.dark) .btn-ghost{background:transparent;border-color:#334155;color:#cbd5e1}
:is(.dark) .btn-danger{background:#0f1729;border-color:#7f1d1d;color:#fca5a5}
:is(.dark) .review-section{color:#cbd5e1}
:is(.dark) .review-items{border-color:#1e293b}
:is(.dark) .review-total{color:#e2e8f0}
:is(.dark) .review-rest .rest-amount{color:#6ee7b7}
:is(.dark) .total-amount{color:#e2e8f0}
:is(.dark) .pagination-row{color:#94a3b8}
:is(.dark) .pagination-info{color:#94a3b8}

:is(.dark) .anticipo-row label{color:#94a3b8}
:is(.dark) .attachments-row label{color:#94a3b8}
:is(.dark) .attachments-hint{color:#64748b}
:is(.dark) .notes-card{background:linear-gradient(135deg,#0f1729 0%,#0c2524 100%);border-color:#1e293b}
:is(.dark) .notes-card:focus-within{border-color:#0ea5a4;box-shadow:0 0 0 3px rgba(14,165,164,0.12)}
:is(.dark) .notes-card__title{color:#e2e8f0}
:is(.dark) .notes-card__counter{color:#64748b}
:is(.dark) .notes-card__counter--warn{color:#f59e0b}
:is(.dark) .quick-tags__label{color:#64748b}
:is(.dark) .qtag{background:#0f1729;border-color:#334155;color:#94a3b8}
:is(.dark) .qtag:hover{border-color:#0ea5a4;background:#0c2e2d}
:is(.dark) .qtag--active{background:linear-gradient(135deg,#0ea5a4,#0d9488);color:#fff;border-color:transparent}
:is(.dark) .notes-textarea{background:#0f1729;border-color:#334155;color:#e2e8f0}
:is(.dark) .notes-textarea::placeholder{color:#475569}
:is(.dark) .notes-textarea:focus{border-color:#0ea5a4}
:is(.dark) .stock-error-banner{background:linear-gradient(135deg,#1a0505,#200808);border-color:#7f1d1d;border-left-color:#ef4444}
:is(.dark) .stock-error-header{color:#fca5a5}
:is(.dark) .stock-error-desc{color:#fecaca}
:is(.dark) .stock-error-list li{color:#fecaca;border-bottom-color:#7f1d1d}

/* Dark mode: new client button */
:is(.dark) .btn-new-client{background:linear-gradient(135deg,#0c2e2d,#0f2e1e);border-color:#0ea5a4;color:#5eead4}
:is(.dark) .btn-new-client:hover{background:linear-gradient(135deg,#134e4a,#14532d);box-shadow:0 4px 12px rgba(14,165,164,0.2)}

/* Dark mode: quick-create client form */
:is(.dark) .quick-client-form{background:linear-gradient(135deg,#0f1729 0%,#0c2524 100%);border-color:#0ea5a4;box-shadow:0 4px 16px rgba(14,165,164,0.15)}
:is(.dark) .quick-client-form__title{color:#5eead4}
:is(.dark) .quick-client-form__close{color:#94a3b8}
:is(.dark) .quick-client-form__close:hover{background:rgba(255,255,255,0.05)}
:is(.dark) .quick-client-form__label{color:#94a3b8}
:is(.dark) .quick-client-form__error{background:#1a0505;border-color:#7f1d1d;color:#fca5a5}
:is(.dark) .quick-client-form__success{background:#052e16;border-color:#166534;color:#86efac}

/* Card stock row */
.card-stock-row{display:flex;align-items:center;gap:6px;margin-top:4px}
.stock-badge-mini{display:inline-flex;align-items:center;padding:2px 8px;border-radius:12px;font-size:0.78rem;font-weight:600;letter-spacing:0.2px}
.stock-badge--ok{background:#dcfce7;color:#166534}
.stock-badge--low{background:#fef3c7;color:#92400e}
.stock-badge--zero{background:#fee2e2;color:#991b1b}
.stock-badge--neutral{background:#f1f5f9;color:#64748b}

/* Restock button (card) */
.btn-restock{display:inline-flex;align-items:center;gap:3px;padding:2px 8px;border-radius:8px;border:1px dashed #f59e0b;background:linear-gradient(135deg,#fffbeb,#fef3c7);color:#92400e;font-weight:600;font-size:0.75rem;cursor:pointer;transition:all 0.2s ease;white-space:nowrap}
.btn-restock:hover{border-style:solid;background:linear-gradient(135deg,#fef3c7,#fde68a);transform:translateY(-1px);box-shadow:0 2px 8px rgba(245,158,11,0.15)}

/* Restock button (inline in error list) */
.btn-restock-inline{display:inline-flex;align-items:center;gap:3px;padding:3px 10px;margin-left:8px;border-radius:8px;border:1px solid #f59e0b;background:linear-gradient(135deg,#fffbeb,#fef3c7);color:#92400e;font-weight:600;font-size:0.82rem;cursor:pointer;transition:all 0.2s ease;vertical-align:middle}
.btn-restock-inline:hover{background:linear-gradient(135deg,#fef3c7,#fde68a);transform:translateY(-1px);box-shadow:0 2px 8px rgba(245,158,11,0.2)}

/* Quick-add stock form */
.quick-stock-form{border:1px solid #f59e0b;border-radius:12px;padding:16px 20px;margin-bottom:16px;background:linear-gradient(135deg,#fffbeb 0%,#fef3c7 100%);box-shadow:0 4px 16px rgba(245,158,11,0.1);overflow:hidden}
.quick-stock-form--review{margin-top:14px}
.quick-stock-form__header{display:flex;justify-content:space-between;align-items:center;margin-bottom:12px}
.quick-stock-form__title{display:flex;align-items:center;gap:8px;font-weight:700;font-size:0.95rem;color:#92400e}
.quick-stock-form__icon{font-size:1.2rem}
.quick-stock-form__close{background:none;border:none;font-size:1rem;color:#64748b;cursor:pointer;padding:4px 8px;border-radius:6px;transition:background 0.15s}
.quick-stock-form__close:hover{background:rgba(0,0,0,0.05)}
.quick-stock-form__body{display:flex;flex-direction:column;gap:12px}
.quick-stock-form__fields{display:grid;grid-template-columns:repeat(3,1fr);gap:12px}
.quick-stock-form__field{display:flex;flex-direction:column;gap:4px}
.quick-stock-form__label{font-weight:600;font-size:0.82rem;color:#78350f;text-transform:uppercase;letter-spacing:0.3px}
.quick-stock-form__value{font-size:1.1rem;font-weight:700;color:#92400e;padding:8px 10px;background:rgba(255,255,255,0.6);border-radius:8px}
.quick-stock-form__value--highlight{color:#059669;background:rgba(5,150,105,0.08)}
.quick-stock-form__actions{display:flex;gap:8px;justify-content:flex-end}
.quick-stock-form__error{background:#fef2f2;border:1px solid #fca5a5;color:#b91c1c;padding:8px 12px;border-radius:8px;font-size:0.88rem;margin-top:4px}
.quick-stock-form__success{background:#f0fdf4;border:1px solid #86efac;color:#166534;padding:8px 12px;border-radius:8px;font-size:0.88rem;margin-top:4px;display:flex;align-items:center;gap:6px;animation:fadeIn 0.3s ease}

@media (max-width: 768px) {
  .quick-stock-form__fields{grid-template-columns:1fr}
  .quick-stock-form{padding:12px 14px}
  .btn-restock-inline{display:flex;margin-left:0;margin-top:6px}
}

/* Dark mode: stock badges */
:is(.dark) .stock-badge--ok{background:#052e16;color:#86efac}
:is(.dark) .stock-badge--low{background:#451a03;color:#fbbf24}
:is(.dark) .stock-badge--zero{background:#450a0a;color:#fca5a5}
:is(.dark) .stock-badge--neutral{background:#1e293b;color:#94a3b8}

/* Dark mode: restock buttons */
:is(.dark) .btn-restock{background:linear-gradient(135deg,#451a03,#78350f);border-color:#f59e0b;color:#fde68a}
:is(.dark) .btn-restock:hover{background:linear-gradient(135deg,#78350f,#92400e);box-shadow:0 2px 8px rgba(245,158,11,0.2)}
:is(.dark) .btn-restock-inline{background:linear-gradient(135deg,#451a03,#78350f);border-color:#f59e0b;color:#fde68a}
:is(.dark) .btn-restock-inline:hover{background:linear-gradient(135deg,#78350f,#92400e)}

/* Dark mode: quick-add stock form */
:is(.dark) .quick-stock-form{background:linear-gradient(135deg,#0f1729 0%,#1c1206 100%);border-color:#f59e0b;box-shadow:0 4px 16px rgba(245,158,11,0.1)}
:is(.dark) .quick-stock-form__title{color:#fde68a}
:is(.dark) .quick-stock-form__close{color:#94a3b8}
:is(.dark) .quick-stock-form__close:hover{background:rgba(255,255,255,0.05)}
:is(.dark) .quick-stock-form__label{color:#fbbf24}
:is(.dark) .quick-stock-form__value{color:#fde68a;background:rgba(255,255,255,0.05)}
:is(.dark) .quick-stock-form__value--highlight{color:#6ee7b7;background:rgba(110,231,183,0.08)}
:is(.dark) .quick-stock-form__error{background:#1a0505;border-color:#7f1d1d;color:#fca5a5}
:is(.dark) .quick-stock-form__success{background:#052e16;border-color:#166534;color:#86efac}
</style>
