<template>
  <div class="view-page">
    <div class="page-header">
      <div>
        <h1 class="font-spa-display">Configuración del Spa</h1>
        <p class="page-sub">Personaliza la información y apariencia de tu spa</p>
      </div>
    </div>

    <div v-if="loadingTenant" class="empty-state"><div class="spinner"/><p>Cargando...</p></div>

    <div v-else class="config-layout">
      <!-- Col izq: datos del spa -->
      <div class="config-col">
        <!-- Sección General -->
        <div class="card-spa config-section">
          <h2>Información general</h2>
          <form @submit.prevent="guardarGeneral" class="config-form">
            <div class="field">
              <label>Nombre del spa *</label>
              <input v-model="form.nombre" required placeholder="Ej. Lotus Spa & Wellness" />
            </div>
            <div class="field">
              <label>Zona horaria</label>
              <select v-model="form.zona_horaria">
                <option value="America/Mexico_City">América/Ciudad de México (UTC-6)</option>
                <option value="America/Monterrey">América/Monterrey (UTC-6)</option>
                <option value="America/Cancun">América/Cancún (UTC-5)</option>
                <option value="America/Tijuana">América/Tijuana (UTC-8)</option>
                <option value="America/Chicago">América/Chicago (UTC-6)</option>
                <option value="America/New_York">América/Nueva York (UTC-5)</option>
              </select>
            </div>
            <div class="field">
              <label>Color principal</label>
              <div class="color-row">
                <div class="color-preview" :style="{ background: form.color_primario }"/>
                <input v-model="form.color_primario" type="color" class="color-input" />
                <span class="color-code">{{ form.color_primario }}</span>
              </div>
              <div class="color-presets">
                <button v-for="c in COLOR_PRESETS" :key="c.value" type="button"
                  class="preset-swatch"
                  :style="{ background: c.value }"
                  :class="form.color_primario === c.value && 'selected'"
                  :title="c.label"
                  @click="form.color_primario = c.value"
                />
              </div>
            </div>

            <div v-if="successGeneral" class="form-success">✅ Cambios guardados</div>
            <div v-if="errorGeneral" class="form-error">{{ errorGeneral }}</div>

            <button type="submit" class="btn-primary w-full" :disabled="savingGeneral">
              <Loader2 v-if="savingGeneral" class="h-4 w-4 animate-spin"/> Guardar información
            </button>
          </form>
        </div>

        <!-- Info de suscripción -->
        <div class="card-spa config-section">
          <h2>Plan y suscripción</h2>
          <div class="plan-card" :class="`plan-${spaConfig?.plan}`">
            <div class="plan-icon">
              {{ spaConfig?.plan === 'enterprise' ? '👑' : spaConfig?.plan === 'pro' ? '⭐' : '🌱' }}
            </div>
            <div>
              <div class="plan-nombre">{{ planLabel }}</div>
              <div class="plan-meta">
                <span v-if="spaConfig?.trial_hasta">Trial hasta: {{ fmtDate(spaConfig.trial_hasta) }}</span>
                <span v-else>Plan activo</span>
              </div>
            </div>
          </div>
          <div class="plan-features">
            <div class="feature-row" v-for="f in planFeatures" :key="f.label">
              <span :class="f.ok ? 'feat-ok' : 'feat-no'">{{ f.ok ? '✓' : '✗' }}</span>
              {{ f.label }}
            </div>
          </div>
        </div>
      </div>

      <!-- Col der: logo + info del sistema -->
      <div class="config-col">
        <!-- Logo -->
        <div class="card-spa config-section">
          <h2>Logo del spa</h2>
          <div class="logo-preview-wrap">
            <div v-if="spaConfig?.logo_url" class="logo-preview">
              <img :src="spaConfig.logo_url" alt="Logo" />
            </div>
            <div v-else class="logo-placeholder">
              <ImageIcon class="h-10 w-10 op-30"/>
              <p>Sin logo cargado</p>
            </div>
          </div>
          <div class="field mt-4">
            <label>URL del logo</label>
            <input v-model="form.logo_url" placeholder="https://..." />
          </div>
          <button class="btn-primary w-full mt-3" @click="guardarLogo" :disabled="savingLogo">
            <Loader2 v-if="savingLogo" class="h-4 w-4 animate-spin"/> Actualizar logo
          </button>
          <p class="hint-text mt-2">Recomendado: imagen cuadrada 200×200px, formato PNG o SVG</p>
        </div>

        <!-- Info del sistema -->
        <div class="card-spa config-section">
          <h2>Información del sistema</h2>
          <div class="sysinfo-list">
            <div class="sysinfo-row">
              <span class="sysinfo-lbl">Spa ID</span>
              <code class="sysinfo-val">{{ spaConfig?.id?.slice(0, 8) }}…</code>
            </div>
            <div class="sysinfo-row">
              <span class="sysinfo-lbl">Plan activo</span>
              <span class="sysinfo-val">{{ planLabel }}</span>
            </div>
            <div class="sysinfo-row">
              <span class="sysinfo-lbl">Zona horaria</span>
              <span class="sysinfo-val">{{ spaConfig?.zona_horaria }}</span>
            </div>
            <div class="sysinfo-row">
              <span class="sysinfo-lbl">Estado</span>
              <span :class="spaConfig?.activo ? 'badge-confirmada estado-badge' : 'badge-cancelada estado-badge'">
                {{ spaConfig?.activo ? 'Activo' : 'Inactivo' }}
              </span>
            </div>
            <div class="sysinfo-row">
              <span class="sysinfo-lbl">Creado</span>
              <span class="sysinfo-val">{{ spaConfig ? fmtDate(spaConfig.created_at) : '—' }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, watch } from 'vue'
import { useTenant } from '../composables/useTenant'
import { ImageIcon, Loader2 } from 'lucide-vue-next'

const { spaConfig, loadingTenant, fetchSpaConfig, updateSpaConfig } = useTenant()

const COLOR_PRESETS = [
  { value: '#8b5cf6', label: 'Lavanda' },
  { value: '#ec4899', label: 'Rosa' },
  { value: '#10b981', label: 'Verde spa' },
  { value: '#f59e0b', label: 'Dorado' },
  { value: '#3b82f6', label: 'Azul' },
  { value: '#06b6d4', label: 'Turquesa' },
  { value: '#8b5e3c', label: 'Café' },
  { value: '#1d4ed8', label: 'Índigo' },
]

const form = ref({
  nombre: '',
  zona_horaria: 'America/Mexico_City',
  color_primario: '#8b5cf6',
  logo_url: '',
})

watch(spaConfig, (cfg) => {
  if (cfg) {
    form.value.nombre = cfg.nombre
    form.value.zona_horaria = cfg.zona_horaria
    form.value.color_primario = cfg.color_primario
    form.value.logo_url = cfg.logo_url ?? ''
  }
}, { immediate: true })

const savingGeneral = ref(false)
const savingLogo = ref(false)
const successGeneral = ref(false)
const errorGeneral = ref<string | null>(null)

async function guardarGeneral() {
  savingGeneral.value = true
  successGeneral.value = false
  errorGeneral.value = null
  try {
    await updateSpaConfig({
      nombre:         form.value.nombre,
      zona_horaria:   form.value.zona_horaria,
      color_primario: form.value.color_primario,
    })
    successGeneral.value = true
    setTimeout(() => { successGeneral.value = false }, 3000)
  } catch (e: any) {
    errorGeneral.value = e.message ?? 'Error al guardar'
  } finally {
    savingGeneral.value = false
  }
}

async function guardarLogo() {
  savingLogo.value = true
  try {
    await updateSpaConfig({ logo_url: form.value.logo_url || null })
  } finally {
    savingLogo.value = false
  }
}

function fmtDate(d: string) {
  return new Date(d).toLocaleDateString('es-MX', { day: 'numeric', month: 'long', year: 'numeric' })
}

const planLabel = computed(() => {
  const M: Record<string, string> = { basic: 'Básico', pro: 'Pro', enterprise: 'Enterprise' }
  return M[spaConfig.value?.plan ?? 'basic'] ?? 'Básico'
})

const planFeatures = computed(() => {
  const plan = spaConfig.value?.plan ?? 'basic'
  return [
    { label: 'Agenda y citas ilimitadas', ok: true },
    { label: 'Módulo de caja y gastos', ok: true },
    { label: 'Reportes y estadísticas', ok: plan !== 'basic' },
    { label: 'Múltiples terapeutas', ok: plan !== 'basic' },
    { label: 'Múltiple sede / sucursales', ok: plan === 'enterprise' },
    { label: 'API personalizada', ok: plan === 'enterprise' },
  ]
})

onMounted(fetchSpaConfig)
</script>

<style scoped>
.view-page { padding: 24px; max-width: 1000px; }
.page-header { margin-bottom: 24px; }
.page-header h1 { font-size: 26px; font-weight: 700; color: var(--foreground); margin: 0; }
.page-sub { color: var(--muted-foreground); font-size: 14px; margin: 4px 0 0; }

.config-layout { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; align-items: start; }
.config-col { display: flex; flex-direction: column; gap: 16px; }
.config-section { padding: 20px 22px; }
.config-section h2 { font-size: 15px; font-weight: 700; color: var(--foreground); margin: 0 0 16px; padding-bottom: 10px; border-bottom: 1px solid var(--border); }
.config-form { display: flex; flex-direction: column; gap: 14px; }

/* Color */
.color-row { display: flex; align-items: center; gap: 10px; }
.color-preview { width: 36px; height: 36px; border-radius: 8px; border: 2px solid var(--border); flex-shrink: 0; }
.color-input { width: 36px; height: 36px; border: none; padding: 0; border-radius: 8px; cursor: pointer; }
.color-code { font-family: monospace; font-size: 14px; color: var(--muted-foreground); }
.color-presets { display: flex; gap: 8px; flex-wrap: wrap; margin-top: 6px; }
.preset-swatch { width: 28px; height: 28px; border-radius: 6px; border: 2px solid transparent; cursor: pointer; transition: transform .15s; }
.preset-swatch:hover { transform: scale(1.2); }
.preset-swatch.selected { border-color: var(--foreground); transform: scale(1.15); }

/* Plan */
.plan-card { display: flex; align-items: center; gap: 14px; padding: 14px 16px; border-radius: var(--radius); margin-bottom: 14px; }
.plan-basic      { background: var(--muted); }
.plan-pro        { background: linear-gradient(135deg, #fef3c7, #fde68a); }
.plan-enterprise { background: linear-gradient(135deg, #e0e7ff, #c7d2fe); }
:is(.dark) .plan-pro        { background: linear-gradient(135deg, #451a03, #78350f); }
:is(.dark) .plan-enterprise { background: linear-gradient(135deg, #1e1b4b, #2e1065); }
.plan-icon { font-size: 28px; }
.plan-nombre { font-size: 16px; font-weight: 700; color: var(--foreground); }
.plan-meta { font-size: 12px; color: var(--muted-foreground); margin-top: 2px; }
.plan-features { display: flex; flex-direction: column; gap: 8px; }
.feature-row { display: flex; align-items: center; gap: 10px; font-size: 13px; color: var(--foreground); }
.feat-ok { color: #10b981; font-weight: 700; }
.feat-no { color: var(--muted-foreground); }

/* Logo */
.logo-preview-wrap { border: 2px dashed var(--border); border-radius: var(--radius); padding: 16px; display: flex; justify-content: center; }
.logo-preview img { max-height: 100px; max-width: 100%; object-fit: contain; border-radius: 8px; }
.logo-placeholder { display: flex; flex-direction: column; align-items: center; gap: 8px; color: var(--muted-foreground); font-size: 13px; padding: 20px; }
.op-30 { opacity: .3; }

/* Sysinfo */
.sysinfo-list { display: flex; flex-direction: column; gap: 10px; }
.sysinfo-row { display: flex; align-items: center; justify-content: space-between; font-size: 13px; padding: 8px 0; border-bottom: 1px solid var(--border); }
.sysinfo-row:last-child { border-bottom: none; }
.sysinfo-lbl { color: var(--muted-foreground); font-weight: 600; }
.sysinfo-val { color: var(--foreground); font-weight: 600; }
code.sysinfo-val { font-family: monospace; background: var(--muted); padding: 2px 6px; border-radius: 4px; }

/* Common */
.field { display: flex; flex-direction: column; gap: 6px; }
.field label { font-size: 13px; font-weight: 600; color: var(--foreground); }
.field input, .field select { padding: 9px 12px; border: 1.5px solid var(--border); border-radius: var(--radius); background: var(--background); color: var(--foreground); font-size: 14px; font-family: inherit; }
.field input:focus, .field select:focus { outline: none; border-color: var(--primary); }
.w-full { width: 100%; }
.mt-2 { margin-top: 8px; }
.mt-3 { margin-top: 12px; }
.mt-4 { margin-top: 16px; }
.hint-text { font-size: 12px; color: var(--muted-foreground); margin: 0; }
.form-success { padding: 10px 14px; background: #d1fae5; color: #065f46; border-radius: var(--radius); font-size: 13px; }
.form-error { padding: 10px 14px; background: #fee2e2; color: #dc2626; border-radius: var(--radius); font-size: 13px; }
:is(.dark) .form-success { background: #064e3b; color: #6ee7b7; }
:is(.dark) .form-error { background: #450a0a; color: #f87171; }
.empty-state { padding: 60px; text-align: center; display: flex; flex-direction: column; align-items: center; gap: 12px; color: var(--muted-foreground); }
.spinner { width: 28px; height: 28px; border: 3px solid var(--border); border-top-color: var(--primary); border-radius: 50%; animation: spin .6s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }

.estado-badge { display: inline-block; padding: 3px 10px; border-radius: 999px; font-size: 11px; font-weight: 700; }
.badge-confirmada { background: #d1fae5; color: #065f46; }
.badge-cancelada  { background: #fee2e2; color: #991b1b; }
:is(.dark) .badge-confirmada { background: #064e3b; color: #6ee7b7; }
:is(.dark) .badge-cancelada  { background: #450a0a; color: #fca5a5; }

@media (max-width: 760px) {
  .config-layout { grid-template-columns: 1fr; }
  .view-page { padding: 16px; }
}
</style>
