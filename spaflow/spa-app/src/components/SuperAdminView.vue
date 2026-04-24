<template>
  <div class="view-page">
    <div class="page-header">
      <div>
        <h1 class="font-spa-display">SuperAdmin</h1>
        <p class="page-sub">Panel global de todos los spas en SpaFlow</p>
      </div>
      <button class="btn-primary" @click="openCrearSpa()"><Plus class="h-4 w-4"/> Nuevo spa</button>
    </div>

    <!-- Stats globales -->
    <div class="global-kpis">
      <div class="kpi-pill"><Building2 class="h-4 w-4"/><span class="kv">{{ spas.length }}</span><span>Spas activos</span></div>
      <div class="kpi-pill"><Users class="h-4 w-4"/><span class="kv">{{ todosUsuarios.length }}</span><span>Usuarios</span></div>
    </div>

    <!-- Lista de spas -->
    <div v-if="loading" class="empty-state"><div class="spinner"/><p>Cargando spas...</p></div>
    <div v-else-if="spas.length === 0" class="empty-state">
      <Building2 class="h-10 w-10 op-30"/><p>Sin spas registrados</p>
      <button class="btn-primary" @click="openCrearSpa()">Crear el primero</button>
    </div>
    <div v-else class="spas-grid">
      <div v-for="spa in spas" :key="spa.id" class="spa-card" :class="!spa.activo && 'inactive'">
        <div class="spa-card-top">
          <div class="spa-avatar" :style="{ background: spa.color_primario }">
            {{ spa.nombre[0] }}
          </div>
          <div class="spa-info">
            <div class="spa-nombre">{{ spa.nombre }}</div>
            <div class="spa-slug">{{ spa.slug }}</div>
          </div>
          <div class="spa-actions">
            <button class="icon-btn" @click="openEditarSpa(spa)" title="Editar"><Pencil class="h-4 w-4"/></button>
            <button class="icon-btn" @click="toggleActivo(spa)" :title="spa.activo ? 'Desactivar' : 'Activar'">
              <component :is="spa.activo ? Pause : Play" class="h-4 w-4"/>
            </button>
          </div>
        </div>

        <div class="spa-meta-row">
          <span class="plan-badge" :class="`plan-${spa.plan}`">
            {{ planIcon(spa.plan) }} {{ spa.plan }}
          </span>
          <span :class="spa.activo ? 'badge-confirmada estado-badge' : 'badge-cancelada estado-badge'">
            {{ spa.activo ? 'Activo' : 'Inactivo' }}
          </span>
        </div>

        <div class="spa-stats">
          <div class="spa-stat">
            <Users class="h-3 w-3"/> {{ spa._usuarios ?? 0 }} usuarios
          </div>
          <div class="spa-stat">
            <CalendarDays class="h-3 w-3"/> Creado {{ fmtDate(spa.created_at) }}
          </div>
        </div>

        <!-- Trial -->
        <div v-if="spa.trial_hasta" class="trial-bar">
          <div class="trial-fill" :style="{ width: trialPct(spa.trial_hasta) + '%' }"/>
          <span class="trial-lbl">Trial hasta {{ fmtDate(spa.trial_hasta) }}</span>
        </div>
      </div>
    </div>

    <!-- ── Sección: Usuarios globales ───────────────────────────────── -->
    <div class="section-header">
      <div class="section-title"><UserCog class="h-5 w-5"/> Usuarios globales</div>
      <input v-model="userSearch" class="search-input" placeholder="Buscar por nombre o email…" />
    </div>

    <div v-if="loadingUsers" class="empty-state"><div class="spinner"/><p>Cargando usuarios...</p></div>
    <div v-else-if="filteredUsers.length === 0" class="empty-state">
      <Users class="h-8 w-8 op-30"/><p>No hay usuarios registrados</p>
    </div>
    <div v-else class="usuarios-table card-spa">
      <table class="spa-table">
        <thead>
          <tr>
            <th>Usuario</th>
            <th>Spa asignado</th>
            <th>Rol</th>
            <th>Desde</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="u in filteredUsers" :key="u.id">
            <td>
              <div class="user-row">
                <div class="user-avatar" :style="avatarStyle(u.full_name || u.email)">
                  {{ initials(u.full_name || u.email) }}
                </div>
                <div>
                  <div class="user-nombre">{{ u.full_name || '(Sin nombre)' }}</div>
                  <div class="user-email">{{ u.email }}</div>
                </div>
              </div>
            </td>
            <td>
              <select class="rol-select" :value="u.spa_id ?? ''" @change="cambiarSpa(u, ($event.target as HTMLSelectElement).value)">
                <option value="">— Sin spa —</option>
                <option v-for="s in spas" :key="s.id" :value="s.id">{{ s.nombre }}</option>
              </select>
            </td>
            <td>
              <select class="rol-select" :value="u.role" @change="cambiarRolGlobal(u, ($event.target as HTMLSelectElement).value)">
                <option value="superadmin">Superadmin</option>
                <option value="admin_spa">Admin spa</option>
                <option value="recepcionista">Recepcionista</option>
                <option value="terapeuta">Terapeuta</option>
              </select>
            </td>
            <td class="date-col">{{ fmtDate(u.created_at) }}</td>
            <td class="actions-cell">
              <button class="icon-btn danger" @click="revocarAcceso(u)" title="Revocar acceso (quitar spa)">
                <Trash2 class="h-4 w-4"/>
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Modal: Crear / Editar spa -->
    <Teleport to="body">
      <div v-if="showSpaForm" class="modal-backdrop" @click.self="showSpaForm = false">
        <div class="modal-box">
          <div class="modal-header">
            <h2>{{ editandoSpa ? 'Editar spa' : 'Nuevo spa' }}</h2>
            <button class="icon-btn" @click="showSpaForm = false"><X class="h-5 w-5"/></button>
          </div>
          <form @submit.prevent="guardarSpa" class="modal-form">
            <div class="field">
              <label>Nombre *</label>
              <input v-model="spaForm.nombre" required placeholder="Ej. Lotus Wellness Spa"/>
            </div>
            <div class="field">
              <label>Slug (URL) *</label>
              <div class="input-prefix"><span>spaflow.mx/</span><input v-model="spaForm.slug" required placeholder="lotus-spa"/></div>
            </div>
            <div class="fields-row">
              <div class="field">
                <label>Plan</label>
                <select v-model="spaForm.plan">
                  <option value="basic">🌱 Básico</option>
                  <option value="pro">⭐ Pro</option>
                  <option value="enterprise">👑 Enterprise</option>
                </select>
              </div>
              <div class="field">
                <label>Color principal</label>
                <div class="color-row">
                  <div class="color-preview" :style="{ background: spaForm.color_primario }"/>
                  <input v-model="spaForm.color_primario" type="color" class="color-input"/>
                </div>
              </div>
            </div>
            <div class="field">
              <label>Trial hasta (opcional)</label>
              <input v-model="spaForm.trial_hasta" type="date"/>
            </div>
            <div class="field-check">
              <label class="check-label"><input type="checkbox" v-model="spaForm.activo"/> Spa activo</label>
            </div>
            <div v-if="spaError" class="form-error">{{ spaError }}</div>
            <div class="modal-footer">
              <button type="button" class="btn-ghost" @click="showSpaForm = false">Cancelar</button>
              <button type="submit" class="btn-primary" :disabled="savingSpa">
                <Loader2 v-if="savingSpa" class="h-4 w-4 animate-spin"/>
                {{ editandoSpa ? 'Guardar cambios' : 'Crear spa' }}
              </button>
            </div>
          </form>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { supabase } from '../lib/supabase'
import { Building2, Users, Plus, Pencil, Play, Pause, CalendarDays, X, Loader2, UserCog, Trash2 } from 'lucide-vue-next'

interface SpaRow {
  id: string
  nombre: string
  slug: string
  color_primario: string
  plan: string
  activo: boolean
  trial_hasta: string | null
  created_at: string
  _usuarios?: number
}

const spas = ref<SpaRow[]>([])
const loading = ref(false)
const totalUsuarios = computed(() => spas.value.reduce((s, sp) => s + (sp._usuarios ?? 0), 0))

async function fetchSpas() {
  loading.value = true
  const { data } = await supabase
    .from('spas')
    .select('*')
    .order('created_at', { ascending: false })
  const rows = (data ?? []) as SpaRow[]

  // Contar usuarios por spa
  for (const spa of rows) {
    const { count } = await supabase
      .from('profiles')
      .select('id', { count: 'exact', head: true })
      .eq('spa_id', spa.id)
    spa._usuarios = count ?? 0
  }
  spas.value = rows
  loading.value = false
}

const fmtDate = (d: string) =>
  new Date(d).toLocaleDateString('es-MX', { day: 'numeric', month: 'short', year: 'numeric' })

const planIcon = (p: string) => ({ basic: '🌱', pro: '⭐', enterprise: '👑' }[p] ?? '🌿')

function trialPct(d: string) {
  const total = 30 * 86400000
  const reste = new Date(d).getTime() - Date.now()
  return Math.max(0, Math.min(100, (reste / total) * 100))
}

async function toggleActivo(spa: SpaRow) {
  await supabase.from('spas').update({ activo: !spa.activo }).eq('id', spa.id)
  spa.activo = !spa.activo
}

// Form
const showSpaForm = ref(false)
const savingSpa = ref(false)
const spaError = ref<string | null>(null)
const editandoSpa = ref<SpaRow | null>(null)

const emptySpaForm = () => ({
  nombre: '', slug: '', plan: 'basic', color_primario: '#8b5cf6',
  trial_hasta: '', activo: true,
})
const spaForm = ref(emptySpaForm())

function openCrearSpa() { editandoSpa.value = null; spaForm.value = emptySpaForm(); spaError.value = null; showSpaForm.value = true }
function openEditarSpa(s: SpaRow) {
  editandoSpa.value = s
  spaForm.value = { nombre: s.nombre, slug: s.slug, plan: s.plan, color_primario: s.color_primario, trial_hasta: s.trial_hasta ?? '', activo: s.activo }
  spaError.value = null
  showSpaForm.value = true
}

async function guardarSpa() {
  spaError.value = null
  savingSpa.value = true
  const payload = {
    ...spaForm.value,
    trial_hasta: spaForm.value.trial_hasta || null,
  }
  try {
    if (editandoSpa.value) {
      const { error } = await supabase.from('spas').update(payload).eq('id', editandoSpa.value.id)
      if (error) throw error
    } else {
      const { error } = await supabase.from('spas').insert(payload)
      if (error) throw error
    }
    showSpaForm.value = false
    await fetchSpas()
  } catch (e: any) {
    spaError.value = e.message ?? 'Error al guardar'
  } finally { savingSpa.value = false }
}

// ── Usuarios globales ────────────────────────────────────────────────────
interface UsuarioGlobal {
  id: string
  email: string
  full_name: string | null
  role: string
  spa_id: string | null
  created_at: string
}

const todosUsuarios = ref<UsuarioGlobal[]>([])
const loadingUsers = ref(false)
const userSearch = ref('')

const filteredUsers = computed(() => {
  const q = userSearch.value.toLowerCase().trim()
  if (!q) return todosUsuarios.value
  return todosUsuarios.value.filter(u =>
    (u.email ?? '').toLowerCase().includes(q) ||
    (u.full_name ?? '').toLowerCase().includes(q)
  )
})

async function fetchUsuarios() {
  loadingUsers.value = true
  const { data } = await supabase
    .from('profiles')
    .select('id, email, full_name, role, spa_id, created_at')
    .order('created_at', { ascending: false })
  todosUsuarios.value = (data ?? []) as UsuarioGlobal[]
  loadingUsers.value = false
}

async function cambiarRolGlobal(u: UsuarioGlobal, newRole: string) {
  const { error } = await supabase.from('profiles').update({ role: newRole }).eq('id', u.id)
  if (!error) u.role = newRole
}

async function cambiarSpa(u: UsuarioGlobal, newSpaId: string) {
  const val = newSpaId || null
  const { error } = await supabase.from('profiles').update({ spa_id: val }).eq('id', u.id)
  if (!error) u.spa_id = val
}

async function revocarAcceso(u: UsuarioGlobal) {
  if (!confirm(`¿Quitar el spa asignado a ${u.email}? El usuario quedará sin acceso hasta que se le asigne uno.`)) return
  const { error } = await supabase.from('profiles').update({ spa_id: null }).eq('id', u.id)
  if (!error) u.spa_id = null
}

const AVATAR_COLORS = ['#8b5cf6','#ec4899','#f59e0b','#10b981','#3b82f6']
function avatarStyle(s: string) { return { background: AVATAR_COLORS[(s ?? 'A').charCodeAt(0) % AVATAR_COLORS.length] } }
function initials(s: string) { return (s ?? '?').split(/[\s@]/).slice(0,2).map(w => w[0]).join('').toUpperCase() }

onMounted(() => { fetchSpas(); fetchUsuarios() })
</script>

<style scoped>
.view-page { padding: 24px; max-width: 1100px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px; gap: 12px; }
.page-header h1 { font-size: 26px; font-weight: 700; color: var(--foreground); margin: 0; }
.page-sub { color: var(--muted-foreground); font-size: 14px; margin: 4px 0 0; }

.global-kpis { display: flex; gap: 12px; margin-bottom: 20px; flex-wrap: wrap; }
.kpi-pill { display: flex; align-items: center; gap: 8px; padding: 10px 18px; background: var(--card); border: 1px solid var(--border); border-radius: 999px; font-size: 13px; color: var(--muted-foreground); }
.kv { font-weight: 800; font-size: 18px; color: var(--primary); }

.spas-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(320px, 1fr)); gap: 16px; }
.spa-card { background: var(--card); border: 1px solid var(--border); border-radius: var(--radius); padding: 20px; display: flex; flex-direction: column; gap: 12px; transition: box-shadow .2s; }
.spa-card:hover { box-shadow: 0 4px 20px rgba(0,0,0,.1); }
.spa-card.inactive { opacity: .55; }

.spa-card-top { display: flex; align-items: center; gap: 12px; }
.spa-avatar { width: 44px; height: 44px; border-radius: 12px; display: flex; align-items: center; justify-content: center; color: white; font-weight: 800; font-size: 20px; flex-shrink: 0; }
.spa-info { flex: 1; min-width: 0; }
.spa-nombre { font-weight: 700; font-size: 16px; color: var(--foreground); }
.spa-slug { font-size: 12px; color: var(--muted-foreground); font-family: monospace; }
.spa-actions { display: flex; gap: 4px; }

.spa-meta-row { display: flex; align-items: center; gap: 8px; }
.plan-badge { display: inline-flex; align-items: center; gap: 4px; padding: 3px 10px; border-radius: 999px; font-size: 12px; font-weight: 700; text-transform: uppercase; }
.plan-basic { background: var(--muted); color: var(--muted-foreground); }
.plan-pro { background: #fef3c7; color: #92400e; }
.plan-enterprise { background: #e0e7ff; color: #3730a3; }
:is(.dark) .plan-pro { background: #451a03; color: #fde68a; }
:is(.dark) .plan-enterprise { background: #1e1b4b; color: #a5b4fc; }

.spa-stats { display: flex; gap: 12px; flex-wrap: wrap; }
.spa-stat { display: flex; align-items: center; gap: 5px; font-size: 12px; color: var(--muted-foreground); }

.trial-bar { position: relative; height: 6px; background: var(--border); border-radius: 3px; overflow: hidden; }
.trial-fill { height: 100%; background: var(--primary); border-radius: 3px; transition: width .6s; }
.trial-lbl { position: absolute; top: 10px; left: 0; font-size: 10px; color: var(--muted-foreground); }

/* Color picker */
.color-row { display: flex; align-items: center; gap: 8px; }
.color-preview { width: 32px; height: 32px; border-radius: 8px; border: 1.5px solid var(--border); }
.color-input { width: 32px; height: 32px; border: none; padding: 0; border-radius: 6px; cursor: pointer; }

/* Estado badges */
.estado-badge { display: inline-block; padding: 3px 10px; border-radius: 999px; font-size: 11px; font-weight: 700; }
.badge-confirmada { background: #d1fae5; color: #065f46; }
.badge-cancelada  { background: #fee2e2; color: #991b1b; }
:is(.dark) .badge-confirmada { background: #064e3b; color: #6ee7b7; }
:is(.dark) .badge-cancelada  { background: #450a0a; color: #fca5a5; }

/* Common */
.op-30 { opacity: .3; }
.icon-btn { display: inline-flex; align-items: center; justify-content: center; width: 30px; height: 30px; border-radius: 8px; border: 1px solid var(--border); background: transparent; color: var(--muted-foreground); cursor: pointer; transition: all .15s; }
.icon-btn:hover { background: var(--muted); }
.empty-state { padding: 60px; text-align: center; display: flex; flex-direction: column; align-items: center; gap: 12px; color: var(--muted-foreground); }
.spinner { width: 28px; height: 28px; border: 3px solid var(--border); border-top-color: var(--primary); border-radius: 50%; animation: spin .6s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
.modal-backdrop { position: fixed; inset: 0; background: rgba(0,0,0,.45); backdrop-filter: blur(4px); z-index: 200; display: flex; align-items: center; justify-content: center; padding: 16px; }
.modal-box { background: var(--card); border-radius: calc(var(--radius) + 4px); width: 100%; max-width: 480px; box-shadow: 0 20px 60px rgba(0,0,0,.25); max-height: 90vh; overflow-y: auto; }
.modal-header { display: flex; align-items: center; justify-content: space-between; padding: 20px 24px 0; }
.modal-header h2 { font-size: 18px; font-weight: 700; color: var(--foreground); margin: 0; }
.modal-form { padding: 18px 24px 22px; display: flex; flex-direction: column; gap: 14px; }
.modal-footer { display: flex; justify-content: flex-end; gap: 10px; padding-top: 8px; border-top: 1px solid var(--border); }
.field { display: flex; flex-direction: column; gap: 5px; }
.field label { font-size: 13px; font-weight: 600; color: var(--foreground); }
.field input, .field select { padding: 9px 12px; border: 1.5px solid var(--border); border-radius: var(--radius); background: var(--background); color: var(--foreground); font-size: 14px; }
.field input:focus, .field select:focus { outline: none; border-color: var(--primary); }
.fields-row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }
.input-prefix { display: flex; }
.input-prefix span { padding: 9px 10px; background: var(--muted); border: 1.5px solid var(--border); border-right: none; border-radius: var(--radius) 0 0 var(--radius); color: var(--muted-foreground); font-size: 14px; white-space: nowrap; }
.input-prefix input { border-radius: 0 var(--radius) var(--radius) 0; flex: 1; min-width: 0; }
.field-check { display: flex; align-items: center; }
.check-label { display: flex; align-items: center; gap: 8px; font-size: 14px; font-weight: 600; cursor: pointer; }
.form-error { padding: 10px 14px; background: #fee2e2; color: #dc2626; border-radius: var(--radius); font-size: 13px; }
:is(.dark) .form-error { background: #450a0a; color: #f87171; }

@media (max-width: 640px) { .view-page { padding: 16px; } .spas-grid { grid-template-columns: 1fr; } }

/* ── Usuarios globales ── */
.section-header { display: flex; align-items: center; justify-content: space-between; margin: 32px 0 14px; gap: 12px; flex-wrap: wrap; }
.section-title { display: flex; align-items: center; gap: 8px; font-size: 18px; font-weight: 700; color: var(--foreground); }
.search-input { padding: 8px 12px; border: 1.5px solid var(--border); border-radius: var(--radius); background: var(--background); color: var(--foreground); font-size: 13px; width: 240px; }
.search-input:focus { outline: none; border-color: var(--primary); }
.usuarios-table { padding: 0; overflow-x: auto; margin-bottom: 24px; }
.spa-table { width: 100%; border-collapse: collapse; min-width: 580px; }
.spa-table th { padding: 10px 14px; text-align: left; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .06em; color: var(--muted-foreground); border-bottom: 2px solid var(--border); }
.spa-table td { padding: 12px 14px; border-bottom: 1px solid var(--border); vertical-align: middle; }
.user-row { display: flex; align-items: center; gap: 10px; }
.user-avatar { width: 34px; height: 34px; border-radius: 9px; display: flex; align-items: center; justify-content: center; color: white; font-weight: 700; font-size: 12px; flex-shrink: 0; }
.user-nombre { font-weight: 600; font-size: 13px; color: var(--foreground); }
.user-email { font-size: 11px; color: var(--muted-foreground); }
.date-col { color: var(--muted-foreground); font-size: 12px; white-space: nowrap; }
.actions-cell { display: flex; justify-content: flex-end; gap: 6px; }
.rol-select { padding: 5px 8px; border: 1.5px solid var(--border); border-radius: var(--radius); background: var(--background); color: var(--foreground); font-size: 12px; font-weight: 600; cursor: pointer; max-width: 160px; }
.rol-select:focus { outline: none; border-color: var(--primary); }

</style>
