<template>
  <div class="modal-overlay" @click.self="close">
    <div class="wizard-card">
      <header class="wizard-header">
        <div class="wizard-steps">
          <div :class="['step', { active: step === 1 }]">1. Cliente</div>
          <div :class="['step', { active: step === 2 }]">2. Productos</div>
          <div :class="['step', { active: step === 3 }]">3. Revisión</div>
        </div>
        <button class="close" @click="close">✕</button>
      </header>

      <section class="wizard-body">
        <!-- STEP 1: Select client -->
        <div v-if="step === 1" class="step-panel">
          <div class="step-actions">
            <input v-model="clientSearch" placeholder="Buscar cliente..." class="input" />
            <div>
              <button class="btn-outline" @click="openNewClient">Registrar nuevo</button>
              <button class="btn-primary" :disabled="!selectedClient" @click="nextStep">Siguiente</button>
            </div>
          </div>

          <div class="cards-grid">
            <div
              v-for="c in filteredClients"
              :key="c.id"
              class="card"
              :class="{ selected: selectedClient?.id === c.id }"
              @click="selectClient(c)">
              <div class="card-title">{{ c.nombre }}</div>
              <div class="card-sub">{{ c.telefono || '-' }} · {{ c.correo || '-' }}</div>
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

          <div class="cards-grid">
            <div v-for="p in filteredProducts" :key="p.id" class="card">
              <div class="card-title">{{ p.nombre }}</div>
              <div class="card-sub">{{ p.unidad || '-' }} · ${{ p.precio_base }}</div>
              <div class="card-actions">
                <input type="number" v-model.number="productQty[p.id]" min="1" class="qty" />
                <button class="btn-primary" @click="addProductToItems(p)">Agregar</button>
              </div>
            </div>
          </div>

          <div class="items-panel" v-if="items.length">
            <h4>Items agregados</h4>
            <div v-for="(it, idx) in items" :key="idx" class="item-row">
              <div class="item-name">{{ it.nombre || it.producto_id }}</div>
              <div class="item-cant">x{{ it.cantidad }}</div>
              <div class="item-price">${{ it.precio_unitario.toFixed(2) }}</div>
              <button class="btn-danger" @click="removeItem(idx)">Eliminar</button>
            </div>
          </div>
        </div>

        <!-- STEP 3: Review -->
        <div v-if="step === 3" class="step-panel">
          <h3>Revisión y pago</h3>
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

            <div class="notes-row">
              <label>Notas adicionales</label>
              <textarea v-model="notas" class="textarea" placeholder="Descripción detallada del pedido, indicaciones de impresión, acabados..."></textarea>
            </div>

            <div class="anticipo-row">
              <label>Anticipo</label>
              <input type="number" v-model.number="anticipo" min="0" step="0.01" class="input" />
            </div>

            <div class="wizard-actions">
              <button class="btn-primary" @click="confirmOrder">Confirmar pedido</button>
              <button class="btn-ghost" @click="prevStep">Atrás</button>
            </div>
          </div>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useClientes } from '../composables/useClientes'
import { useProductos } from '../composables/useProductos'
import { usePedidos } from '../composables/usePedidos'
import NewClientForm from './NewClientForm.vue'

const emit = defineEmits(['created','close'])
const props = defineProps<{ initialPedido?: any | null }>()

const step = ref(1)

const { clientes, fetchClientes } = useClientes()
const { productos, fetchProductos, actualizarProducto } = useProductos()
const { crearPedido, actualizarPedidoCompleto } = usePedidos()

const clientSearch = ref('')
const productSearch = ref('')

const selectedClient = ref<any | null>(null)
const productQty = ref<Record<string, number>>({})
const items = ref<Array<any>>([])
const anticipo = ref(0)
const notas = ref('')

const showNewClient = ref(false)

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

const filteredProducts = computed(() => {
  const q = (productSearch.value || '').toLowerCase().trim()
  if (!q) return productos.value
  return productos.value.filter((p:any) => (p.nombre||'').toLowerCase().includes(q))
})

function selectClient(c:any){ selectedClient.value = c }

function nextStep(){ if(step.value < 3) step.value++ }
function prevStep(){ if(step.value > 1) step.value-- }

function openNewClient(){ showNewClient.value = true }
async function onCreatedClient(){ showNewClient.value = false; await fetchClientes(); }

function openProductList(){ /* no-op: products already visible */ }

function addProductToItems(p:any){
  const qty = productQty.value[p.id] || 1
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

async function confirmOrder(){
  if(!selectedClient.value){ alert('Selecciona un cliente'); step.value = 1; return }
  if(items.value.length === 0){ alert('Añade al menos un item'); step.value = 2; return }

  const payloadItems = items.value.map(it=>({ producto_id: it.producto_id, cantidad: it.cantidad, precio_unitario: it.precio_unitario, descripcion_personalizada: it.descripcion || '' }))

  if (props.initialPedido && props.initialPedido.id) {
    // edit existing pedido
    await actualizarPedidoCompleto(props.initialPedido.id, { notas: notas.value, items: payloadItems })
  } else {
    const pedido = await crearPedido({ cliente_id: selectedClient.value.id, notas: notas.value, items: payloadItems, anticipo: anticipo.value > 0 ? anticipo.value : undefined })
    // attempt to decrement stock for products that report stock
    try {
      // aggregate quantities per product
      const qtyByProduct = payloadItems.reduce((acc: Record<string, number>, it: any) => {
        acc[it.producto_id] = (acc[it.producto_id] || 0) + it.cantidad
        return acc
      }, {})

      for (const prodId of Object.keys(qtyByProduct)) {
        const prod = (productos.value as any[]).find(p => p.id === prodId)
        if (!prod || typeof prod.stock !== 'number') continue
        const newStock = Math.max(0, (prod.stock || 0) - qtyByProduct[prodId])
        try {
          await actualizarProducto(prodId, { stock: newStock })
        } catch (e) {
          // ignore update errors (DB may not have `stock` column)
          console.warn('No se pudo actualizar stock para', prodId, e)
        }
      }
    } catch (e) {
      console.warn('Error al procesar stock', e)
    }
  }

  emit('created')
  close()
}

function close(){ emit('close') }
</script>

<style scoped>
.modal-overlay{position:fixed;inset:0;background:rgba(2,6,23,0.45);display:flex;align-items:center;justify-content:center;padding:24px;z-index:70}
.wizard-card{width:1000px;max-width:96vw;background:#fff;border-radius:12px;overflow:auto;box-shadow:0 16px 48px rgba(2,6,23,0.2)}
.wizard-header{display:flex;justify-content:space-between;align-items:center;padding:16px 20px;border-bottom:1px solid #eef2f5}
.wizard-steps{display:flex;gap:12px}
.step{padding:6px 10px;border-radius:8px;background:#f8fafc;color:#475569}
.step.active{background:#0ea5a4;color:#fff}
.wizard-body{padding:16px}
.step-actions{display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;gap:12px}
.input{padding:8px 10px;border:1px solid #e6eef2;border-radius:8px}
.textarea{min-height:84px;padding:10px;border:1px solid #e6eef2;border-radius:8px;resize:vertical}
.cards-grid{display:grid;grid-template-columns:repeat(4,1fr);gap:12px}
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
.wizard-actions{display:flex;gap:8px;justify-content:flex-end}
</style>
