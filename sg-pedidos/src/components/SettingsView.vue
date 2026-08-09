<script setup lang="ts">
import { ref, onMounted, watch } from 'vue'
import { useBusinessConfig, type BusinessConfig } from '../composables/useBusinessConfig'
import { useAuth } from '../composables/useAuth'
import { Save, RotateCcw, Upload, Palette, Building2, CheckCircle2, AlertCircle } from 'lucide-vue-next'

const { config, loading, loadConfig, saveConfig } = useBusinessConfig()
const { isAdmin } = useAuth()

// Local form state (copy of config)
const form = ref<Partial<BusinessConfig>>({})
const saving = ref(false)
const saved = ref(false)
const saveError = ref<string | null>(null)

// Color presets
const colorPresets = [
  { name: 'Azul Cielo',  primary: '#0ea5e9', dark: '#0284c7', accent: '#38bdf8' },
  { name: 'Violeta',     primary: '#8b5cf6', dark: '#7c3aed', accent: '#a78bfa' },
  { name: 'Esmeralda',   primary: '#10b981', dark: '#059669', accent: '#34d399' },
  { name: 'Rosa',        primary: '#ec4899', dark: '#db2777', accent: '#f472b6' },
  { name: 'Naranja',     primary: '#f97316', dark: '#ea580c', accent: '#fb923c' },
  { name: 'Rojo',        primary: '#ef4444', dark: '#dc2626', accent: '#f87171' },
  { name: 'Índigo',      primary: '#6366f1', dark: '#4f46e5', accent: '#818cf8' },
  { name: 'Teal',        primary: '#14b8a6', dark: '#0d9488', accent: '#2dd4bf' },
]

function syncFormFromConfig() {
  form.value = {
    business_name: config.value.business_name,
    business_rfc: config.value.business_rfc,
    business_email: config.value.business_email,
    business_address: config.value.business_address,
    business_phone: config.value.business_phone,
    business_logo_url: config.value.business_logo_url,
    business_socials: config.value.business_socials,
    business_series: config.value.business_series,
    tax_rate: config.value.tax_rate,
    color_primary: config.value.color_primary,
    color_primary_dark: config.value.color_primary_dark,
    color_accent: config.value.color_accent,
  }
}

onMounted(async () => {
  await loadConfig()
  syncFormFromConfig()
})

// Keep form in sync if config changes externally
watch(() => config.value, () => {
  if (!saving.value) syncFormFromConfig()
}, { deep: true })

function applyPreset(preset: typeof colorPresets[0]) {
  form.value.color_primary = preset.primary
  form.value.color_primary_dark = preset.dark
  form.value.color_accent = preset.accent
}

async function handleSave() {
  saving.value = true
  saved.value = false
  saveError.value = null

  try {
    await saveConfig(form.value)
    saved.value = true
    setTimeout(() => { saved.value = false }, 3000)
  } catch (e) {
    saveError.value = (e as Error).message
  } finally {
    saving.value = false
  }
}

function handleReset() {
  syncFormFromConfig()
}

function handleLogoFileChange(e: Event) {
  const input = e.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file) return

  const reader = new FileReader()
  reader.onload = () => {
    form.value.business_logo_url = reader.result as string
  }
  reader.readAsDataURL(file)
  input.value = ''
}
</script>

<template>
  <div class="settings-page" v-if="isAdmin">
    <header class="settings-header">
      <div class="header-icon">
        <Building2 class="h-7 w-7" />
      </div>
      <div>
        <h1 class="settings-title">Configuración del Negocio</h1>
        <p class="settings-subtitle">Personaliza tu sistema sin tocar código</p>
      </div>
    </header>

    <!-- Success / Error banners -->
    <Transition name="slide-fade">
      <div v-if="saved" class="banner banner-success">
        <CheckCircle2 class="h-5 w-5" />
        <span>Configuración guardada correctamente</span>
      </div>
    </Transition>
    <Transition name="slide-fade">
      <div v-if="saveError" class="banner banner-error">
        <AlertCircle class="h-5 w-5" />
        <span>{{ saveError }}</span>
      </div>
    </Transition>

    <div class="settings-grid">
      <!-- ==================== CARD: Datos del negocio ==================== -->
      <section class="settings-card">
        <h2 class="card-title">
          <Building2 class="h-5 w-5" />
          Datos del Negocio
        </h2>

        <div class="form-group">
          <label for="cfg-name">Nombre del negocio</label>
          <input id="cfg-name" v-model="form.business_name" type="text" placeholder="Mi Imprenta" />
        </div>

        <div class="form-row">
          <div class="form-group">
            <label for="cfg-rfc">RFC</label>
            <input id="cfg-rfc" v-model="form.business_rfc" type="text" placeholder="XXXX000000XXX" />
          </div>
          <div class="form-group">
            <label for="cfg-phone">Teléfono</label>
            <input id="cfg-phone" v-model="form.business_phone" type="text" placeholder="(123) 456 7890" />
          </div>
        </div>

        <div class="form-group">
          <label for="cfg-email">Email</label>
          <input id="cfg-email" v-model="form.business_email" type="email" placeholder="contacto@miimprenta.com" />
        </div>

        <div class="form-group">
          <label for="cfg-address">Dirección</label>
          <textarea id="cfg-address" v-model="form.business_address" rows="2" placeholder="Calle #123, Col. Centro, Ciudad, Estado"></textarea>
        </div>

        <div class="form-group">
          <label for="cfg-socials">Redes sociales (para tickets)</label>
          <input id="cfg-socials" v-model="form.business_socials" type="text" placeholder="FB: @miImprenta • IG: @miImprenta" />
        </div>
      </section>

      <!-- ==================== CARD: Cotizador ==================== -->
      <section class="settings-card">
        <h2 class="card-title">
          <Save class="h-5 w-5" />
          Cotizador y Facturación
        </h2>

        <div class="form-row">
          <div class="form-group">
            <label for="cfg-series">Prefijo de folio</label>
            <input id="cfg-series" v-model="form.business_series" type="text" placeholder="COT" maxlength="5" />
            <span class="hint">Ej: "SG", "COT", "IL"</span>
          </div>
          <div class="form-group">
            <label for="cfg-tax">Tasa de IVA</label>
            <input id="cfg-tax" v-model.number="form.tax_rate" type="number" step="0.01" min="0" max="1" placeholder="0.16" />
            <span class="hint">0.16 = 16%</span>
          </div>
        </div>

        <!-- Logo preview + upload -->
        <div class="form-group">
          <label>Logo del negocio</label>
          <div class="logo-section">
            <div class="logo-preview">
              <img
                v-if="form.business_logo_url"
                :src="form.business_logo_url"
                alt="Logo preview"
                class="logo-img"
              />
              <div v-else class="logo-placeholder">Sin logo</div>
            </div>
            <div class="logo-actions">
              <label class="upload-btn">
                <Upload class="h-4 w-4" />
                Subir imagen
                <input type="file" accept="image/*" class="hidden-input" @change="handleLogoFileChange" />
              </label>
              <div class="form-group" style="margin:0">
                <input v-model="form.business_logo_url" type="text" placeholder="URL o ruta al logo" />
              </div>
            </div>
          </div>
        </div>
      </section>

      <!-- ==================== CARD: Colores (Whitelabel) ==================== -->
      <section class="settings-card settings-card-full">
        <h2 class="card-title">
          <Palette class="h-5 w-5" />
          Colores del Tema
        </h2>
        <p class="card-desc">Elige una paleta predefinida o personaliza los colores.</p>

        <!-- Presets -->
        <div class="preset-grid">
          <button
            v-for="preset in colorPresets"
            :key="preset.name"
            class="preset-btn"
            :class="{ active: form.color_primary === preset.primary }"
            @click="applyPreset(preset)"
          >
            <span class="preset-swatch" :style="{ background: `linear-gradient(135deg, ${preset.primary}, ${preset.dark})` }"></span>
            <span class="preset-label">{{ preset.name }}</span>
          </button>
        </div>

        <!-- Custom pickers -->
        <div class="color-pickers">
          <div class="color-group">
            <label for="cp-primary">Primario</label>
            <div class="color-input-row">
              <input id="cp-primary" type="color" v-model="form.color_primary" />
              <input type="text" v-model="form.color_primary" class="color-hex" placeholder="#0ea5e9" />
            </div>
          </div>
          <div class="color-group">
            <label for="cp-dark">Primario oscuro</label>
            <div class="color-input-row">
              <input id="cp-dark" type="color" v-model="form.color_primary_dark" />
              <input type="text" v-model="form.color_primary_dark" class="color-hex" placeholder="#0284c7" />
            </div>
          </div>
          <div class="color-group">
            <label for="cp-accent">Acento</label>
            <div class="color-input-row">
              <input id="cp-accent" type="color" v-model="form.color_accent" />
              <input type="text" v-model="form.color_accent" class="color-hex" placeholder="#38bdf8" />
            </div>
          </div>
        </div>

        <!-- Live preview -->
        <div class="preview-card" :style="{
          '--p': form.color_primary,
          '--pd': form.color_primary_dark,
          '--pa': form.color_accent,
        }">
          <div class="preview-header">
            <span class="preview-dot" :style="{ background: form.color_primary }"></span>
            <span class="preview-title">Vista previa</span>
          </div>
          <div class="preview-body">
            <button class="preview-btn-primary">Botón primario</button>
            <button class="preview-btn-outline">Botón outline</button>
            <div class="preview-badge">Badge</div>
            <div class="preview-bar"></div>
          </div>
        </div>
      </section>
    </div>

    <!-- Actions -->
    <div class="settings-actions">
      <button class="btn-secondary" @click="handleReset" :disabled="saving">
        <RotateCcw class="h-4 w-4" />
        Deshacer cambios
      </button>
      <button class="btn-primary" @click="handleSave" :disabled="saving || loading">
        <Save class="h-4 w-4" />
        {{ saving ? 'Guardando...' : 'Guardar configuración' }}
      </button>
    </div>
  </div>
</template>

<style scoped>
.settings-page {
  max-width: 960px;
  margin: 0 auto;
  padding: 8px;
}

.settings-header {
  display: flex;
  align-items: center;
  gap: 16px;
  margin-bottom: 24px;
}

.header-icon {
  width: 52px; height: 52px;
  border-radius: 14px;
  background: linear-gradient(135deg, var(--brand-primary, #0ea5e9), var(--brand-primary-dark, #0284c7));
  color: #fff;
  display: flex; align-items: center; justify-content: center;
  box-shadow: 0 4px 14px var(--brand-primary-20, rgba(14,165,233,.2));
}

.settings-title {
  font-family: 'Montserrat', sans-serif;
  font-size: 24px;
  font-weight: 800;
  color: #0f172a;
  margin: 0;
}
:is(.dark) .settings-title { color: #f1f5f9; }

.settings-subtitle {
  color: #64748b;
  font-size: 14px;
  margin: 2px 0 0;
}
:is(.dark) .settings-subtitle { color: #94a3b8; }

/* Banners */
.banner {
  display: flex; align-items: center; gap: 10px;
  padding: 12px 16px; border-radius: 10px;
  margin-bottom: 16px; font-weight: 600; font-size: 14px;
}
.banner-success { background: #ecfdf5; color: #065f46; border: 1px solid #a7f3d0; }
:is(.dark) .banner-success { background: #064e3b; color: #a7f3d0; border-color: #065f46; }
.banner-error { background: #fef2f2; color: #991b1b; border: 1px solid #fecaca; }
:is(.dark) .banner-error { background: #450a0a; color: #fca5a5; border-color: #991b1b; }

.slide-fade-enter-active { transition: all .3s ease; }
.slide-fade-leave-active { transition: all .2s ease; }
.slide-fade-enter-from { transform: translateY(-8px); opacity: 0; }
.slide-fade-leave-to { opacity: 0; }

/* Grid */
.settings-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(380px, 1fr));
  gap: 20px;
  margin-bottom: 24px;
}

.settings-card {
  background: #fff;
  border: 1px solid #e2e8f0;
  border-radius: 14px;
  padding: 24px;
  transition: box-shadow .2s ease;
}
.settings-card:hover { box-shadow: 0 4px 20px rgba(0,0,0,.06); }
:is(.dark) .settings-card { background: #1e293b; border-color: #334155; }
:is(.dark) .settings-card:hover { box-shadow: 0 4px 20px rgba(0,0,0,.3); }

.settings-card-full { grid-column: 1 / -1; }

.card-title {
  display: flex; align-items: center; gap: 8px;
  font-size: 16px; font-weight: 700; color: #0f172a;
  margin: 0 0 16px;
}
:is(.dark) .card-title { color: #f1f5f9; }

.card-desc {
  color: #64748b; font-size: 13px; margin: -10px 0 16px;
}
:is(.dark) .card-desc { color: #94a3b8; }

/* Form */
.form-group {
  margin-bottom: 14px;
}
.form-group label {
  display: block; font-size: 13px; font-weight: 700;
  color: #334155; margin-bottom: 5px;
}
:is(.dark) .form-group label { color: #cbd5e1; }

.form-group input[type="text"],
.form-group input[type="email"],
.form-group input[type="number"],
.form-group textarea {
  width: 100%; padding: 10px 12px;
  border: 1px solid #e2e8f0; border-radius: 8px;
  font-size: 14px; color: #0f172a;
  background: #f8fafc;
  transition: border-color .15s, box-shadow .15s;
  box-sizing: border-box;
}
.form-group input:focus, .form-group textarea:focus {
  outline: none;
  border-color: var(--brand-primary, #0ea5e9);
  box-shadow: 0 0 0 3px var(--brand-primary-10, rgba(14,165,233,.1));
}
:is(.dark) .form-group input[type="text"],
:is(.dark) .form-group input[type="email"],
:is(.dark) .form-group input[type="number"],
:is(.dark) .form-group textarea {
  background: #0f172a; border-color: #475569; color: #e2e8f0;
}

.form-group textarea { resize: vertical; }
.hint { color: #94a3b8; font-size: 12px; margin-top: 3px; display: block; }

.form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
@media (max-width: 500px) { .form-row { grid-template-columns: 1fr; } }

/* Logo */
.logo-section { display: flex; gap: 16px; align-items: flex-start; }
.logo-preview {
  width: 80px; height: 80px;
  border-radius: 12px; border: 2px dashed #e2e8f0;
  display: flex; align-items: center; justify-content: center;
  overflow: hidden; flex-shrink: 0;
  background: #f8fafc;
}
:is(.dark) .logo-preview { border-color: #475569; background: #0f172a; }
.logo-img { width: 100%; height: 100%; object-fit: contain; }
.logo-placeholder { color: #94a3b8; font-size: 11px; text-align: center; }
.logo-actions { flex: 1; display: flex; flex-direction: column; gap: 8px; }

.upload-btn {
  display: inline-flex; align-items: center; gap: 6px;
  padding: 8px 14px; border-radius: 8px;
  background: var(--brand-primary, #0ea5e9);
  color: #fff; font-weight: 600; font-size: 13px;
  cursor: pointer; border: none;
  transition: background .15s;
  width: fit-content;
}
.upload-btn:hover { filter: brightness(1.1); }
.hidden-input { display: none; }

/* Color presets */
.preset-grid {
  display: flex; flex-wrap: wrap; gap: 10px; margin-bottom: 20px;
}
.preset-btn {
  display: flex; align-items: center; gap: 8px;
  padding: 8px 14px; border-radius: 10px;
  border: 2px solid transparent;
  background: #f8fafc; cursor: pointer;
  transition: all .15s;
}
.preset-btn:hover { border-color: #cbd5e1; }
.preset-btn.active { border-color: var(--brand-primary, #0ea5e9); background: #eff6ff; }
:is(.dark) .preset-btn { background: #0f172a; }
:is(.dark) .preset-btn:hover { border-color: #475569; }
:is(.dark) .preset-btn.active { border-color: var(--brand-primary, #0ea5e9); background: #1e293b; }
.preset-swatch {
  width: 24px; height: 24px; border-radius: 6px;
  box-shadow: 0 2px 6px rgba(0,0,0,.15);
}
.preset-label { font-size: 13px; font-weight: 600; color: #334155; }
:is(.dark) .preset-label { color: #cbd5e1; }

/* Color pickers */
.color-pickers { display: flex; gap: 20px; flex-wrap: wrap; margin-bottom: 20px; }
.color-group label { display: block; font-size: 12px; font-weight: 700; color: #64748b; margin-bottom: 4px; }
:is(.dark) .color-group label { color: #94a3b8; }
.color-input-row { display: flex; align-items: center; gap: 8px; }
.color-input-row input[type="color"] {
  width: 40px; height: 40px; border: 2px solid #e2e8f0;
  border-radius: 8px; cursor: pointer; padding: 2px;
  background: transparent;
}
:is(.dark) .color-input-row input[type="color"] { border-color: #475569; }
.color-hex {
  width: 100px; padding: 8px 10px; border: 1px solid #e2e8f0;
  border-radius: 8px; font-size: 13px; font-family: monospace;
  color: #0f172a; background: #f8fafc;
}
:is(.dark) .color-hex { background: #0f172a; border-color: #475569; color: #e2e8f0; }

/* Live preview */
.preview-card {
  background: #f8fafc;
  border: 1px solid #e2e8f0;
  border-radius: 12px;
  overflow: hidden;
}
:is(.dark) .preview-card { background: #0f172a; border-color: #334155; }

.preview-header {
  display: flex; align-items: center; gap: 10px;
  padding: 14px 18px;
  background: linear-gradient(135deg, var(--p), var(--pd));
  color: #fff;
}
.preview-dot { width: 12px; height: 12px; border-radius: 50%; }
.preview-title { font-weight: 700; font-size: 15px; }

.preview-body {
  padding: 18px;
  display: flex; align-items: center; gap: 12px; flex-wrap: wrap;
}
.preview-btn-primary {
  padding: 8px 18px; border-radius: 8px; border: none;
  background: var(--p); color: #fff; font-weight: 700;
  font-size: 13px; cursor: pointer;
  transition: filter .15s;
}
.preview-btn-primary:hover { filter: brightness(1.1); }
.preview-btn-outline {
  padding: 8px 18px; border-radius: 8px;
  border: 2px solid var(--p); background: transparent;
  color: var(--p); font-weight: 700; font-size: 13px;
  cursor: pointer;
}
.preview-badge {
  padding: 4px 12px; border-radius: 999px;
  background: var(--pa); color: #fff;
  font-size: 12px; font-weight: 700;
}
.preview-bar {
  flex: 1; min-width: 80px; height: 8px; border-radius: 4px;
  background: linear-gradient(90deg, var(--p), var(--pa));
}

/* Action buttons */
.settings-actions {
  display: flex; justify-content: flex-end; gap: 12px;
  padding-top: 8px; border-top: 1px solid #e2e8f0;
}
:is(.dark) .settings-actions { border-top-color: #334155; }

.btn-primary {
  display: inline-flex; align-items: center; gap: 8px;
  padding: 10px 24px; border-radius: 10px;
  background: linear-gradient(135deg, var(--brand-primary, #0ea5e9), var(--brand-primary-dark, #0284c7));
  color: #fff; font-weight: 700; font-size: 14px;
  border: none; cursor: pointer;
  box-shadow: 0 4px 14px var(--brand-primary-20, rgba(14,165,233,.2));
  transition: all .15s;
}
.btn-primary:hover { filter: brightness(1.1); transform: translateY(-1px); }
.btn-primary:disabled { opacity: .6; cursor: not-allowed; transform: none; }

.btn-secondary {
  display: inline-flex; align-items: center; gap: 8px;
  padding: 10px 20px; border-radius: 10px;
  background: #f8fafc; color: #475569;
  font-weight: 600; font-size: 14px;
  border: 1px solid #e2e8f0; cursor: pointer;
  transition: all .15s;
}
.btn-secondary:hover { background: #f1f5f9; border-color: #cbd5e1; }
:is(.dark) .btn-secondary { background: #1e293b; border-color: #475569; color: #94a3b8; }
:is(.dark) .btn-secondary:hover { background: #334155; }

@media (max-width: 500px) {
  .settings-grid { grid-template-columns: 1fr; }
  .settings-actions { flex-direction: column; }
  .color-pickers { flex-direction: column; }
  .logo-section { flex-direction: column; }
}
</style>
