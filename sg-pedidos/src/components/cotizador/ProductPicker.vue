<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useProductos } from '../../composables/useProductos'
import type { Producto } from '../../types'

const emit = defineEmits<{
  (e: 'select', product: Producto): void
  (e: 'close'): void
}>()

const { productos, loading, fetchProductos } = useProductos()

const search = ref('')
const hasFetched = ref(false)

onMounted(async () => {
  if (productos.value.length === 0) {
    await fetchProductos()
  }
  hasFetched.value = true
})

const filtered = computed(() => {
  const q = search.value.toLowerCase().trim()
  const active = productos.value.filter(p => p.activo)
  if (!q) return active
  return active.filter(p =>
    (p.nombre || '').toLowerCase().includes(q) ||
    (p.descripcion || '').toLowerCase().includes(q) ||
    (p.unidad || '').toLowerCase().includes(q)
  )
})

function selectProduct(p: Producto) {
  emit('select', p)
  emit('close')
}

function formatPrice(n: number) {
  return (n ?? 0).toLocaleString('es-MX', { style: 'currency', currency: 'MXN' })
}

function stockClass(stock: number | null | undefined) {
  if (typeof stock !== 'number') return 'pp-stock--neutral'
  if (stock === 0) return 'pp-stock--zero'
  if (stock <= 2) return 'pp-stock--low'
  return 'pp-stock--ok'
}

function handleOverlayClick(e: MouseEvent) {
  if ((e.target as HTMLElement).classList.contains('pp-overlay')) {
    emit('close')
  }
}
</script>

<template>
  <div class="pp-overlay" @click="handleOverlayClick">
    <div class="pp-modal">
      <div class="pp-header">
        <div class="pp-title">
          <span class="pp-title-icon">📦</span>
          <span>Seleccionar producto</span>
        </div>
        <button class="pp-close" @click="$emit('close')">✕</button>
      </div>

      <div class="pp-search">
        <input
          v-model="search"
          type="text"
          placeholder="Buscar por nombre, descripción o unidad..."
          autofocus
          class="pp-search-input"
        />
      </div>

      <div class="pp-body">
        <div v-if="loading && !hasFetched" class="pp-loading">
          <div class="pp-spinner"></div>
          <span>Cargando productos...</span>
        </div>

        <div v-else-if="filtered.length === 0" class="pp-empty">
          <span class="pp-empty-icon">🔍</span>
          <span>No se encontraron productos</span>
        </div>

        <div v-else class="pp-list">
          <div
            v-for="p in filtered"
            :key="p.id"
            class="pp-item"
            @click="selectProduct(p)"
          >
            <div class="pp-item-main">
              <div class="pp-item-name">{{ p.nombre }}</div>
              <div class="pp-item-desc" v-if="p.descripcion">{{ p.descripcion }}</div>
            </div>
            <div class="pp-item-meta">
              <span class="pp-item-unit" v-if="p.unidad">{{ p.unidad }}</span>
              <span :class="['pp-item-stock', stockClass(p.stock)]">
                Stock: {{ typeof p.stock === 'number' ? p.stock : '—' }}
              </span>
            </div>
            <div class="pp-item-price">{{ formatPrice(p.precio_base) }}</div>
          </div>
        </div>
      </div>

      <div class="pp-footer">
        <span class="pp-count">{{ filtered.length }} producto{{ filtered.length !== 1 ? 's' : '' }}</span>
        <button class="pp-btn-cancel" @click="$emit('close')">Cancelar</button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.pp-overlay {
  position: fixed;
  inset: 0;
  z-index: 9999;
  background: rgba(0,0,0,.45);
  display: flex;
  align-items: center;
  justify-content: center;
  animation: ppFadeIn .18s ease;
}
@keyframes ppFadeIn { from { opacity: 0 } to { opacity: 1 } }

.pp-modal {
  background: #fff;
  border-radius: 16px;
  box-shadow: 0 24px 64px rgba(0,0,0,.22);
  width: 560px;
  max-width: 94vw;
  max-height: 80vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  animation: ppSlideUp .22s ease;
}
@keyframes ppSlideUp { from { transform: translateY(24px); opacity: 0 } to { transform: translateY(0); opacity: 1 } }

.pp-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 20px 12px;
  border-bottom: 1px solid #f0f0f0;
}
.pp-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 700;
  font-size: 1.05rem;
  color: #1b4276;
}
.pp-title-icon { font-size: 1.2rem }
.pp-close {
  background: none;
  border: none;
  font-size: 1.1rem;
  cursor: pointer;
  color: #888;
  padding: 4px 8px;
  border-radius: 8px;
  transition: background .15s;
}
.pp-close:hover { background: #f3f3f3; color: #333 }

.pp-search {
  padding: 12px 20px 8px;
}
.pp-search-input {
  width: 100%;
  padding: 10px 14px;
  border: 1.5px solid #e0e0e0;
  border-radius: 10px;
  font-size: .95rem;
  outline: none;
  transition: border-color .15s;
  box-sizing: border-box;
}
.pp-search-input:focus {
  border-color: #1b4276;
  box-shadow: 0 0 0 3px rgba(27,66,118,.1);
}

.pp-body {
  flex: 1;
  overflow-y: auto;
  padding: 4px 12px 8px;
  min-height: 120px;
}

.pp-loading, .pp-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 40px 0;
  color: #888;
  font-size: .95rem;
}
.pp-empty-icon { font-size: 1.8rem }
.pp-spinner {
  width: 28px; height: 28px;
  border: 3px solid #e0e0e0;
  border-top-color: #1b4276;
  border-radius: 50%;
  animation: ppSpin .7s linear infinite;
}
@keyframes ppSpin { to { transform: rotate(360deg) } }

.pp-list {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.pp-item {
  display: grid;
  grid-template-columns: 1fr auto auto;
  align-items: center;
  gap: 12px;
  padding: 10px 12px;
  border-radius: 10px;
  cursor: pointer;
  transition: background .12s, box-shadow .12s;
  border: 1px solid transparent;
}
.pp-item:hover {
  background: #f0f6ff;
  border-color: #c8ddf5;
  box-shadow: 0 2px 8px rgba(27,66,118,.07);
}
.pp-item-main {
  min-width: 0;
}
.pp-item-name {
  font-weight: 600;
  font-size: .95rem;
  color: #222;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.pp-item-desc {
  font-size: .82rem;
  color: #888;
  margin-top: 2px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.pp-item-meta {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 3px;
}
.pp-item-unit {
  font-size: .78rem;
  color: #666;
  background: #f4f4f4;
  padding: 2px 8px;
  border-radius: 6px;
}
.pp-item-stock {
  font-size: .75rem;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: 6px;
  color: #fff;
}
.pp-stock--ok { background: #16a34a }
.pp-stock--low { background: #f59e0b }
.pp-stock--zero { background: #ef4444 }
.pp-stock--neutral { background: #94a3b8 }
.pp-item-price {
  font-weight: 700;
  font-size: 1rem;
  color: #1b4276;
  white-space: nowrap;
  min-width: 90px;
  text-align: right;
}

.pp-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 20px;
  border-top: 1px solid #f0f0f0;
}
.pp-count {
  font-size: .82rem;
  color: #888;
}
.pp-btn-cancel {
  padding: 7px 18px;
  border-radius: 8px;
  border: 1px solid #ddd;
  background: #fff;
  cursor: pointer;
  font-size: .9rem;
  color: #555;
  transition: background .12s;
}
.pp-btn-cancel:hover { background: #f5f5f5 }

/* Dark mode */
:is(.dark) .pp-modal { background: #0f1729; border-color: #1e293b }
:is(.dark) .pp-header { border-bottom-color: #1e293b }
:is(.dark) .pp-title { color: #93c5fd }
:is(.dark) .pp-close { color: #94a3b8 }
:is(.dark) .pp-close:hover { background: #1e293b; color: #e2e8f0 }
:is(.dark) .pp-search-input { background: #111c2e; border-color: #334155; color: #e2e8f0 }
:is(.dark) .pp-search-input::placeholder { color: #475569 }
:is(.dark) .pp-search-input:focus { border-color: #3b82f6; box-shadow: 0 0 0 3px rgba(59,130,246,.15) }
:is(.dark) .pp-item:hover { background: #1e293b; border-color: #334155 }
:is(.dark) .pp-item-name { color: #e2e8f0 }
:is(.dark) .pp-item-desc { color: #64748b }
:is(.dark) .pp-item-unit { background: #1e293b; color: #94a3b8 }
:is(.dark) .pp-item-price { color: #93c5fd }
:is(.dark) .pp-footer { border-top-color: #1e293b }
:is(.dark) .pp-count { color: #64748b }
:is(.dark) .pp-btn-cancel { background: #111c2e; border-color: #334155; color: #cbd5e1 }
:is(.dark) .pp-btn-cancel:hover { background: #1e293b }
:is(.dark) .pp-loading, :is(.dark) .pp-empty { color: #64748b }
:is(.dark) .pp-spinner { border-color: #334155; border-top-color: #3b82f6 }
</style>
