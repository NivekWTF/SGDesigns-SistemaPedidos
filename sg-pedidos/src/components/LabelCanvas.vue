<template>
  <div class="label-canvas-root">
    <div class="controls">
      <h3>Calculador de etiquetas - Tabloide 12" x 18"</h3>

      <div class="row">
        <label>Orientación</label>
        <select v-model="orientation">
          <option value="12x18">12 x 18 (ancho x alto)</option>
          <option value="18x12">18 x 12 (ancho x alto)</option>
        </select>
      </div>

      <div class="row">
        <label>Unidades / DPI</label>
        <select v-model="unit">
          <option value="in">in</option>
          <option value="mm">mm</option>
          <option value="cm">cm</option>
        </select>
        <input v-model.number="dpi" type="number" min="72" step="1" style="width:120px" />
      </div>

      <div class="row">
        <label>Tamaño etiqueta ({ {unit} })</label>
        <input v-model.number="labelWidth" type="number" step="0.01" min="0.1" />
        <input v-model.number="labelHeight" type="number" step="0.01" min="0.1" />
      </div>

      <div class="row">
        <label>Gaps ({ {unit} })</label>
        <input v-model.number="hGap" type="number" step="0.01" min="0" />
        <input v-model.number="vGap" type="number" step="0.01" min="0" />
      </div>

      <div class="row">
        <label>Margen ({ {unit} })</label>
        <input v-model.number="marginLeft" type="number" step="0.01" min="0" />
        <input v-model.number="marginTop" type="number" step="0.01" min="0" />
        <input v-model.number="marginRight" type="number" step="0.01" min="0" />
        <input v-model.number="marginBottom" type="number" step="0.01" min="0" />
      </div>

      <div class="row">
        <label>Imagen (URL)</label>
        <input v-model="imageUrl" placeholder="https://..." />
        <input type="file" @change="onFile" accept="image/*" />
      </div>

      <div class="actions">
        <button class="btn" @click="calculate">Calcular</button>
        <button class="btn" @click="generateGrid">Generar grid</button>
        <button class="btn-ghost" @click="clearGrid">Limpiar</button>
      </div>

      <div class="info">
        <div>Columnas: <strong>{{ cols }}</strong></div>
        <div>Filas: <strong>{{ rows }}</strong></div>
        <div>Total etiquetas: <strong>{{ total }}</strong></div>
      </div>
    </div>

    <div class="canvas-area">
      <div class="page" :style="pageStyle">
        <div class="page-inner" :style="innerStyle">
          <div v-for="(cell, i) in cells" :key="i" class="label-cell" :style="cellStyle">
            <img v-if="cellImage" :src="cellImage" class="cell-image" />
            <div class="cell-content">Etiqueta</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'

// page size in inches
const orientation = ref<'12x18'|'18x12'>('12x18')

const unit = ref<'in'|'mm'|'cm'>('in')
const dpi = ref(300)

const labelWidth = ref(2.0)
const labelHeight = ref(1.0)
const hGap = ref(0.125)
const vGap = ref(0.125)
const marginLeft = ref(0.25)
const marginTop = ref(0.25)
const marginRight = ref(0.25)
const marginBottom = ref(0.25)

const imageUrl = ref('')
const cellImage = ref<string | null>(null)

// preview scale will be derived from DPI and max display size
const maxPreviewWidth = 900

function pageDimensions(){
  if (orientation.value === '12x18') return { w: 12, h: 18 }
  return { w: 18, h: 12 }
}

const cols = ref(0)
const rows = ref(0)
const total = computed(()=> cols.value * rows.value)

const cells = ref<Array<number>>([])

function calculate(){
  const { w, h } = pageDimensions()
  // convert all inputs to inches
  const ml = toInches(marginLeft.value, unit.value)
  const mr = toInches(marginRight.value, unit.value)
  const mt = toInches(marginTop.value, unit.value)
  const mb = toInches(marginBottom.value, unit.value)
  const lw = toInches(labelWidth.value, unit.value)
  const lh = toInches(labelHeight.value, unit.value)
  const hg = toInches(hGap.value, unit.value)
  const vg = toInches(vGap.value, unit.value)

  const availW = w - ml - mr
  const availH = h - mt - mb

  const c = Math.floor((availW + hg) / (lw + hg))
  const r = Math.floor((availH + vg) / (lh + vg))

  cols.value = Math.max(0, c)
  rows.value = Math.max(0, r)
}

function generateGrid(){
  calculate()
  const count = cols.value * rows.value
  cells.value = Array.from({length: count}, (_,i)=>i)
  cellImage.value = imageUrl.value || cellImage.value
}

function clearGrid(){
  cells.value = []
}

function onFile(e: Event){
  const input = e.target as HTMLInputElement
  const f = input.files && input.files[0]
  if (!f) return
  const reader = new FileReader()
  reader.onload = ()=>{ cellImage.value = String(reader.result) }
  reader.readAsDataURL(f)
}

// helper to convert unit to inches
function toInches(val:number, u:'in'|'mm'|'cm'){
  if(u === 'in') return val
  if(u === 'mm') return val / 25.4
  return val / 2.54
}

const pageStyle = computed(()=>{
  const { w, h } = pageDimensions()
  const pageWIn = w
  const pageHIn = h
  const pagePixelW = pageWIn * dpi.value
  const pagePixelH = pageHIn * dpi.value
  // scale down for preview if too wide
  const previewScale = Math.min(1, maxPreviewWidth / pagePixelW)
  return { width: `${Math.round(pagePixelW * previewScale)}px`, height: `${Math.round(pagePixelH * previewScale)}px` }
})

const innerStyle = computed(()=>{
  const lw = toInches(labelWidth.value, unit.value)
  const lh = toInches(labelHeight.value, unit.value)
  const hg = toInches(hGap.value, unit.value)
  const vg = toInches(vGap.value, unit.value)
  const ml = toInches(marginLeft.value, unit.value)
  const mt = toInches(marginTop.value, unit.value)
  const mr = toInches(marginRight.value, unit.value)
  const mb = toInches(marginBottom.value, unit.value)

  const pageWIn = pageDimensions().w
  const pagePixelW = pageWIn * dpi.value
  const previewScale = Math.min(1, maxPreviewWidth / pagePixelW)

  return {
    paddingTop: `${Math.round(mt * dpi.value * previewScale)}px`,
    paddingLeft: `${Math.round(ml * dpi.value * previewScale)}px`,
    paddingRight: `${Math.round(mr * dpi.value * previewScale)}px`,
    paddingBottom: `${Math.round(mb * dpi.value * previewScale)}px`,
    gap: `${Math.round(vg * dpi.value * previewScale)}px ${Math.round(hg * dpi.value * previewScale)}px`,
    gridTemplateColumns: `repeat(${Math.max(1, cols.value)}, ${Math.round(lw * dpi.value * previewScale)}px)`
  }
})

const cellStyle = computed(()=>{
  const lw = toInches(labelWidth.value, unit.value)
  const lh = toInches(labelHeight.value, unit.value)
  const pageWIn = pageDimensions().w
  const pagePixelW = pageWIn * dpi.value
  const previewScale = Math.min(1, maxPreviewWidth / pagePixelW)
  return {
    width: `${Math.round(lw * dpi.value * previewScale)}px`,
    height: `${Math.round(lh * dpi.value * previewScale)}px`
  }
})

</script>

<style scoped>
.label-canvas-root{display:flex;gap:18px;padding:16px}
.controls{width:360px;background:#fff;border:1px solid #e6eef2;padding:12px;border-radius:8px}
.controls .row{display:flex;gap:8px;align-items:center;margin-bottom:8px}
.controls label{width:120px;font-weight:700}
.controls input[type="number"], .controls input[type="text"], .controls select{flex:1;padding:6px;border:1px solid #e6eef2;border-radius:6px}
.actions{display:flex;gap:8px;margin-top:8px}
.btn{background:#059669;color:#fff;padding:8px 12px;border-radius:6px;border:none}
.btn-ghost{background:transparent;border:1px solid #e6eef2;padding:8px 12px;border-radius:6px}
.info{margin-top:12px;display:flex;gap:12px}

.canvas-area{flex:1;display:flex;align-items:flex-start;justify-content:center;padding:8px}
.page{background:linear-gradient(180deg,#fff,#fbfdff);border:1px solid #cfdbe6;padding:8px;box-shadow:0 8px 24px rgba(2,6,23,0.06)}
.page-inner{display:grid;grid-auto-rows:auto;align-content:start}
.label-cell{border:1px dashed #e6eef2;display:flex;align-items:center;justify-content:center;position:relative;overflow:hidden}
.cell-image{position:absolute;inset:0;width:100%;height:100%;object-fit:cover;opacity:0.9}
.cell-content{z-index:2;font-size:12px;color:#0f172a}

/* scroll if too large */
.canvas-area .page{max-width:calc(100vw - 420px);max-height:calc(100vh - 120px);overflow:auto}

/* Dark mode */
:is(.dark) .label-canvas-root{color:#e2e8f0}
:is(.dark) .controls{background:#111c2e;border-color:#1e293b}
:is(.dark) .controls h3{color:#e2e8f0}
:is(.dark) .controls label{color:#94a3b8}
:is(.dark) .controls input[type="number"],:is(.dark) .controls input[type="text"],:is(.dark) .controls select{background:#0f1729;border-color:#334155;color:#e2e8f0}
:is(.dark) .btn{background:#059669}
:is(.dark) .btn-ghost{border-color:#334155;color:#cbd5e1}
:is(.dark) .info{color:#94a3b8}
:is(.dark) .info strong{color:#e2e8f0}
:is(.dark) .page{background:linear-gradient(180deg,#1e293b,#111c2e);border-color:#334155;box-shadow:0 8px 24px rgba(0,0,0,0.2)}
:is(.dark) .label-cell{border-color:#334155}
:is(.dark) .cell-content{color:#e2e8f0}
</style>
