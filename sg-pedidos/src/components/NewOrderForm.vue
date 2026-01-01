<template>
  <div class="modal-overlay" @click.self="close">
    <div class="modal-card">
      <header class="modal-header">
        <h3>Nuevo pedido</h3>
        <button class="close" @click="close">✕</button>
      </header>

      <form @submit.prevent="handleCrearPedido">
        <div>
          <label>Cliente</label>
          <select v-model="clienteId" required>
            <option value="">-- Selecciona un cliente --</option>
            <option v-for="c in clientes" :key="c.id" :value="c.id">{{ c.nombre }}</option>
          </select>
        </div>

        <div>
          <label>Notas</label>
          <textarea v-model="notas" />
        </div>

        <div>
          <label>Anticipo (opcional)</label>
          <input v-model.number="anticipo" type="number" min="0" step="0.01" placeholder="0.00" />
        </div>

        <div>
          <h4>Items</h4>
          <div v-for="(it, idx) in items" :key="idx" class="item-row">
            <select v-model="items[idx].producto_id" @change="onProductChange(idx)">
              <option :value="null">-- Sin producto --</option>
              <option v-for="prod in productos" :key="prod.id" :value="prod.id">
                {{ prod.nombre }} - ${{ prod.precio_base }}
              </option>
            </select>

            <input v-model.number="items[idx].cantidad" type="number" min="1" />
            <input v-model.number="items[idx].precio_unitario" type="number" min="0" step="0.01" />
            <input v-model="items[idx].descripcion_personalizada" placeholder="Descripción" />

            <button type="button" @click="removeItem(idx)">Eliminar</button>
          </div>

          <button type="button" @click="addItem">Añadir ítem</button>
        </div>

        <div class="form-actions">
          <button type="submit" class="btn-primary">Crear pedido</button>
          <button type="button" @click="close">Cancelar</button>
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
.modal-overlay{position:fixed;inset:0;background:rgba(0,0,0,0.35);display:flex;align-items:flex-start;justify-content:center;padding:40px;z-index:50}
.modal-card{background:#fff;border-radius:8px;padding:16px;width:760px;max-height:80vh;overflow:auto}
.modal-header{display:flex;justify-content:space-between;align-items:center}
.modal-header .close{background:none;border:none;font-size:1.1rem}
.item-row{display:flex;gap:8px;align-items:center;margin-bottom:8px}
.form-actions{display:flex;gap:8px;justify-content:flex-end;margin-top:12px}
.btn-primary{background:#059669;color:#fff;padding:8px 12px;border-radius:6px;border:none}
</style>
