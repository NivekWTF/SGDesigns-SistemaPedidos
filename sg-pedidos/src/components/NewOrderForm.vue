<template>
  <div class="modal-overlay" @click.self="close">
    <div class="modal-card">
      <header class="modal-header--accent">
        <div class="modal-title">
          <div class="logo-pill">✂️</div>
          <div>
            <h3>Nuevo pedido</h3>
            <div class="subtitle">Crea un pedido rápido</div>
          </div>
        </div>
        <button class="close" @click="close">✕</button>
      </header>

      <form @submit.prevent="handleCrearPedido" class="form-grid">
        <div class="col-2">
          <label class="label">Cliente</label>
          <select v-model="clienteId" required class="input">
            <option value="">-- Selecciona un cliente --</option>
            <option v-for="c in clientes" :key="c.id" :value="c.id">{{ c.nombre }}</option>
          </select>

          <label class="label">Anticipo (opcional)</label>
          <input v-model.number="anticipo" type="number" min="0" step="0.01" placeholder="0.00" class="input" />

          <label class="label">Notas</label>
          <textarea v-model="notas" class="input textarea" placeholder="Instrucciones o detalles adicionales" />
        </div>

        <div class="col-2">
          <div class="items-header">
            <h4>Items</h4>
            <button type="button" class="btn-outline" @click="addItem">+ Añadir ítem</button>
          </div>

          <div class="items-list">
            <div v-for="(it, idx) in items" :key="idx" class="item-row-card">
              <select v-model="items[idx].producto_id" @change="onProductChange(idx)" class="input small">
                <option :value="null">-- Producto --</option>
                <option v-for="prod in productos" :key="prod.id" :value="prod.id">{{ prod.nombre }}</option>
              </select>

              <input v-model.number="items[idx].cantidad" type="number" min="1" class="input tiny" />
              <input v-model.number="items[idx].precio_unitario" type="number" min="0" step="0.01" class="input small" />
              <input v-model="items[idx].descripcion_personalizada" placeholder="Descripción" class="input" />

              <button type="button" class="btn-danger" @click="removeItem(idx)">Eliminar</button>
            </div>
          </div>

          <div class="summary">
            <div>Total:</div>
            <div class="total-amount">${{ items.reduce((acc, it) => acc + (it.cantidad * it.precio_unitario), 0).toFixed(2) }}</div>
          </div>
        </div>

        <div class="form-actions full-width">
          <button type="submit" class="btn-primary">Crear pedido</button>
          <button type="button" class="btn-ghost" @click="close">Cancelar</button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { usePedidos } from '../composables/usePedidos'
import { useProductos } from '../composables/useProductos'
import { useClientes } from '../composables/useClientes'
import type { PedidoItemInput } from '../types'

const emit = defineEmits(['created', 'close'])

const { crearPedido } = usePedidos()
const { productos, fetchProductos } = useProductos()
const { clientes, fetchClientes } = useClientes()

const clienteId = ref('')
const notas = ref('')
const anticipo = ref(0)
const items = ref<PedidoItemInput[]>([
  { producto_id: null, descripcion_personalizada: '', cantidad: 1, precio_unitario: 0 }
])

onMounted(async () => {
  await fetchProductos()
  await fetchClientes()
})

function addItem() {
  items.value.push({ producto_id: null, descripcion_personalizada: '', cantidad: 1, precio_unitario: 0 })
}

function removeItem(i:number){
  if(items.value.length === 1) return
  items.value.splice(i,1)
}

function onProductChange(idx:number){
  const item = items.value[idx]
  if(!item) return
  const prod = (productos.value as any[]).find(p=>p.id === item.producto_id)
  if(prod) item.precio_unitario = prod.precio_base
}

async function handleCrearPedido(){
  if(!clienteId.value){ alert('Seleccione un cliente'); return }

  const payloadItems = items.value.map(it=>({
    producto_id: it.producto_id,
    cantidad: it.cantidad,
    precio_unitario: it.precio_unitario,
    descripcion_personalizada: it.descripcion_personalizada
  }))

  await crearPedido({
    cliente_id: clienteId.value,
    notas: notas.value,
    items: payloadItems,
    anticipo: anticipo.value > 0 ? anticipo.value : undefined
  })

  emit('created')
  clienteId.value = ''
  notas.value = ''
  anticipo.value = 0
  items.value = [{ producto_id: null, descripcion_personalizada:'', cantidad:1, precio_unitario:0 }]
}

function close(){ emit('close') }
</script>

<style scoped>
.modal-overlay{position:fixed;inset:0;background:rgba(2,6,23,0.45);display:flex;align-items:center;justify-content:center;padding:24px;z-index:60}
.modal-card{background:linear-gradient(180deg,#ffffff,#fbfdff);border-radius:12px;padding:20px;width:900px;max-height:86vh;overflow:auto;box-shadow:0 12px 40px rgba(2,6,23,0.2)}
.modal-header--accent{display:flex;justify-content:space-between;align-items:center;padding-bottom:12px;border-bottom:1px solid #eef2f5}
.modal-title{display:flex;gap:12px;align-items:center}
.logo-pill{width:48px;height:48px;border-radius:10px;background:#0ea5a4;color:white;display:flex;align-items:center;justify-content:center;font-weight:700}
.modal-header--accent h3{margin:0;font-size:1.1rem}
.modal-header--accent .subtitle{font-size:0.85rem;color:#475569}
.close{background:none;border:none;font-size:1.1rem}

.form-grid{display:grid;grid-template-columns:1fr 1fr;gap:16px;padding-top:12px}
.col-2{display:flex;flex-direction:column;gap:10px}
.label{font-weight:600;color:#334155}
.input{padding:10px;border:1px solid #e6eef2;border-radius:8px;width:100%;box-sizing:border-box}
.textarea{min-height:80px;resize:vertical}
.input.small{width:160px}
.input.tiny{width:80px}

.items-header{display:flex;justify-content:space-between;align-items:center}
.btn-outline{background:#fff;border:1px solid #e6eef2;padding:6px 8px;border-radius:8px}
.items-list{display:flex;flex-direction:column;gap:10px}
.item-row-card{display:grid;grid-template-columns: 1fr 80px 120px 1fr 80px;gap:8px;align-items:center;padding:10px;border-radius:8px;border:1px solid #f0f6f8;background:#ffffff}
.btn-danger{background:#fff;border:1px solid #ffdddd;color:#ef4444;padding:6px 8px;border-radius:8px}

.summary{display:flex;justify-content:space-between;align-items:center;margin-top:12px;padding:10px;border-top:1px dashed #eef2f5}
.total-amount{font-weight:800;font-size:1.1rem}

.form-actions.full-width{grid-column:1 / -1;display:flex;gap:8px;justify-content:flex-end;margin-top:12px}
.btn-primary{background:#059669;color:#fff;padding:10px 14px;border-radius:8px;border:none}
.btn-ghost{background:transparent;border:1px solid #e6eef2;padding:8px 12px;border-radius:8px}
</style>
