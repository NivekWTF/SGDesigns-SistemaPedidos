<template>
  <div class="lc-root">
    <!-- ── HEADER ── -->
    <div class="lc-header">
      <div class="lc-header-icon">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="4" width="20" height="16" rx="2"/><path d="M7 8h10M7 12h6"/></svg>
      </div>
      <div>
        <h1 class="lc-title">Calculador de Etiquetas</h1>
        <p class="lc-subtitle">Calcula cuantas etiquetas caben en un tabloide</p>
      </div>
    </div>

    <!-- ── MAIN LAYOUT ── -->
    <div class="lc-body">
      <!-- ── CONTROLS PANEL ── -->
      <div class="controls-panel">

        <!-- Tamano de hoja -->
        <div class="section-block">
          <div class="section-label">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/></svg>
            Tamano de Hoja (Tabloide)
          </div>
          <div class="paper-grid">
            <button
              v-for="p in PAPER_SIZES" :key="p.id"
              class="paper-btn"
              :class="{ active: paperSize === p.id }"
              @click="paperSize = p.id"
            >
              <span class="paper-name">{{ p.label }}</span>
              <span class="paper-dim">{{ p.wIn }}" x {{ p.hIn }}"</span>
            </button>
          </div>
        </div>

        <!-- Orientacion -->
        <div class="section-block">
          <div class="section-label">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2"/><path d="M3 9h18M9 21V9"/></svg>
            Orientacion
          </div>
          <div class="orient-grid">
            <button class="orient-btn" :class="{ active: landscape === false }" @click="landscape = false">
              <svg class="orient-icon portrait" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="4" y="2" width="16" height="20" rx="2"/></svg>
              <span>Vertical ({{ currentPaper.wIn }}" x {{ currentPaper.hIn }}")</span>
            </button>
            <button class="orient-btn" :class="{ active: landscape === true }" @click="landscape = true">
              <svg class="orient-icon landscape" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="2" y="4" width="20" height="16" rx="2"/></svg>
              <span>Horizontal ({{ currentPaper.hIn }}" x {{ currentPaper.wIn }}")</span>
            </button>
          </div>
        </div>

        <!-- Unidades y DPI -->
        <div class="section-block">
          <div class="section-label">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 12h4l3-9 4 18 3-9h4"/></svg>
            Unidades y Resolucion
          </div>
          <div class="two-col">
            <div class="field-group">
              <label class="field-label">Unidades</label>
              <select v-model="unit" class="ctrl-select">
                <option value="in">Pulgadas (in)</option>
                <option value="mm">Milimetros (mm)</option>
                <option value="cm">Centimetros (cm)</option>
              </select>
            </div>
            <div class="field-group">
              <label class="field-label">DPI</label>
              <input v-model.number="dpi" type="number" min="72" step="1" class="ctrl-input" />
            </div>
          </div>
        </div>

        <!-- Tamano de etiqueta -->
        <div class="section-block">
          <div class="section-label">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"/><line x1="7" y1="7" x2="7.01" y2="7"/></svg>
            Tamano de la Etiqueta ({{ unit }})
          </div>
          <div class="two-col">
            <div class="field-group">
              <label class="field-label">Ancho</label>
              <input v-model.number="labelWidth" type="number" step="0.01" min="0.1" class="ctrl-input" />
            </div>
            <div class="field-group">
              <label class="field-label">Alto</label>
              <input v-model.number="labelHeight" type="number" step="0.01" min="0.1" class="ctrl-input" />
            </div>
          </div>
        </div>

        <!-- Gaps -->
        <div class="section-block">
          <div class="section-label">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="8" y1="6" x2="21" y2="6"/><line x1="8" y1="12" x2="21" y2="12"/><line x1="8" y1="18" x2="21" y2="18"/><line x1="3" y1="6" x2="3.01" y2="6"/><line x1="3" y1="12" x2="3.01" y2="12"/><line x1="3" y1="18" x2="3.01" y2="18"/></svg>
            Gaps / Sangria ({{ unit }})
          </div>
          <div class="two-col">
            <div class="field-group">
              <label class="field-label">Gap Horizontal</label>
              <input v-model.number="hGap" type="number" step="0.01" min="0" class="ctrl-input" />
            </div>
            <div class="field-group">
              <label class="field-label">Gap Vertical</label>
              <input v-model.number="vGap" type="number" step="0.01" min="0" class="ctrl-input" />
            </div>
          </div>
        </div>

        <!-- Margenes -->
        <div class="section-block">
          <div class="section-label">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="1"/><path d="M9 3v18M15 3v18M3 9h18M3 15h18"/></svg>
            Margenes ({{ unit }})
          </div>
          <div class="four-col">
            <div class="field-group">
              <label class="field-label">Izq</label>
              <input v-model.number="marginLeft" type="number" step="0.01" min="0" class="ctrl-input" />
            </div>
            <div class="field-group">
              <label class="field-label">Sup</label>
              <input v-model.number="marginTop" type="number" step="0.01" min="0" class="ctrl-input" />
            </div>
            <div class="field-group">
              <label class="field-label">Der</label>
              <input v-model.number="marginRight" type="number" step="0.01" min="0" class="ctrl-input" />
            </div>
            <div class="field-group">
              <label class="field-label">Inf</label>
              <input v-model.number="marginBottom" type="number" step="0.01" min="0" class="ctrl-input" />
            </div>
          </div>
        </div>

        <!-- Imagen -->
        <div class="section-block">
          <div class="section-label">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="3" width="18" height="18" rx="2"/><circle cx="8.5" cy="8.5" r="1.5"/><polyline points="21 15 16 10 5 21"/></svg>
            Imagen de Etiqueta (opcional)
          </div>
          <div class="field-group">
            <label class="field-label">URL de imagen</label>
            <input v-model="imageUrl" placeholder="https://..." class="ctrl-input" />
          </div>
          <div class="field-group" style="margin-top:8px">
            <label class="field-label">Subir archivo</label>
            <input type="file" @change="onFile" accept="image/*" class="ctrl-file" />
          </div>
        </div>

        <!-- Acciones -->
        <div class="actions-block">
          <button class="btn-calc" @click="generateGrid">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="3" width="20" height="14" rx="2"/><path d="M8 21h8M12 17v4"/></svg>
            Calcular y Generar
          </button>
          <button class="btn-clear" @click="clearGrid">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6"/><path d="M9 6V4h6v2"/></svg>
            Limpiar
          </button>
        </div>

        <!-- Resultados -->
        <div class="results-block" v-if="cols > 0 || rows > 0">
          <div class="result-item">
            <span class="result-label">Columnas</span>
            <span class="result-value">{{ cols }}</span>
          </div>
          <div class="result-item">
            <span class="result-label">Filas</span>
            <span class="result-value">{{ rows }}</span>
          </div>
          <div class="result-item total">
            <span class="result-label">Total Etiquetas</span>
            <span class="result-value accent">{{ total }}</span>
          </div>
        </div>

      </div>

      <!-- ── PREVIEW PANEL ── -->
      <div class="preview-panel">
        <div class="preview-header">
          <span class="preview-tag">Vista previa &mdash; {{ currentPaper.label }} {{ landscape ? 'Horizontal' : 'Vertical' }}</span>
          <span class="preview-dim">{{ pageW }}" x {{ pageH }}"</span>
        </div>
        <div class="preview-scroll">
          <template v-if="cells.length > 0">
            <div class="page" :style="pageStyle">
              <div class="page-inner" :style="innerStyle">
                <div v-for="(_, i) in cells" :key="i" class="label-cell" :style="cellStyle">
                  <img v-if="cellImage" :src="cellImage" class="cell-image" />
                  <span v-else class="cell-num">{{ i + 1 }}</span>
                </div>
              </div>
            </div>
          </template>
          <div v-else class="preview-empty">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"><rect x="2" y="4" width="20" height="16" rx="2"/><path d="M7 8h10M7 12h6"/></svg>
            <p>Configura los parametros y presiona <strong>Calcular y Generar</strong></p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'

// Paper sizes
interface PaperDef { id: string; label: string; wIn: number; hIn: number }

const PAPER_SIZES: PaperDef[] = [
  { id: '12x18', label: 'Tabloide 12x18',  wIn: 12, hIn: 18 },
  { id: '13x19', label: 'Super B 13x19', wIn: 13, hIn: 19 },
]

const paperSize = ref<string>('12x18')
const landscape  = ref(false)

const currentPaper = computed<PaperDef>(
  () => PAPER_SIZES.find(p => p.id === paperSize.value) ?? PAPER_SIZES[0]
)

const pageW = computed(() => landscape.value ? currentPaper.value.hIn : currentPaper.value.wIn)
const pageH = computed(() => landscape.value ? currentPaper.value.wIn : currentPaper.value.hIn)

// Inputs
const unit        = ref<'in'|'mm'|'cm'>('in')
const dpi         = ref(300)
const labelWidth  = ref(2.0)
const labelHeight = ref(1.0)
const hGap        = ref(0.125)
const vGap        = ref(0.125)
const marginLeft   = ref(0.25)
const marginTop    = ref(0.25)
const marginRight  = ref(0.25)
const marginBottom = ref(0.25)

const imageUrl  = ref('')
const cellImage = ref<string | null>(null)

// Results
const cols  = ref(0)
const rows  = ref(0)
const total = computed(() => cols.value * rows.value)
const cells = ref<number[]>([])

// Helpers
function toInches(val: number, u: 'in'|'mm'|'cm') {
  if (u === 'in') return val
  if (u === 'mm') return val / 25.4
  return val / 2.54
}

function calculate() {
  const w  = pageW.value
  const h  = pageH.value
  const ml = toInches(marginLeft.value,   unit.value)
  const mr = toInches(marginRight.value,  unit.value)
  const mt = toInches(marginTop.value,    unit.value)
  const mb = toInches(marginBottom.value, unit.value)
  const lw = toInches(labelWidth.value,   unit.value)
  const lh = toInches(labelHeight.value,  unit.value)
  const hg = toInches(hGap.value,         unit.value)
  const vg = toInches(vGap.value,         unit.value)

  const availW = w - ml - mr
  const availH = h - mt - mb

  cols.value = Math.max(0, Math.floor((availW + hg) / (lw + hg)))
  rows.value = Math.max(0, Math.floor((availH + vg) / (lh + vg)))
}

function generateGrid() {
  calculate()
  cells.value = Array.from({ length: cols.value * rows.value }, (_, i) => i)
  if (imageUrl.value) cellImage.value = imageUrl.value
}

function clearGrid() {
  cells.value  = []
  cols.value   = 0
  rows.value   = 0
  cellImage.value = null
}

function onFile(e: Event) {
  const input = e.target as HTMLInputElement
  const f = input.files?.[0]
  if (!f) return
  const reader = new FileReader()
  reader.onload = () => { cellImage.value = String(reader.result) }
  reader.readAsDataURL(f)
}

// Preview styles
const MAX_PREVIEW_W = 820

const previewScale = computed(() => {
  const px = pageW.value * dpi.value
  return Math.min(1, MAX_PREVIEW_W / px)
})

const pageStyle = computed(() => ({
  width:  `${Math.round(pageW.value * dpi.value * previewScale.value)}px`,
  height: `${Math.round(pageH.value * dpi.value * previewScale.value)}px`,
}))

const innerStyle = computed(() => {
  const s   = previewScale.value
  const d   = dpi.value
  const lw  = toInches(labelWidth.value,   unit.value)
  const hg  = toInches(hGap.value,         unit.value)
  const vg  = toInches(vGap.value,         unit.value)
  const ml  = toInches(marginLeft.value,   unit.value)
  const mt  = toInches(marginTop.value,    unit.value)
  const mr  = toInches(marginRight.value,  unit.value)
  const mb  = toInches(marginBottom.value, unit.value)
  return {
    paddingTop:    `${Math.round(mt * d * s)}px`,
    paddingLeft:   `${Math.round(ml * d * s)}px`,
    paddingRight:  `${Math.round(mr * d * s)}px`,
    paddingBottom: `${Math.round(mb * d * s)}px`,
    gap: `${Math.round(vg * d * s)}px ${Math.round(hg * d * s)}px`,
    gridTemplateColumns: `repeat(${Math.max(1, cols.value)}, ${Math.round(lw * d * s)}px)`,
  }
})

const cellStyle = computed(() => {
  const s  = previewScale.value
  const d  = dpi.value
  const lw = toInches(labelWidth.value,  unit.value)
  const lh = toInches(labelHeight.value, unit.value)
  return {
    width:  `${Math.round(lw * d * s)}px`,
    height: `${Math.round(lh * d * s)}px`,
  }
})
</script>

<style scoped>
/* Root & Header */
.lc-root {
  display: flex;
  flex-direction: column;
  gap: 0;
  height: 100%;
  background: var(--bg, #f0f4f8);
}

.lc-header {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 20px 24px 16px;
  background: #fff;
  border-bottom: 1px solid #e2eaf0;
  flex-shrink: 0;
}
.lc-header-icon {
  width: 42px; height: 42px;
  background: linear-gradient(135deg, #059669 0%, #0891b2 100%);
  border-radius: 10px;
  display: flex; align-items: center; justify-content: center;
  color: #fff;
  flex-shrink: 0;
}
.lc-header-icon svg { width: 22px; height: 22px; }
.lc-title { margin: 0; font-size: 1.25rem; font-weight: 700; color: #0f172a; }
.lc-subtitle { margin: 2px 0 0; font-size: 0.83rem; color: #64748b; }

/* Body Layout */
.lc-body {
  display: flex;
  flex: 1;
  overflow: hidden;
  min-height: 0;
}

/* Controls Panel */
.controls-panel {
  width: 340px;
  min-width: 300px;
  flex-shrink: 0;
  background: #fff;
  border-right: 1px solid #e2eaf0;
  overflow-y: auto;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 0;
}

.section-block {
  background: #f8fafc;
  border: 1px solid #e2eaf0;
  border-radius: 10px;
  padding: 12px 14px;
  margin-bottom: 8px;
}

.section-label {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 0.78rem;
  font-weight: 700;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: #475569;
  margin-bottom: 10px;
}
.section-label svg { width: 14px; height: 14px; flex-shrink: 0; }

/* Paper size grid */
.paper-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}
.paper-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
  padding: 10px 8px;
  border: 2px solid #e2eaf0;
  border-radius: 8px;
  background: #fff;
  cursor: pointer;
  transition: all 0.15s;
}
.paper-btn:hover { border-color: #059669; background: #f0fdf4; }
.paper-btn.active { border-color: #059669; background: #ecfdf5; }
.paper-name { font-weight: 700; font-size: 0.82rem; color: #0f172a; }
.paper-dim  { font-size: 0.75rem; color: #64748b; }
.paper-btn.active .paper-name { color: #065f46; }

/* Orientation */
.orient-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 8px;
}
.orient-btn {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
  padding: 10px 6px;
  border: 2px solid #e2eaf0;
  border-radius: 8px;
  background: #fff;
  cursor: pointer;
  transition: all 0.15s;
  font-size: 0.75rem;
  color: #475569;
}
.orient-btn:hover { border-color: #0891b2; background: #f0f9ff; }
.orient-btn.active { border-color: #0891b2; background: #e0f2fe; color: #0c4a6e; font-weight: 700; }
.orient-icon { stroke: #64748b; }
.orient-btn.active .orient-icon { stroke: #0369a1; }
.orient-icon.portrait  { width: 24px; height: 30px; }
.orient-icon.landscape { width: 30px; height: 24px; }

/* Two & four column grids */
.two-col  { display: grid; grid-template-columns: 1fr 1fr; gap: 8px; }
.four-col { display: grid; grid-template-columns: 1fr 1fr 1fr 1fr; gap: 6px; }

.field-group { display: flex; flex-direction: column; gap: 3px; }
.field-label { font-size: 0.72rem; font-weight: 600; color: #64748b; }

.ctrl-input, .ctrl-select {
  width: 100%;
  box-sizing: border-box;
  padding: 6px 8px;
  border: 1px solid #cbd5e1;
  border-radius: 6px;
  font-size: 0.84rem;
  background: #fff;
  color: #0f172a;
  transition: border-color 0.15s;
}
.ctrl-input:focus, .ctrl-select:focus { outline: none; border-color: #059669; box-shadow: 0 0 0 3px rgba(5,150,105,0.12); }

.ctrl-file { font-size: 0.78rem; color: #475569; }

/* Actions */
.actions-block {
  display: flex;
  gap: 8px;
  margin-top: 4px;
  margin-bottom: 8px;
}
.btn-calc {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 7px;
  padding: 10px 12px;
  background: linear-gradient(135deg, #059669 0%, #0891b2 100%);
  color: #fff;
  border: none;
  border-radius: 8px;
  font-weight: 700;
  font-size: 0.88rem;
  cursor: pointer;
  transition: opacity 0.15s, transform 0.1s;
}
.btn-calc:hover { opacity: 0.92; }
.btn-calc:active { transform: scale(0.98); }
.btn-calc svg { width: 16px; height: 16px; }

.btn-clear {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 10px 12px;
  background: transparent;
  border: 1px solid #e2eaf0;
  border-radius: 8px;
  font-size: 0.84rem;
  color: #64748b;
  cursor: pointer;
  transition: background 0.15s, border-color 0.15s;
}
.btn-clear:hover { background: #fef2f2; border-color: #fca5a5; color: #dc2626; }
.btn-clear svg { width: 15px; height: 15px; }

/* Results */
.results-block {
  display: flex;
  gap: 8px;
  background: linear-gradient(135deg, #ecfdf5, #e0f2fe);
  border: 1px solid #a7f3d0;
  border-radius: 10px;
  padding: 12px;
  margin-bottom: 8px;
}
.result-item {
  flex: 1;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
}
.result-item.total { border-left: 1px solid #a7f3d0; padding-left: 8px; }
.result-label { font-size: 0.7rem; font-weight: 600; text-transform: uppercase; letter-spacing: 0.05em; color: #047857; }
.result-value { font-size: 1.5rem; font-weight: 800; color: #065f46; }
.result-value.accent { color: #059669; font-size: 1.8rem; }

/* Preview Panel */
.preview-panel {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  min-width: 0;
}

.preview-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 18px;
  background: #f8fafc;
  border-bottom: 1px solid #e2eaf0;
  flex-shrink: 0;
}
.preview-tag {
  font-size: 0.8rem;
  font-weight: 700;
  color: #475569;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
.preview-dim {
  font-size: 0.78rem;
  color: #94a3b8;
  font-weight: 600;
}

.preview-scroll {
  flex: 1;
  overflow: auto;
  display: flex;
  align-items: flex-start;
  justify-content: center;
  padding: 24px;
  background: repeating-linear-gradient(45deg, #e8edf2 0px, #e8edf2 1px, #f0f4f8 1px, #f0f4f8 10px);
}

.page {
  background: #fff;
  box-shadow: 0 4px 32px rgba(2,6,23,0.14), 0 1px 4px rgba(2,6,23,0.08);
  border-radius: 2px;
  flex-shrink: 0;
}
.page-inner {
  display: grid;
  grid-auto-rows: auto;
  align-content: start;
  width: 100%;
  height: 100%;
  box-sizing: border-box;
}
.label-cell {
  border: 1px dashed #c7d6e0;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  overflow: hidden;
  background: #fafcff;
}
.label-cell:hover { background: #f0fdf4; }
.cell-image { position: absolute; inset: 0; width: 100%; height: 100%; object-fit: cover; opacity: 0.9; }
.cell-num { font-size: 10px; color: #94a3b8; z-index: 2; font-weight: 700; }

/* Empty state */
.preview-empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 12px;
  color: #94a3b8;
  padding: 60px 20px;
  width: 100%;
}
.preview-empty svg { width: 56px; height: 56px; }
.preview-empty p { margin: 0; font-size: 0.9rem; text-align: center; max-width: 280px; }
.preview-empty strong { color: #059669; }

/* Dark Mode */
:is(.dark) .lc-root { background: #0b1120; }
:is(.dark) .lc-header { background: #111c2e; border-color: #1e293b; }
:is(.dark) .lc-title { color: #e2e8f0; }
:is(.dark) .lc-subtitle { color: #64748b; }
:is(.dark) .controls-panel { background: #111c2e; border-color: #1e293b; }
:is(.dark) .section-block { background: #0f1729; border-color: #1e293b; }
:is(.dark) .section-label { color: #94a3b8; }
:is(.dark) .paper-btn { background: #111c2e; border-color: #1e293b; }
:is(.dark) .paper-btn:hover { border-color: #059669; background: #0a1f17; }
:is(.dark) .paper-btn.active { border-color: #059669; background: #052e16; }
:is(.dark) .paper-name { color: #e2e8f0; }
:is(.dark) .paper-btn.active .paper-name { color: #6ee7b7; }
:is(.dark) .orient-btn { background: #111c2e; border-color: #1e293b; color: #94a3b8; }
:is(.dark) .orient-btn:hover { border-color: #0891b2; background: #082536; }
:is(.dark) .orient-btn.active { border-color: #0891b2; background: #0c2d44; color: #7dd3fc; }
:is(.dark) .ctrl-input,
:is(.dark) .ctrl-select { background: #0f1729; border-color: #334155; color: #e2e8f0; }
:is(.dark) .ctrl-input:focus,
:is(.dark) .ctrl-select:focus { border-color: #059669; }
:is(.dark) .field-label { color: #64748b; }
:is(.dark) .btn-clear { border-color: #1e293b; color: #64748b; }
:is(.dark) .btn-clear:hover { background: #1c0a0a; border-color: #7f1d1d; color: #fca5a5; }
:is(.dark) .results-block { background: linear-gradient(135deg, #052e16, #082536); border-color: #065f46; }
:is(.dark) .result-item.total { border-color: #065f46; }
:is(.dark) .result-label { color: #34d399; }
:is(.dark) .result-value { color: #6ee7b7; }
:is(.dark) .result-value.accent { color: #34d399; }
:is(.dark) .preview-panel { background: #0b1120; }
:is(.dark) .preview-header { background: #0f1729; border-color: #1e293b; }
:is(.dark) .preview-tag { color: #94a3b8; }
:is(.dark) .preview-scroll { background: repeating-linear-gradient(45deg, #0f1729 0px, #0f1729 1px, #0b1120 1px, #0b1120 10px); }
:is(.dark) .page { background: #fff; box-shadow: 0 4px 40px rgba(0,0,0,0.5); }
</style>
