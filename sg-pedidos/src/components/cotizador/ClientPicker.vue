<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useClientes } from '../../composables/useClientes'
import type { Cliente } from '../../types'

const emit = defineEmits<{
  (e: 'select', client: Cliente): void
  (e: 'close'): void
}>()

const { clientes, loading, fetchClientes } = useClientes()

const search = ref('')
const hasFetched = ref(false)

onMounted(async () => {
  if (clientes.value.length === 0) {
    await fetchClientes()
  }
  hasFetched.value = true
})

const filtered = computed(() => {
  const q = search.value.toLowerCase().trim()
  if (!q) return clientes.value
  return clientes.value.filter(c =>
    (c.nombre || '').toLowerCase().includes(q) ||
    (c.telefono || '').toLowerCase().includes(q) ||
    (c.correo || '').toLowerCase().includes(q)
  )
})

function selectClient(c: Cliente) {
  emit('select', c)
  emit('close')
}

function handleOverlayClick(e: MouseEvent) {
  if ((e.target as HTMLElement).classList.contains('cp-overlay')) {
    emit('close')
  }
}
</script>

<template>
  <div class="cp-overlay" @click="handleOverlayClick">
    <div class="cp-modal">
      <div class="cp-header">
        <div class="cp-title">
          <span class="cp-title-icon">👤</span>
          <span>Seleccionar cliente</span>
        </div>
        <button class="cp-close" @click="$emit('close')">✕</button>
      </div>

      <div class="cp-search">
        <input
          v-model="search"
          type="text"
          placeholder="Buscar por nombre, teléfono o correo..."
          autofocus
          class="cp-search-input"
        />
      </div>

      <div class="cp-body">
        <div v-if="loading && !hasFetched" class="cp-loading">
          <div class="cp-spinner"></div>
          <span>Cargando clientes...</span>
        </div>

        <div v-else-if="filtered.length === 0" class="cp-empty">
          <span class="cp-empty-icon">🔍</span>
          <span>No se encontraron clientes</span>
        </div>

        <div v-else class="cp-list">
          <div
            v-for="c in filtered"
            :key="c.id"
            class="cp-item"
            @click="selectClient(c)"
          >
            <div class="cp-item-avatar">{{ (c.nombre || '?')[0].toUpperCase() }}</div>
            <div class="cp-item-main">
              <div class="cp-item-name">{{ c.nombre }}</div>
              <div class="cp-item-info">
                <span v-if="c.telefono">📞 {{ c.telefono }}</span>
                <span v-if="c.correo">✉️ {{ c.correo }}</span>
                <span v-if="!c.telefono && !c.correo" class="cp-item-noinfo">Sin datos de contacto</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="cp-footer">
        <span class="cp-count">{{ filtered.length }} cliente{{ filtered.length !== 1 ? 's' : '' }}</span>
        <button class="cp-btn-cancel" @click="$emit('close')">Cancelar</button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.cp-overlay {
  position: fixed;
  inset: 0;
  z-index: 9999;
  background: rgba(0,0,0,.45);
  display: flex;
  align-items: center;
  justify-content: center;
  animation: cpFadeIn .18s ease;
}
@keyframes cpFadeIn { from { opacity: 0 } to { opacity: 1 } }

.cp-modal {
  background: #fff;
  border-radius: 16px;
  box-shadow: 0 24px 64px rgba(0,0,0,.22);
  width: 500px;
  max-width: 94vw;
  max-height: 80vh;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  animation: cpSlideUp .22s ease;
}
@keyframes cpSlideUp { from { transform: translateY(24px); opacity: 0 } to { transform: translateY(0); opacity: 1 } }

.cp-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 20px 12px;
  border-bottom: 1px solid #f0f0f0;
}
.cp-title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 700;
  font-size: 1.05rem;
  color: #1b4276;
}
.cp-title-icon { font-size: 1.2rem }
.cp-close {
  background: none;
  border: none;
  font-size: 1.1rem;
  cursor: pointer;
  color: #888;
  padding: 4px 8px;
  border-radius: 8px;
  transition: background .15s;
}
.cp-close:hover { background: #f3f3f3; color: #333 }

.cp-search {
  padding: 12px 20px 8px;
}
.cp-search-input {
  width: 100%;
  padding: 10px 14px;
  border: 1.5px solid #e0e0e0;
  border-radius: 10px;
  font-size: .95rem;
  outline: none;
  transition: border-color .15s;
  box-sizing: border-box;
}
.cp-search-input:focus {
  border-color: #1b4276;
  box-shadow: 0 0 0 3px rgba(27,66,118,.1);
}

.cp-body {
  flex: 1;
  overflow-y: auto;
  padding: 4px 12px 8px;
  min-height: 120px;
}

.cp-loading, .cp-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 10px;
  padding: 40px 0;
  color: #888;
  font-size: .95rem;
}
.cp-empty-icon { font-size: 1.8rem }
.cp-spinner {
  width: 28px; height: 28px;
  border: 3px solid #e0e0e0;
  border-top-color: #1b4276;
  border-radius: 50%;
  animation: cpSpin .7s linear infinite;
}
@keyframes cpSpin { to { transform: rotate(360deg) } }

.cp-list {
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.cp-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 12px;
  border-radius: 10px;
  cursor: pointer;
  transition: background .12s, box-shadow .12s;
  border: 1px solid transparent;
}
.cp-item:hover {
  background: #f0f6ff;
  border-color: #c8ddf5;
  box-shadow: 0 2px 8px rgba(27,66,118,.07);
}
.cp-item-avatar {
  width: 38px;
  height: 38px;
  border-radius: 50%;
  background: linear-gradient(135deg, #1b4276, #2563eb);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  font-weight: 700;
  font-size: 1rem;
  flex-shrink: 0;
}
.cp-item-main {
  min-width: 0;
  flex: 1;
}
.cp-item-name {
  font-weight: 600;
  font-size: .95rem;
  color: #222;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.cp-item-info {
  display: flex;
  gap: 12px;
  font-size: .82rem;
  color: #888;
  margin-top: 2px;
}
.cp-item-noinfo {
  font-style: italic;
  color: #bbb;
}

.cp-footer {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 20px;
  border-top: 1px solid #f0f0f0;
}
.cp-count {
  font-size: .82rem;
  color: #888;
}
.cp-btn-cancel {
  padding: 7px 18px;
  border-radius: 8px;
  border: 1px solid #ddd;
  background: #fff;
  cursor: pointer;
  font-size: .9rem;
  color: #555;
  transition: background .12s;
}
.cp-btn-cancel:hover { background: #f5f5f5 }

/* Dark mode */
:is(.dark) .cp-modal { background: #0f1729; border-color: #1e293b }
:is(.dark) .cp-header { border-bottom-color: #1e293b }
:is(.dark) .cp-title { color: #93c5fd }
:is(.dark) .cp-close { color: #94a3b8 }
:is(.dark) .cp-close:hover { background: #1e293b; color: #e2e8f0 }
:is(.dark) .cp-search-input { background: #111c2e; border-color: #334155; color: #e2e8f0 }
:is(.dark) .cp-search-input::placeholder { color: #475569 }
:is(.dark) .cp-search-input:focus { border-color: #3b82f6; box-shadow: 0 0 0 3px rgba(59,130,246,.15) }
:is(.dark) .cp-item:hover { background: #1e293b; border-color: #334155 }
:is(.dark) .cp-item-avatar { background: linear-gradient(135deg, #1e3a5f, #3b82f6) }
:is(.dark) .cp-item-name { color: #e2e8f0 }
:is(.dark) .cp-item-info { color: #64748b }
:is(.dark) .cp-item-noinfo { color: #475569 }
:is(.dark) .cp-footer { border-top-color: #1e293b }
:is(.dark) .cp-count { color: #64748b }
:is(.dark) .cp-btn-cancel { background: #111c2e; border-color: #334155; color: #cbd5e1 }
:is(.dark) .cp-btn-cancel:hover { background: #1e293b }
:is(.dark) .cp-loading, :is(.dark) .cp-empty { color: #64748b }
:is(.dark) .cp-spinner { border-color: #334155; border-top-color: #3b82f6 }
</style>
