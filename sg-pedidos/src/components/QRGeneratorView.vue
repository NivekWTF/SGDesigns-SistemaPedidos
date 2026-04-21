<template>
  <div class="qr-page">
    <div class="qr-header">
      <div class="qr-header-icon">
        <QrCode class="h-7 w-7" />
      </div>
      <div>
        <h1 class="qr-title">Generador de Códigos QR</h1>
        <p class="qr-subtitle">Genera códigos QR sin conexión a internet, 100% local</p>
      </div>
    </div>

    <div class="qr-layout">
      <!-- Panel de configuración -->
      <div class="qr-panel">
        <div class="panel-section">
          <label class="field-label">Contenido del QR</label>
          <textarea
            id="qr-text-input"
            v-model="qrText"
            class="qr-textarea"
            placeholder="Escribe un URL, texto, número de pedido, datos del cliente…"
            rows="4"
            @input="debouncedGenerate"
          />
          <div class="char-count" :class="{ danger: qrText.length > 2000 }">
            {{ qrText.length }} caracteres
            <span v-if="qrText.length > 2000" class="danger-text"> — muy largo, el QR puede fallar</span>
          </div>
        </div>

        <!-- Presets rápidos -->
        <div class="panel-section">
          <label class="field-label">Plantillas rápidas</label>
          <div class="presets-grid">
            <button
              v-for="preset in presets"
              :key="preset.label"
              class="preset-btn"
              :class="{ active: activePreset === preset.label }"
              @click="applyPreset(preset)"
            >
              <component :is="preset.icon" class="h-4 w-4" />
              {{ preset.label }}
            </button>
          </div>
        </div>

        <!-- Opciones de diseño -->
        <div class="panel-section">
          <label class="field-label">Color del QR</label>
          <div class="color-row">
            <div class="color-field">
              <span class="color-label">Módulos</span>
              <div class="color-pick-wrap">
                <input id="qr-color-dark" type="color" v-model="darkColor" @input="generate" class="color-input" />
                <span class="color-hex">{{ darkColor }}</span>
              </div>
            </div>
            <div class="color-field">
              <span class="color-label">Fondo</span>
              <div class="color-pick-wrap">
                <input id="qr-color-light" type="color" v-model="lightColor" @input="generate" class="color-input" />
                <span class="color-hex">{{ lightColor }}</span>
              </div>
            </div>
          </div>
        </div>

        <div class="panel-section two-cols">
          <div>
            <label class="field-label" for="qr-size">Tamaño (px)</label>
            <input id="qr-size" type="number" v-model.number="size" min="128" max="1024" step="64" class="qr-input" @change="generate" />
          </div>
          <div>
            <label class="field-label" for="qr-margin">Margen</label>
            <input id="qr-margin" type="number" v-model.number="margin" min="0" max="10" class="qr-input" @change="generate" />
          </div>
        </div>

        <div class="panel-section">
          <label class="field-label" for="qr-ecl">Corrección de errores</label>
          <select id="qr-ecl" v-model="errorCorrectionLevel" class="qr-select" @change="generate">
            <option value="L">L — Mínima (7%)</option>
            <option value="M">M — Media (15%) — recomendado</option>
            <option value="Q">Q — Alta (25%)</option>
            <option value="H">H — Máxima (30%)</option>
          </select>
        </div>

        <!-- Nombre de archivo -->
        <div class="panel-section">
          <label class="field-label" for="qr-filename">Nombre del archivo</label>
          <input id="qr-filename" type="text" v-model="filename" placeholder="mi-codigo-qr" class="qr-input" />
        </div>

        <!-- Acciones de descarga -->
        <div class="panel-section">
          <div class="actions-row">
            <button id="btn-download-png" class="action-btn primary" :disabled="!hasContent" @click="downloadPNG">
              <Download class="h-4 w-4" />
              Descargar PNG
            </button>
            <button id="btn-download-svg" class="action-btn secondary" :disabled="!hasContent" @click="downloadSVG">
              <FileCode class="h-4 w-4" />
              Descargar SVG
            </button>
            <button id="btn-copy-clipboard" class="action-btn ghost" :disabled="!hasContent" @click="copyToClipboard">
              <component :is="copied ? Check : Copy" class="h-4 w-4" />
              {{ copied ? 'Copiado!' : 'Copiar imagen' }}
            </button>
          </div>
        </div>
      </div>

      <!-- Panel de previsualización -->
      <div class="qr-preview-panel">
        <div class="preview-card">
          <div class="preview-header">
            <span class="preview-label">Vista previa</span>
            <span v-if="hasContent" class="preview-badge">
              <Eye class="h-3.5 w-3.5" /> en vivo
            </span>
          </div>

          <div class="preview-area">
            <Transition name="qr-fade" mode="out-in">
              <div v-if="!hasContent" key="empty" class="preview-empty">
                <QrCode class="h-16 w-16 empty-icon" />
                <p>Escribe algo para generar el QR</p>
              </div>
              <div v-else-if="generating" key="loading" class="preview-loading">
                <div class="spinner" />
                <p>Generando…</p>
              </div>
              <div v-else-if="error" key="error" class="preview-error">
                <AlertCircle class="h-10 w-10" />
                <p>{{ error }}</p>
              </div>
              <img v-else key="img" :src="qrDataUrl" class="qr-canvas" alt="Código QR generado" />
            </Transition>
          </div>

          <!-- Info del QR generado -->
          <div v-if="hasContent && !error && !generating" class="qr-info">
            <div class="info-item">
              <span class="info-label">Tamaño</span>
              <span class="info-value">{{ size }}×{{ size }} px</span>
            </div>
            <div class="info-item">
              <span class="info-label">Corrección</span>
              <span class="info-value">{{ errorCorrectionLevel }}</span>
            </div>
            <div class="info-item">
              <span class="info-label">Chars</span>
              <span class="info-value">{{ qrText.length }}</span>
            </div>
          </div>
        </div>

        <!-- Historial reciente -->
        <div v-if="history.length > 0" class="history-card">
          <div class="history-header">
            <Clock class="h-4 w-4" />
            <span>Recientes</span>
            <button class="clear-btn" @click="clearHistory" title="Limpiar historial">
              <Trash2 class="h-3.5 w-3.5" />
            </button>
          </div>
          <ul class="history-list">
            <li
              v-for="(item, i) in history"
              :key="i"
              class="history-item"
              @click="loadFromHistory(item)"
              :title="item.text"
            >
              <span class="history-text">{{ truncate(item.text, 45) }}</span>
              <span class="history-time">{{ item.time }}</span>
            </li>
          </ul>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import QRCode from 'qrcode'
import {
  QrCode, Download, FileCode, Copy, Check, Eye,
  AlertCircle, Clock, Trash2
} from 'lucide-vue-next'

// ─── State ────────────────────────────────────────────────────────────────────
const qrText = ref('')
const darkColor = ref('#000000')
const lightColor = ref('#ffffff')
const size = ref(300)
const margin = ref(2)
const errorCorrectionLevel = ref<'L' | 'M' | 'Q' | 'H'>('M')
const filename = ref('codigo-qr')
const generating = ref(false)
const error = ref('')
const copied = ref(false)
const activePreset = ref('')

// Data URL del QR generado (enfoque sin ref de DOM)
const qrDataUrl = ref('')

// ─── Historial ────────────────────────────────────────────────────────────────
interface HistoryItem { text: string; time: string }
const HISTORY_KEY = 'qr-history'
const history = ref<HistoryItem[]>(JSON.parse(localStorage.getItem(HISTORY_KEY) || '[]'))

function saveHistory(text: string) {
  const now = new Date()
  const time = now.toLocaleTimeString('es-MX', { hour: '2-digit', minute: '2-digit' })
  const entry: HistoryItem = { text, time }
  history.value = [entry, ...history.value.filter(h => h.text !== text)].slice(0, 10)
  localStorage.setItem(HISTORY_KEY, JSON.stringify(history.value))
}

function clearHistory() {
  history.value = []
  localStorage.removeItem(HISTORY_KEY)
}

function loadFromHistory(item: HistoryItem) {
  qrText.value = item.text
  generate()
}

// ─── Plantillas ───────────────────────────────────────────────────────────────
import { Link, Hash, Phone, Mail, MapPin, Package } from 'lucide-vue-next'

const presets = [
  {
    label: 'URL',
    icon: Link,
    text: 'https://sgdesigns.mx',
    placeholder: 'https://tu-sitio.com'
  },
  {
    label: 'WhatsApp',
    icon: Phone,
    text: 'https://wa.me/521234567890?text=Hola%20SGDesigns',
    placeholder: ''
  },
  {
    label: 'Email',
    icon: Mail,
    text: 'mailto:contacto@sgdesigns.mx?subject=Consulta&body=Hola',
    placeholder: ''
  },
  {
    label: 'Pedido',
    icon: Package,
    text: 'Pedido #001\nCliente: Juan García\nFecha: 2025-05-01\nTotal: $1,500.00 MXN',
    placeholder: ''
  },
  {
    label: 'Ubicación',
    icon: MapPin,
    text: 'geo:19.432608,-99.133209?q=CDMX',
    placeholder: ''
  },
  {
    label: 'Texto libre',
    icon: Hash,
    text: '',
    placeholder: 'Escribe tu propio contenido…'
  }
]

function applyPreset(preset: typeof presets[number]) {
  activePreset.value = preset.label
  qrText.value = preset.text
  generate()
}

// ─── Computed ────────────────────────────────────────────────────────────────
const hasContent = computed(() => qrText.value.trim().length > 0)

// ─── Generación de QR ─────────────────────────────────────────────────────────
let debounceTimer: ReturnType<typeof setTimeout>

function debouncedGenerate() {
  clearTimeout(debounceTimer)
  debounceTimer = setTimeout(generate, 350)
}

async function generate() {
  if (!hasContent.value) return

  generating.value = true
  error.value = ''
  qrDataUrl.value = ''

  try {
    // toDataURL no necesita ningún elemento del DOM — elimina el race condition
    const url = await QRCode.toDataURL(qrText.value, {
      width: size.value,
      margin: margin.value,
      color: {
        dark: darkColor.value,
        light: lightColor.value
      },
      errorCorrectionLevel: errorCorrectionLevel.value,
      type: 'image/png'
    })
    qrDataUrl.value = url
    saveHistory(qrText.value)
  } catch (e: any) {
    error.value = e?.message || 'Error al generar el QR. El contenido puede ser demasiado largo.'
  } finally {
    generating.value = false
  }
}

// ─── Descarga PNG ─────────────────────────────────────────────────────────────
function downloadPNG() {
  if (!qrDataUrl.value) return
  const link = document.createElement('a')
  link.download = `${filename.value || 'codigo-qr'}.png`
  link.href = qrDataUrl.value
  link.click()
}

// ─── Descarga SVG ─────────────────────────────────────────────────────────────
async function downloadSVG() {
  try {
    const svg = await QRCode.toString(qrText.value, {
      type: 'svg',
      margin: margin.value,
      color: { dark: darkColor.value, light: lightColor.value },
      errorCorrectionLevel: errorCorrectionLevel.value
    })
    const blob = new Blob([svg], { type: 'image/svg+xml' })
    const url = URL.createObjectURL(blob)
    const link = document.createElement('a')
    link.download = `${filename.value || 'codigo-qr'}.svg`
    link.href = url
    link.click()
    URL.revokeObjectURL(url)
  } catch (e: any) {
    error.value = e?.message || 'Error al generar SVG'
  }
}

// ─── Copiar al portapapeles ───────────────────────────────────────────────────
async function copyToClipboard() {
  if (!qrDataUrl.value) return
  try {
    // Convertir data URL a Blob
    const res = await fetch(qrDataUrl.value)
    const blob = await res.blob()
    await navigator.clipboard.write([
      new ClipboardItem({ 'image/png': blob })
    ])
    copied.value = true
    setTimeout(() => { copied.value = false }, 2000)
  } catch {
    // Fallback: abrir en nueva pestaña
    window.open(qrDataUrl.value, '_blank')
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────
function truncate(str: string, len: number) {
  return str.length > len ? str.slice(0, len) + '…' : str
}

</script>

<style scoped>
/* ─── Layout ──────────────────────────────────────────────────────────────── */
.qr-page {
  max-width: 1100px;
  margin: 0 auto;
  padding: 8px 0 32px;
  font-family: 'Montserrat', system-ui, sans-serif;
}

.qr-header {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 28px;
}

.qr-header-icon {
  width: 52px;
  height: 52px;
  border-radius: 14px;
  background: linear-gradient(135deg, #0ea5e9, #0284c7);
  color: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
  box-shadow: 0 4px 16px rgba(14, 165, 233, 0.35);
  flex-shrink: 0;
}

.qr-title {
  font-size: 22px;
  font-weight: 800;
  color: #0f172a;
  margin: 0 0 2px;
  line-height: 1.2;
}

:is(.dark) .qr-title { color: #e2e8f0; }

.qr-subtitle {
  font-size: 13px;
  color: #64748b;
  margin: 0;
}

:is(.dark) .qr-subtitle { color: #94a3b8; }

.qr-layout {
  display: grid;
  grid-template-columns: 1fr 420px;
  gap: 24px;
  align-items: start;
}

/* ─── Panel configuración ─────────────────────────────────────────────────── */
.qr-panel {
  background: #fff;
  border-radius: 16px;
  border: 1px solid #e8eef5;
  padding: 24px;
  display: flex;
  flex-direction: column;
  gap: 4px;
  box-shadow: 0 2px 12px rgba(10, 30, 60, 0.06);
}

:is(.dark) .qr-panel {
  background: #0f1729;
  border-color: #1e293b;
  box-shadow: 0 2px 12px rgba(0, 0, 0, 0.3);
}

.panel-section {
  padding: 14px 0;
  border-bottom: 1px solid #f1f5fb;
}

:is(.dark) .panel-section { border-bottom-color: #1e293b; }

.panel-section:last-child { border-bottom: none; }

.panel-section.two-cols {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
}

.field-label {
  display: block;
  font-size: 12px;
  font-weight: 700;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-bottom: 8px;
}

:is(.dark) .field-label { color: #94a3b8; }

/* ─── Inputs ──────────────────────────────────────────────────────────────── */
.qr-textarea,
.qr-input,
.qr-select {
  width: 100%;
  box-sizing: border-box;
  padding: 10px 12px;
  border: 1px solid #dde3ee;
  border-radius: 10px;
  font-family: inherit;
  font-size: 14px;
  color: #0f172a;
  background: #f8fafc;
  transition: border-color 0.15s, box-shadow 0.15s;
  outline: none;
}

:is(.dark) .qr-textarea,
:is(.dark) .qr-input,
:is(.dark) .qr-select {
  background: #0c1222;
  border-color: #334155;
  color: #e2e8f0;
}

.qr-textarea:focus,
.qr-input:focus,
.qr-select:focus {
  border-color: #0ea5e9;
  box-shadow: 0 0 0 3px rgba(14, 165, 233, 0.12);
}

.qr-textarea {
  resize: vertical;
  min-height: 90px;
}

.char-count {
  font-size: 11px;
  color: #94a3b8;
  margin-top: 4px;
  text-align: right;
}

.char-count.danger { color: #f59e0b; }
.danger-text { color: #ef4444; }

/* ─── Presets ─────────────────────────────────────────────────────────────── */
.presets-grid {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.preset-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 7px 14px;
  border-radius: 999px;
  border: 1.5px solid #dde3ee;
  background: #f8fafc;
  color: #334155;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.15s;
  font-family: inherit;
}

:is(.dark) .preset-btn {
  border-color: #334155;
  background: #1e293b;
  color: #94a3b8;
}

.preset-btn:hover {
  border-color: #0ea5e9;
  color: #0284c7;
  background: #eff6ff;
}

:is(.dark) .preset-btn:hover {
  border-color: #38bdf8;
  color: #38bdf8;
  background: #0c2d5b;
}

.preset-btn.active {
  background: linear-gradient(135deg, #0ea5e9, #0284c7);
  color: #fff;
  border-color: transparent;
  box-shadow: 0 3px 10px rgba(14, 165, 233, 0.3);
}

/* ─── Colores ─────────────────────────────────────────────────────────────── */
.color-row {
  display: flex;
  gap: 16px;
}

.color-field {
  display: flex;
  flex-direction: column;
  gap: 6px;
  flex: 1;
}

.color-label {
  font-size: 12px;
  color: #94a3b8;
  font-weight: 600;
}

.color-pick-wrap {
  display: flex;
  align-items: center;
  gap: 10px;
  border: 1px solid #dde3ee;
  border-radius: 10px;
  padding: 6px 12px;
  background: #f8fafc;
}

:is(.dark) .color-pick-wrap {
  border-color: #334155;
  background: #0c1222;
}

.color-input {
  width: 34px;
  height: 34px;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  padding: 2px;
  background: transparent;
}

.color-hex {
  font-family: 'Courier New', monospace;
  font-size: 13px;
  color: #475569;
  font-weight: 600;
}

:is(.dark) .color-hex { color: #94a3b8; }

/* ─── Acciones ────────────────────────────────────────────────────────────── */
.actions-row {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}

.action-btn {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  padding: 10px 18px;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
  border: none;
  font-family: inherit;
  transition: all 0.15s;
}

.action-btn:disabled {
  opacity: 0.45;
  cursor: not-allowed;
}

.action-btn.primary {
  background: linear-gradient(135deg, #0ea5e9, #0284c7);
  color: #fff;
  box-shadow: 0 3px 12px rgba(14, 165, 233, 0.3);
}

.action-btn.primary:hover:not(:disabled) {
  transform: translateY(-1px);
  box-shadow: 0 6px 18px rgba(14, 165, 233, 0.4);
}

.action-btn.secondary {
  background: #eff6ff;
  color: #0284c7;
  border: 1.5px solid #bae6fd;
}

:is(.dark) .action-btn.secondary {
  background: #0c2d5b;
  color: #38bdf8;
  border-color: #1e4d8c;
}

.action-btn.secondary:hover:not(:disabled) {
  background: #dbeafe;
}

.action-btn.ghost {
  background: #f8fafc;
  color: #475569;
  border: 1.5px solid #dde3ee;
}

:is(.dark) .action-btn.ghost {
  background: #1e293b;
  color: #94a3b8;
  border-color: #334155;
}

.action-btn.ghost:hover:not(:disabled) {
  background: #f1f5f9;
}

/* ─── Preview ─────────────────────────────────────────────────────────────── */
.qr-preview-panel {
  display: flex;
  flex-direction: column;
  gap: 16px;
  position: sticky;
  top: 16px;
}

.preview-card {
  background: #fff;
  border-radius: 16px;
  border: 1px solid #e8eef5;
  overflow: hidden;
  box-shadow: 0 4px 20px rgba(10, 30, 60, 0.08);
}

:is(.dark) .preview-card {
  background: #0f1729;
  border-color: #1e293b;
  box-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
}

.preview-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 16px;
  border-bottom: 1px solid #f1f5fb;
}

:is(.dark) .preview-header { border-bottom-color: #1e293b; }

.preview-label {
  font-size: 12px;
  font-weight: 700;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

:is(.dark) .preview-label { color: #94a3b8; }

.preview-badge {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 11px;
  font-weight: 700;
  color: #16a34a;
  background: #f0fdf4;
  padding: 3px 10px;
  border-radius: 999px;
}

:is(.dark) .preview-badge {
  color: #4ade80;
  background: #052e16;
}

.preview-area {
  min-height: 300px;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}

.preview-empty,
.preview-loading,
.preview-error {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  text-align: center;
}

.preview-empty p,
.preview-loading p,
.preview-error p {
  font-size: 13px;
  color: #94a3b8;
  margin: 0;
}

:is(.dark) .preview-empty p,
:is(.dark) .preview-loading p { color: #64748b; }

.empty-icon { color: #cbd5e1; }
:is(.dark) .empty-icon { color: #334155; }

.preview-error { color: #ef4444; }
.preview-error p { color: #ef4444; font-size: 13px; }

.qr-canvas {
  border-radius: 8px;
  max-width: 100%;
  height: auto !important;
  display: block;
}

.spinner {
  width: 36px;
  height: 36px;
  border: 3px solid #e2e8f0;
  border-top-color: #0ea5e9;
  border-radius: 50%;
  animation: spin 0.7s linear infinite;
}

@keyframes spin { to { transform: rotate(360deg); } }

/* ─── QR Info ─────────────────────────────────────────────────────────────── */
.qr-info {
  display: flex;
  justify-content: space-around;
  padding: 12px 16px;
  border-top: 1px solid #f1f5fb;
  background: #f8fafc;
}

:is(.dark) .qr-info {
  border-top-color: #1e293b;
  background: #0c1222;
}

.info-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
}

.info-label {
  font-size: 10px;
  font-weight: 700;
  color: #94a3b8;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}

.info-value {
  font-size: 13px;
  font-weight: 700;
  color: #334155;
}

:is(.dark) .info-value { color: #e2e8f0; }

/* ─── Historial ───────────────────────────────────────────────────────────── */
.history-card {
  background: #fff;
  border-radius: 16px;
  border: 1px solid #e8eef5;
  overflow: hidden;
  box-shadow: 0 2px 10px rgba(10, 30, 60, 0.06);
}

:is(.dark) .history-card {
  background: #0f1729;
  border-color: #1e293b;
  box-shadow: 0 2px 10px rgba(0, 0, 0, 0.3);
}

.history-header {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 14px;
  font-size: 12px;
  font-weight: 700;
  color: #64748b;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  border-bottom: 1px solid #f1f5fb;
}

:is(.dark) .history-header {
  color: #94a3b8;
  border-bottom-color: #1e293b;
}

.clear-btn {
  margin-left: auto;
  background: transparent;
  border: none;
  padding: 4px;
  border-radius: 6px;
  cursor: pointer;
  color: #94a3b8;
  display: flex;
  align-items: center;
  transition: background 0.12s, color 0.12s;
}

.clear-btn:hover {
  background: #fee2e2;
  color: #dc2626;
}

.history-list {
  list-style: none;
  margin: 0;
  padding: 0;
}

.history-item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  padding: 9px 14px;
  cursor: pointer;
  border-bottom: 1px solid #f8fafc;
  transition: background 0.12s;
}

:is(.dark) .history-item { border-bottom-color: #1e293b; }

.history-item:last-child { border-bottom: none; }

.history-item:hover { background: #f1f5f9; }

:is(.dark) .history-item:hover { background: #1e293b; }

.history-text {
  font-size: 12px;
  color: #334155;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
  flex: 1;
}

:is(.dark) .history-text { color: #94a3b8; }

.history-time {
  font-size: 11px;
  color: #94a3b8;
  flex-shrink: 0;
}

/* ─── Transiciones ────────────────────────────────────────────────────────── */
.qr-fade-enter-active,
.qr-fade-leave-active { transition: opacity 0.2s ease, transform 0.2s ease; }

.qr-fade-enter-from { opacity: 0; transform: scale(0.95); }
.qr-fade-leave-to { opacity: 0; transform: scale(1.02); }

/* ─── Responsive ──────────────────────────────────────────────────────────── */
@media (max-width: 900px) {
  .qr-layout {
    grid-template-columns: 1fr;
  }
  .qr-preview-panel {
    position: static;
    order: -1;
  }
}

@media (max-width: 600px) {
  .qr-header { flex-direction: column; align-items: flex-start; }
  .panel-section.two-cols { grid-template-columns: 1fr; }
  .actions-row { flex-direction: column; }
  .action-btn { justify-content: center; }
}
</style>
