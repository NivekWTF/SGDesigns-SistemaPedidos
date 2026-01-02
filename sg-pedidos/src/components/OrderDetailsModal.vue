<template>
  <div class="modal-overlay" @click.self="close">
    <div class="modal-card">
      <header class="modal-header--accent">
        <div class="modal-title">
          <div class="logo-pill">📄</div>
          <div>
            <h3>Detalle Pedido</h3>
            <div class="subtitle">{{ pedido.folio || ('#' + pedido.id.slice(0,8)) }} • {{ formatDate(pedido.created_at) }}</div>
          </div>
        </div>
        <button class="close" @click="close">✕</button>
      </header>

      <section class="modal-body">
        <div class="meta-row">
          <div><strong>Cliente:</strong> {{ pedido.clientes?.nombre || 'Sin cliente' }}</div>
          <div><strong>Estado:</strong> <span :class="['badge', statusClass(pedido.estado)]">{{ pedido.estado }}</span></div>
        </div>

        <div class="notes-block" v-if="pedido.notas">
          <h4>Notas</h4>
          <div class="notes">{{ pedido.notas }}</div>
        </div>

        <div class="items-block">
          <h4>Items</h4>
          <div v-for="(it, idx) in pedido.pedido_items || []" :key="it.id || idx" class="detail-item">
            <div class="item-left">{{ it.cantidad }} x <strong>{{ it.descripcion_personalizada || it.productos?.nombre || 'Item' }}</strong></div>
            <div class="item-right">${{ ((it.cantidad||0) * (it.precio_unitario||0)).toFixed(2) }}</div>
          </div>
        </div>

        <div class="payments-block" v-if="pagos.length">
          <h4>Pagos / Anticipos</h4>
          <div v-for="pay in pagos" :key="pay.id" class="payment-row">
            <div>{{ new Date(pay.creado_en).toLocaleString() }} • <strong>${{ pay.monto.toFixed(2) }}</strong></div>
            <div class="pay-right">{{ pay.es_anticipo ? 'Anticipo' : (pay.metodo || 'Pago') }}</div>
          </div>
        </div>

        <div class="total-row">
          <div>Total</div>
          <div class="total-amount">${{ (pedido.total || 0).toFixed(2) }}</div>
        </div>

        <div class="actions-row">
          <button class="btn-primary" @click="close">Cerrar</button>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Pedido } from '../types'
import type { Pago } from '../types/pagos'
import { defineEmits, ref, onMounted } from 'vue'
import { supabase } from '../lib/supabase'

const props = defineProps<{ pedido: Pedido }>()
const emit = defineEmits(['close'])

const pagos = ref<Pago[]>([])

function close(){ emit('close') }

function statusClass(s?: string){
  switch(s){
    case 'PENDIENTE': return 'status-pending'
    case 'EN_PRODUCCION': return 'status-blue'
    case 'TERMINADO': return 'status-gray'
    case 'ENTREGADO': return 'status-green'
    case 'CANCELADO': return 'status-red'
    default: return 'status-gray'
  }
}

function formatDate(d?: string | null){
  if(!d) return ''
  try{ return new Date(d).toLocaleString() }catch{ return d }
}

const pedido = props.pedido

onMounted(async ()=>{
  if (!pedido || !pedido.id) return
  const { data, error } = await supabase.from('pagos').select('*').eq('pedido_id', pedido.id).order('creado_en', { ascending: true })
  if (!error && data) pagos.value = data as Pago[]
})
</script>

<style scoped>
.modal-overlay{position:fixed;inset:0;background:rgba(2,6,23,0.45);display:flex;align-items:center;justify-content:center;padding:24px;z-index:80}
.modal-card{background:linear-gradient(180deg,#ffffff,#fbfdff);border-radius:12px;padding:18px;width:640px;box-shadow:0 12px 36px rgba(2,6,23,0.12)}
.modal-header--accent{display:flex;justify-content:space-between;align-items:center;padding-bottom:8px;border-bottom:1px solid #eef2f5}
.modal-title{display:flex;gap:12px;align-items:center}
.logo-pill{width:44px;height:44px;border-radius:10px;background:#0ea5a4;color:white;display:flex;align-items:center;justify-content:center;font-weight:700}
.subtitle{font-size:0.85rem;color:#475569}
.close{background:none;border:none;font-size:1.1rem}
.modal-body{padding-top:12px;display:flex;flex-direction:column;gap:12px}
.meta-row{display:flex;justify-content:space-between;gap:12px}
.notes-block .notes{background:#fbfcfd;border:1px solid #eef2f5;padding:10px;border-radius:8px}
.items-block{border:1px solid #f1f5f9;padding:10px;border-radius:8px}
.detail-item{display:flex;justify-content:space-between;padding:6px 0;border-bottom:1px dashed #f3f7fa}
.detail-item:last-child{border-bottom:0}
.payments-block{border:1px solid #f1f5f9;padding:10px;border-radius:8px}
.payment-row{display:flex;justify-content:space-between;padding:8px 0;border-bottom:1px dashed #f3f7fa}
.payment-row:last-child{border-bottom:0}
.pay-right{color:#667085}
.total-row{display:flex;justify-content:space-between;font-weight:700;padding-top:6px}
.actions-row{display:flex;justify-content:flex-end}
.btn-primary{background:#059669;color:#fff;padding:8px 12px;border-radius:8px;border:none}
.badge{padding:6px 10px;border-radius:999px;color:white;font-weight:600}
.status-pending { background:#f59e0b }
.status-blue { background:#3b82f6 }
.status-gray { background:#6b7280 }
.status-green { background:#10b981 }
.status-red { background:#ef4444 }
</style>
