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

        <!-- Archivos adjuntos -->
        <div class="attachments-block">
          <h4>📎 Archivos adjuntos</h4>
          <div v-if="archivos.length" class="attachments-gallery">
            <div v-for="arch in archivos" :key="arch.id" class="attach-thumb" @click="openPreview(arch)">
              <img v-if="isImage(arch.tipo || arch.nombre_archivo)" :src="arch.url" :alt="arch.nombre_archivo" />
              <div v-else class="attach-icon">📄</div>
              <div class="attach-name">{{ arch.nombre_archivo }}</div>
              <button class="attach-delete" @click.stop="deleteArchivo(arch)" title="Eliminar">✕</button>
            </div>
          </div>
          <div v-else class="no-attachments">Sin archivos adjuntos</div>
          <div class="add-files-section" v-if="!showUploader">
            <button class="btn-add-files" @click="showUploader = true">+ Agregar archivos</button>
          </div>
          <div v-if="showUploader" class="uploader-section">
            <FileUploader
              bucket="pedido-attachments"
              :folder="pedido.id"
              :maxFiles="10"
              @uploaded="onFileUploaded"
              @deleted="onFileDeletedFromUploader"
            />
          </div>
        </div>

        <!-- Lightbox -->
        <Teleport to="body">
          <div v-if="lightboxUrl" class="lightbox-overlay" @click="lightboxUrl = null">
            <div class="lightbox-content" @click.stop>
              <img :src="lightboxUrl" alt="Preview" />
              <button class="lightbox-close" @click="lightboxUrl = null">✕</button>
            </div>
          </div>
        </Teleport>

        <div class="items-block">
          <h4>Items</h4>
          <div v-for="(it, idx) in pedido.pedido_items || []" :key="it.id || idx" class="detail-item">
            <div class="item-left">{{ fmtQty(Number(it.cantidad)) }} x <strong>{{ it.descripcion_personalizada || it.productos?.nombre || 'Item' }}</strong></div>
            <div class="item-right">${{ ((Number(it.cantidad)||0) * (Number(it.precio_unitario)||0)).toFixed(2) }}</div>
          </div>
        </div>

        <div class="payments-block" v-if="pagos.length">
          <h4>Pagos / Anticipos</h4>
          <div v-for="pay in pagos" :key="pay.id" class="payment-row">
            <div>
              {{ new Date(pay.creado_en).toLocaleString() }} • <strong>${{ pay.monto.toFixed(2) }}</strong>
              <span v-if="pay.metodo" class="pay-method">{{ pay.metodo }}</span>
            </div>
            <div class="pay-right">{{ pay.es_anticipo ? 'Anticipo' : 'Pago' }}</div>
          </div>
        </div>

        <div class="total-row">
          <div>Total</div>
          <div class="total-amount">${{ (pedido.total || 0).toFixed(2) }}</div>
        </div>

        <div v-if="remainingAmount > 0" class="remaining-row">
          <div>Restante</div>
          <div class="remaining-amount">${{ remainingAmount.toFixed(2) }}</div>
        </div>

        <div v-if="remainingAmount <= 0 && pagos.length" class="paid-badge">
          ✅ Pagado por completo
        </div>

        <!-- Pagar por completo -->
        <div v-if="remainingAmount > 0 && !showPayForm" class="actions-row" style="gap:8px">
          <button class="btn-pay" @click="showPayForm = true">💳 Pagar por completo (${{ remainingAmount.toFixed(2) }})</button>
          <button class="btn-primary" style="margin-left:auto" @click="close">Cerrar</button>
          <button class="btn-primary" style="background:#0ea5a4" @click="reimprimirTicket">Re-imprimir Ticket</button>
        </div>

        <!-- Payment method form -->
        <div v-if="showPayForm" class="pay-form">
          <h4 style="margin:0 0 8px">Método de pago</h4>
          <p style="color:#666;margin:0 0 12px;font-size:0.9rem">Monto a pagar: <strong>${{ remainingAmount.toFixed(2) }}</strong></p>
          <div class="pay-methods">
            <button :class="['pay-option', selectedMethod === 'Efectivo' && 'pay-option-active']" @click="selectedMethod = 'Efectivo'">💵 Efectivo</button>
            <button :class="['pay-option', selectedMethod === 'Transferencia' && 'pay-option-active']" @click="selectedMethod = 'Transferencia'">🏦 Transferencia</button>
            <button :class="['pay-option', selectedMethod === 'Tarjeta' && 'pay-option-active']" @click="selectedMethod = 'Tarjeta'">💳 Tarjeta</button>
          </div>
          <div style="display:flex;gap:8px;justify-content:flex-end;margin-top:12px">
            <button class="btn-ghost" @click="showPayForm = false; selectedMethod = ''">Cancelar</button>
            <button class="btn-confirm" :disabled="!selectedMethod || paying" @click="handlePagarCompleto">
              {{ paying ? 'Procesando...' : 'Confirmar pago' }}
            </button>
          </div>
        </div>

        <div v-if="!showPayForm" class="actions-row">
          <template v-if="remainingAmount <= 0">
            <button class="btn-primary" @click="close">Cerrar</button>
            <button class="btn-primary" style="margin-left:8px;background:#0ea5a4" @click="reimprimirTicket">Re-imprimir Ticket</button>
          </template>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
import type { Pedido } from '../types'
import type { PedidoArchivo } from '../types/pedidos'
import type { Pago } from '../types/pagos'
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../lib/supabase'
import { usePedidos } from '../composables/usePedidos'
import { useStorage } from '../composables/useStorage'
import FileUploader from './FileUploader.vue'

const props = defineProps<{ pedido: Pedido }>()
const emit = defineEmits(['close', 'updated'])

const pagos = ref<Pago[]>([])
const showPayForm = ref(false)
const selectedMethod = ref('')
const paying = ref(false)

const { fetchPedidoById, printTicket, registrarPago } = usePedidos()
const { deleteFile, extractPathFromUrl } = useStorage()

const archivos = ref<PedidoArchivo[]>([])
const showUploader = ref(false)
const lightboxUrl = ref<string | null>(null)

function close(){ emit('close') }

const totalPaid = computed(() => pagos.value.reduce((s, p) => s + (Number(p.monto) || 0), 0))
const remainingAmount = computed(() => Math.max(0, (Number(pedido.total) || 0) - totalPaid.value))

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

function fmtQty(n: number) {
  if (!Number.isFinite(n)) return '0'
  if (Number.isInteger(n)) return String(n)
  return n.toFixed(2).replace(/\.?0+$/, '')
}

const pedido = props.pedido

onMounted(async ()=>{
  if (!pedido || !pedido.id) return
  const { data, error } = await supabase.from('pagos').select('*').eq('pedido_id', pedido.id).order('creado_en', { ascending: true })
  if (!error && data) pagos.value = data as Pago[]

  // Load attached files
  const { data: files } = await supabase
    .from('pedido_archivos')
    .select('*')
    .eq('pedido_id', pedido.id)
    .order('created_at', { ascending: true })
  if (files) archivos.value = files as PedidoArchivo[]
})

function isImage(nameOrType: string): boolean {
  const lower = (nameOrType || '').toLowerCase()
  return /^image\//.test(lower) || /\.(jpg|jpeg|png|gif|webp|svg|bmp)$/i.test(lower)
}

function openPreview(arch: PedidoArchivo) {
  if (isImage(arch.tipo || arch.nombre_archivo)) {
    lightboxUrl.value = arch.url
  } else {
    window.open(arch.url, '_blank')
  }
}

async function deleteArchivo(arch: PedidoArchivo) {
  if (!confirm(`\u00bfEliminar "${arch.nombre_archivo}"?`)) return
  const path = extractPathFromUrl(arch.url, 'pedido-attachments')
  await deleteFile('pedido-attachments', path)
  await supabase.from('pedido_archivos').delete().eq('id', arch.id)
  archivos.value = archivos.value.filter(a => a.id !== arch.id)
}

async function onFileUploaded(file: any) {
  const { data } = await supabase.from('pedido_archivos').insert({
    pedido_id: pedido.id,
    url: file.url,
    nombre_archivo: file.nombre_archivo,
    tipo: file.tipo || null,
    tamanio_bytes: file.tamanio_bytes || null
  }).select().single()
  if (data) archivos.value.push(data as PedidoArchivo)
}

function onFileDeletedFromUploader(file: any) {
  archivos.value = archivos.value.filter(a => a.url !== file.url)
}

async function handlePagarCompleto() {
  if (!selectedMethod.value || paying.value) return
  paying.value = true
  try {
    await registrarPago(pedido.id, remainingAmount.value, selectedMethod.value)
    // Refresh pagos list
    const { data } = await supabase.from('pagos').select('*').eq('pedido_id', pedido.id).order('creado_en', { ascending: true })
    if (data) pagos.value = data as Pago[]
    showPayForm.value = false
    selectedMethod.value = ''
    emit('updated')
  } catch (err) {
    console.error('Error registrando pago', err)
    alert('No se pudo registrar el pago')
  } finally {
    paying.value = false
  }
}

async function reimprimirTicket() {
  if (!pedido || !pedido.id) return
  try {
    const full = await fetchPedidoById(pedido.id)
    await printTicket(full)
  } catch (err) {
    console.warn('Error reimprimiendo ticket', err)
    alert('No se pudo reimprimir el ticket')
  }
}
</script>

<style scoped>
.modal-overlay{position:fixed;inset:0;background:rgba(2,6,23,0.45);display:flex;align-items:center;justify-content:center;padding:16px;z-index:80}
.modal-card{background:linear-gradient(180deg,#ffffff,#fbfdff);border-radius:12px;padding:18px;width:640px;max-width:100%;max-height:90vh;overflow-y:auto;box-shadow:0 12px 36px rgba(2,6,23,0.12);box-sizing:border-box}
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
.pay-method{display:inline-block;margin-left:6px;padding:2px 8px;border-radius:999px;background:#eff6ff;color:#2563eb;font-size:0.8rem;font-weight:600}
.total-row{display:flex;justify-content:space-between;font-weight:700;padding-top:6px}
.remaining-row{display:flex;justify-content:space-between;font-weight:600;color:#dc2626}
.remaining-amount{font-weight:700}
.paid-badge{text-align:center;padding:8px;border-radius:8px;background:#ecfdf5;color:#065f46;font-weight:600}
.actions-row{display:flex;justify-content:flex-end}
.btn-primary{background:#059669;color:#fff;padding:8px 12px;border-radius:8px;border:none}
.btn-pay{background:linear-gradient(135deg,#3b82f6,#2563eb);color:#fff;padding:10px 18px;border-radius:8px;border:none;font-weight:700;cursor:pointer;font-size:0.95rem}
.btn-pay:hover{filter:brightness(1.1)}
.badge{padding:6px 10px;border-radius:999px;color:white;font-weight:600}
.status-pending { background:#f59e0b }
.status-blue { background:#3b82f6 }
.status-gray { background:#6b7280 }
.status-green { background:#10b981 }
.status-red { background:#ef4444 }

/* Pay form */
.pay-form{border:1px solid #e0e7ff;border-radius:10px;padding:16px;background:#f8fafc}
.pay-methods{display:flex;gap:10px;justify-content:center}
.pay-option{background:#f6f7fb;border:2px solid #e5e7eb;padding:12px 20px;border-radius:10px;font-size:0.95rem;cursor:pointer;transition:all 0.15s}
.pay-option:hover{border-color:#3b82f6;background:#eff6ff}
.pay-option-active{border-color:#3b82f6;background:#eff6ff;font-weight:700}
.btn-ghost{background:transparent;border:1px solid #ddd;padding:8px 14px;border-radius:6px;cursor:pointer}
.btn-confirm{background:#059669;color:#fff;padding:8px 16px;border-radius:8px;border:none;font-weight:700;cursor:pointer}
.btn-confirm:disabled{opacity:0.5;cursor:not-allowed}

/* Dark mode */
:is(.dark) .modal-overlay{background:rgba(0,0,0,0.6)}
:is(.dark) .modal-card{background:linear-gradient(180deg,#111c2e,#0f1729);box-shadow:0 12px 36px rgba(0,0,0,0.3)}
:is(.dark) .modal-header--accent{border-bottom-color:#1e293b}
:is(.dark) .modal-header--accent h3{color:#e2e8f0}
:is(.dark) .subtitle{color:#94a3b8}
:is(.dark) .close{color:#94a3b8}
:is(.dark) .modal-body{color:#cbd5e1}
:is(.dark) .meta-row{color:#cbd5e1}
:is(.dark) .meta-row strong{color:#e2e8f0}
:is(.dark) .notes-block h4{color:#e2e8f0}
:is(.dark) .notes-block .notes{background:#0f1729;border-color:#1e293b;color:#cbd5e1}
:is(.dark) .items-block{border-color:#1e293b}
:is(.dark) .items-block h4{color:#e2e8f0}
:is(.dark) .detail-item{border-bottom-color:#1e293b;color:#cbd5e1}
:is(.dark) .detail-item strong{color:#e2e8f0}
:is(.dark) .payments-block{border-color:#1e293b}
:is(.dark) .payments-block h4{color:#e2e8f0}
:is(.dark) .payment-row{border-bottom-color:#1e293b;color:#cbd5e1}
:is(.dark) .pay-right{color:#94a3b8}
:is(.dark) .pay-method{background:#1e3a5f;color:#93c5fd}
:is(.dark) .total-row{color:#e2e8f0}
:is(.dark) .remaining-row{color:#fca5a5}
:is(.dark) .paid-badge{background:#052e16;color:#6ee7b7}
:is(.dark) .pay-form{background:#0f1729;border-color:#1e293b}
:is(.dark) .pay-form h4{color:#e2e8f0}
:is(.dark) .pay-methods .pay-option{background:#0f1729;border-color:#334155;color:#cbd5e1}
:is(.dark) .pay-methods .pay-option:hover{border-color:#3b82f6;background:#1e3a5f}
:is(.dark) .pay-methods .pay-option-active{border-color:#3b82f6;background:#1e3a5f}
:is(.dark) .btn-ghost{border-color:#334155;color:#cbd5e1}

/* Attachments */
.attachments-block{border:1px solid #f1f5f9;padding:12px;border-radius:8px}
.attachments-block h4{margin:0 0 10px;font-size:0.95rem}
.attachments-gallery{display:grid;grid-template-columns:repeat(auto-fill,minmax(100px,1fr));gap:10px}
.attach-thumb{position:relative;border:1px solid #e2e8f0;border-radius:8px;overflow:hidden;cursor:pointer;background:#f8fafc;transition:box-shadow 0.15s}
.attach-thumb:hover{box-shadow:0 4px 12px rgba(14,165,164,0.12)}
.attach-thumb img{width:100%;height:72px;object-fit:cover;display:block}
.attach-icon{width:100%;height:72px;display:flex;align-items:center;justify-content:center;font-size:1.8rem;background:#f1f5f9}
.attach-name{padding:4px 6px;font-size:0.72rem;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;color:#475569;font-weight:600}
.attach-delete{position:absolute;top:3px;right:3px;width:20px;height:20px;border-radius:50%;border:none;background:rgba(239,68,68,0.85);color:#fff;font-size:0.65rem;font-weight:700;cursor:pointer;display:flex;align-items:center;justify-content:center;opacity:0;transition:opacity 0.15s}
.attach-thumb:hover .attach-delete{opacity:1}
.no-attachments{color:#94a3b8;font-size:0.88rem;padding:8px 0}
.add-files-section{margin-top:8px}
.btn-add-files{background:#f0fdfa;border:1px dashed #0ea5a4;color:#0ea5a4;padding:8px 14px;border-radius:8px;font-weight:600;cursor:pointer;font-size:0.88rem;transition:all 0.15s}
.btn-add-files:hover{background:#ccfbf1}
.uploader-section{margin-top:10px}

/* Lightbox */
.lightbox-overlay{position:fixed;inset:0;background:rgba(0,0,0,0.8);display:flex;align-items:center;justify-content:center;z-index:100;padding:24px;animation:fadeIn 0.2s ease}
@keyframes fadeIn{from{opacity:0}to{opacity:1}}
.lightbox-content{position:relative;max-width:90vw;max-height:90vh}
.lightbox-content img{max-width:100%;max-height:85vh;border-radius:8px;box-shadow:0 16px 48px rgba(0,0,0,0.4)}
.lightbox-close{position:absolute;top:-12px;right:-12px;width:32px;height:32px;border-radius:50%;border:none;background:#fff;color:#111;font-size:1rem;font-weight:700;cursor:pointer;box-shadow:0 4px 12px rgba(0,0,0,0.2)}

/* Dark attachments */
:is(.dark) .attachments-block{border-color:#1e293b}
:is(.dark) .attachments-block h4{color:#e2e8f0}
:is(.dark) .attach-thumb{background:#0f1729;border-color:#1e293b}
:is(.dark) .attach-icon{background:#111c2e}
:is(.dark) .attach-name{color:#94a3b8}
:is(.dark) .no-attachments{color:#64748b}
:is(.dark) .btn-add-files{background:#0c2e2d;border-color:#0ea5a4;color:#5eead4}
:is(.dark) .btn-add-files:hover{background:#0f3b3a}
</style>
