<template>
  <div class="view-page">
    <div class="page-header">
      <div>
        <h1 class="font-spa-display">Usuarios del spa</h1>
        <p class="page-sub">Gestiona el acceso del equipo</p>
      </div>
      <button class="btn-primary" @click="openInvite()"><UserPlus class="h-4 w-4"/> Agregar usuario</button>
    </div>

    <div v-if="loading" class="empty-state"><div class="spinner"/><p>Cargando usuarios...</p></div>
    <div v-else-if="usuarios.length === 0" class="empty-state">
      <Users class="h-10 w-10 op-30"/>
      <p>Aún no hay usuarios registrados</p>
      <button class="btn-primary" @click="openInvite()">Agregar el primero</button>
    </div>
    <div v-else class="usuarios-table card-spa">
      <table class="spa-table">
        <thead>
          <tr>
            <th>Usuario</th>
            <th>Rol</th>
            <th>Desde</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="u in usuarios" :key="u.id">
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
              <select class="rol-select" :value="u.role" @change="cambiarRol(u, ($event.target as HTMLSelectElement).value)">
                <option value="admin_spa">Admin spa</option>
                <option value="recepcionista">Recepcionista</option>
                <option value="terapeuta">Terapeuta</option>
              </select>
            </td>
            <td class="date-col">{{ fmtDate(u.created_at) }}</td>
            <td class="actions-cell">
              <button class="icon-btn danger" @click="eliminarAcceso(u)" title="Revocar acceso">
                <UserX class="h-4 w-4"/>
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Modal: Invitar/crear usuario -->
    <Teleport to="body">
      <div v-if="showInvite" class="modal-backdrop" @click.self="showInvite = false">
        <div class="modal-box">
          <div class="modal-header">
            <h2>Agregar usuario al spa</h2>
            <button class="icon-btn" @click="showInvite = false"><X class="h-5 w-5"/></button>
          </div>
          <div class="modal-form">
            <div class="info-banner">
              <Info class="h-4 w-4 flex-shrink-0"/>
              <p>Crea primero el usuario en <strong>Supabase → Authentication → Users</strong>, luego registra su email aquí para asignarle acceso al spa.</p>
            </div>
            <div class="field">
              <label>Email del usuario *</label>
              <input v-model="inviteForm.email" type="email" required placeholder="terapeuta@mispa.com"/>
            </div>
            <div class="field">
              <label>Nombre completo</label>
              <input v-model="inviteForm.nombre" placeholder="Ej. Sofía Ramírez"/>
            </div>
            <div class="field">
              <label>Rol *</label>
              <select v-model="inviteForm.rol">
                <option value="recepcionista">Recepcionista</option>
                <option value="terapeuta">Terapeuta</option>
                <option value="admin_spa">Admin spa</option>
              </select>
            </div>
            <div v-if="inviteError" class="form-error">{{ inviteError }}</div>
            <div class="modal-footer">
              <button class="btn-ghost" @click="showInvite = false">Cancelar</button>
              <button class="btn-primary" @click="asignarAcceso" :disabled="savingInvite">
                <Loader2 v-if="savingInvite" class="h-4 w-4 animate-spin"/> Asignar acceso
              </button>
            </div>
          </div>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '../lib/supabase'
import { useTenant } from '../composables/useTenant'
import { Users, UserPlus, UserX, X, Loader2, Info } from 'lucide-vue-next'

const { spaId } = useTenant()

interface UsuarioPerfil {
  id: string
  email: string
  full_name: string | null
  role: string
  created_at: string
}

const usuarios = ref<UsuarioPerfil[]>([])
const loading = ref(false)

async function fetchUsuarios() {
  if (!spaId.value) return
  loading.value = true
  const { data } = await supabase
    .from('profiles')
    .select('id, email, full_name, role, created_at')
    .eq('spa_id', spaId.value)
    .order('created_at', { ascending: false })
  usuarios.value = (data ?? []) as UsuarioPerfil[]
  loading.value = false
}

function fmtDate(d: string) {
  return new Date(d).toLocaleDateString('es-MX', { day: 'numeric', month: 'short', year: 'numeric' })
}
const AVATAR_COLORS = ['#8b5cf6','#ec4899','#f59e0b','#10b981','#3b82f6']
function avatarStyle(s: string) { return { background: AVATAR_COLORS[s.charCodeAt(0) % AVATAR_COLORS.length] } }
function initials(s: string) { return s.split(/[\s@]/).slice(0,2).map(w => w[0]).join('').toUpperCase() }

async function cambiarRol(u: UsuarioPerfil, newRole: string) {
  await supabase.from('profiles').update({ role: newRole }).eq('id', u.id)
  u.role = newRole
}

async function eliminarAcceso(u: UsuarioPerfil) {
  if (!confirm(`¿Revocar acceso de ${u.email}? El usuario existirá en Auth pero sin acceso al spa.`)) return
  await supabase.from('profiles').update({ spa_id: null, role: 'terapeuta' }).eq('id', u.id)
  await fetchUsuarios()
}

// Invitar usuario
const showInvite = ref(false)
const savingInvite = ref(false)
const inviteError = ref<string | null>(null)
const inviteForm = ref({ email: '', nombre: '', rol: 'recepcionista' })

function openInvite() { inviteForm.value = { email: '', nombre: '', rol: 'recepcionista' }; inviteError.value = null; showInvite.value = true }

async function asignarAcceso() {
  if (!inviteForm.value.email || !spaId.value) return
  inviteError.value = null
  savingInvite.value = true
  try {
    // Buscar perfil por email
    const { data: p, error } = await supabase
      .from('profiles')
      .select('id')
      .eq('email', inviteForm.value.email)
      .maybeSingle()

    if (error) throw error
    if (!p) throw new Error(`No se encontró usuario con email "${inviteForm.value.email}". Asegúrate de crearlo primero en Supabase Auth.`)

    // Asignar spa_id y rol
    const { error: upErr } = await supabase.from('profiles').update({
      spa_id: spaId.value,
      role: inviteForm.value.rol,
      full_name: inviteForm.value.nombre || undefined,
    }).eq('id', p.id)

    if (upErr) throw upErr

    showInvite.value = false
    await fetchUsuarios()
  } catch (e: any) {
    inviteError.value = e.message ?? 'Error al asignar acceso'
  } finally { savingInvite.value = false }
}

onMounted(fetchUsuarios)
</script>

<style scoped>
.view-page { padding: 24px; max-width: 900px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 24px; gap: 12px; }
.page-header h1 { font-size: 26px; font-weight: 700; color: var(--foreground); margin: 0; }
.page-sub { color: var(--muted-foreground); font-size: 14px; margin: 4px 0 0; }

.usuarios-table { padding: 0; overflow-x: auto; }
.spa-table { width: 100%; border-collapse: collapse; min-width: 500px; }
.spa-table th { padding: 11px 16px; text-align: left; font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .06em; color: var(--muted-foreground); border-bottom: 2px solid var(--border); }
.spa-table td { padding: 14px 16px; border-bottom: 1px solid var(--border); vertical-align: middle; }

.user-row { display: flex; align-items: center; gap: 10px; }
.user-avatar { width: 36px; height: 36px; border-radius: 10px; display: flex; align-items: center; justify-content: center; color: white; font-weight: 700; font-size: 13px; flex-shrink: 0; }
.user-nombre { font-weight: 600; font-size: 14px; color: var(--foreground); }
.user-email { font-size: 12px; color: var(--muted-foreground); }
.date-col { color: var(--muted-foreground); font-size: 13px; }
.actions-cell { display: flex; justify-content: flex-end; gap: 6px; }

.rol-select { padding: 6px 10px; border: 1.5px solid var(--border); border-radius: var(--radius); background: var(--background); color: var(--foreground); font-size: 13px; font-weight: 600; cursor: pointer; }
.rol-select:focus { outline: none; border-color: var(--primary); }

.info-banner { display: flex; align-items: flex-start; gap: 10px; padding: 12px 14px; background: #eff6ff; border-radius: var(--radius); color: #1e40af; font-size: 13px; line-height: 1.5; }
:is(.dark) .info-banner { background: #1e3a5f; color: #93c5fd; }

.icon-btn { display: inline-flex; align-items: center; justify-content: center; width: 32px; height: 32px; border-radius: 8px; border: 1px solid var(--border); background: transparent; color: var(--muted-foreground); cursor: pointer; transition: all .15s; }
.icon-btn:hover { background: var(--muted); }
.icon-btn.danger:hover { background: #fee2e2; color: #dc2626; border-color: #dc2626; }
:is(.dark) .icon-btn.danger:hover { background: #450a0a; color: #f87171; border-color: #f87171; }

.empty-state { padding: 60px; text-align: center; display: flex; flex-direction: column; align-items: center; gap: 12px; color: var(--muted-foreground); }
.op-30 { opacity: .3; }
.spinner { width: 28px; height: 28px; border: 3px solid var(--border); border-top-color: var(--primary); border-radius: 50%; animation: spin .6s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
.modal-backdrop { position: fixed; inset: 0; background: rgba(0,0,0,.45); backdrop-filter: blur(4px); z-index: 200; display: flex; align-items: center; justify-content: center; padding: 16px; }
.modal-box { background: var(--card); border-radius: calc(var(--radius) + 4px); width: 100%; max-width: 460px; box-shadow: 0 20px 60px rgba(0,0,0,.25); }
.modal-header { display: flex; align-items: center; justify-content: space-between; padding: 20px 24px 0; }
.modal-header h2 { font-size: 18px; font-weight: 700; color: var(--foreground); margin: 0; }
.modal-form { padding: 18px 24px 22px; display: flex; flex-direction: column; gap: 14px; }
.modal-footer { display: flex; justify-content: flex-end; gap: 10px; padding-top: 8px; border-top: 1px solid var(--border); }
.field { display: flex; flex-direction: column; gap: 5px; }
.field label { font-size: 13px; font-weight: 600; color: var(--foreground); }
.field input, .field select { padding: 9px 12px; border: 1.5px solid var(--border); border-radius: var(--radius); background: var(--background); color: var(--foreground); font-size: 14px; }
.field input:focus, .field select:focus { outline: none; border-color: var(--primary); }
.form-error { padding: 10px 14px; background: #fee2e2; color: #dc2626; border-radius: var(--radius); font-size: 13px; }
:is(.dark) .form-error { background: #450a0a; color: #f87171; }

@media (max-width: 600px) { .view-page { padding: 16px; } }
</style>