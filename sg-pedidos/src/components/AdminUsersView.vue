<template>
  <div class="p-6 users-page">
    <header class="page-header">
      <div>
        <h1 class="page-title">Usuarios</h1>
        <p class="page-sub">Administra accesos y cambia roles desde la app</p>
      </div>
    </header>

    <section class="stats-grid">
      <div class="stat-card">
        <div class="stat-num">{{ profiles.length }}</div>
        <div class="stat-label">Total usuarios</div>
      </div>
      <div class="stat-card">
        <div class="stat-num">{{ adminCount }}</div>
        <div class="stat-label">Administradores</div>
      </div>
      <div class="stat-card">
        <div class="stat-num">{{ employeeCount }}</div>
        <div class="stat-label">Empleados</div>
      </div>
      <div class="stat-card">
        <div class="stat-num">{{ filteredProfiles.length }}</div>
        <div class="stat-label">Coincidencias</div>
      </div>
    </section>

    <section class="create-section">
      <div class="create-header">
        <div>
          <h2>Nuevo usuario</h2>
          <p class="section-note">Se crea con acceso inmediato. El correo queda confirmado al momento del alta.</p>
        </div>
        <button class="btn-ghost" @click="toggleCreateForm">
          {{ showCreateForm ? 'Ocultar formulario' : 'Crear usuario' }}
        </button>
      </div>

      <form v-if="showCreateForm" class="create-form" @submit.prevent="handleCreateUser">
        <div class="form-grid">
          <label>
            <span>Nombre</span>
            <input v-model="createForm.full_name" type="text" class="input" placeholder="Nombre del usuario" />
          </label>

          <label>
            <span>Correo</span>
            <input v-model="createForm.email" type="email" class="input" placeholder="usuario@correo.com" required />
          </label>

          <label>
            <span>Contrasena</span>
            <input v-model="createForm.password" type="password" class="input" placeholder="Minimo 8 caracteres" required />
          </label>

          <label>
            <span>Confirmar contrasena</span>
            <input v-model="createForm.confirmPassword" type="password" class="input" placeholder="Repite la contrasena" required />
          </label>

          <label>
            <span>Rol</span>
            <select v-model="createForm.role" class="input">
              <option value="empleado">Empleado</option>
              <option value="admin">Administrador</option>
            </select>
          </label>
        </div>

        <div class="create-actions">
          <button class="btn-primary" type="submit" :disabled="creating">
            {{ creating ? 'Creando...' : 'Crear usuario' }}
          </button>
          <button class="btn-ghost" type="button" @click="resetCreateForm">Limpiar</button>
        </div>
      </form>
    </section>

    <section class="mt-8 list-section">
      <div v-if="infoMsg" class="info-toast">{{ infoMsg }}</div>
      <div v-if="localError" class="error-toast">{{ localError }}</div>

      <h2>Listado</h2>
      <p class="section-note">El sistema siempre conserva al menos un administrador activo.</p>

      <div class="list-controls">
        <div class="search-wrap">
          <input v-model="searchTerm" placeholder="Buscar por nombre o correo..." />
        </div>

        <select v-model="roleFilter" class="input role-filter">
          <option value="ALL">Todos los roles</option>
          <option value="admin">Administrador</option>
          <option value="empleado">Empleado</option>
        </select>

        <button class="btn-ghost" @click="reloadProfiles">Actualizar</button>
      </div>

      <p v-if="loading">Cargando...</p>
      <p v-else-if="errorMsg">⚠️ {{ errorMsg }}</p>

      <div v-else class="orders-table">
        <div class="orders-row header">
          <div>Usuario</div>
          <div>Correo</div>
          <div>Rol actual</div>
          <div>Nuevo rol</div>
          <div>Alta</div>
          <div>Acciones</div>
        </div>

        <div v-for="profileItem in filteredProfiles" :key="profileItem.id" class="orders-row">
          <div class="user-cell">
            <div class="user-name">{{ profileItem.full_name || 'Sin nombre' }}</div>
            <div class="user-sub">
              <span v-if="profileItem.id === currentUserId">Tu cuenta</span>
              <span v-else>Usuario registrado</span>
              <span v-if="isLastAdmin(profileItem)"> · Último admin protegido</span>
            </div>
          </div>

          <div class="email-cell">{{ profileItem.email || 'Sin correo' }}</div>

          <div>
            <span :class="rolePillClasses(profileItem.role)">{{ roleLabel(profileItem.role) }}</span>
          </div>

          <div>
            <select
              v-model="draftRoles[profileItem.id]"
              class="input role-select"
              :disabled="savingUserId === profileItem.id || isLastAdmin(profileItem)"
            >
              <option value="admin">Administrador</option>
              <option value="empleado">Empleado</option>
            </select>
          </div>

          <div>{{ formatDate(profileItem.created_at) }}</div>

          <div class="actions">
            <button
              class="btn-primary"
              :disabled="isSaveDisabled(profileItem)"
              @click="saveRole(profileItem)"
            >
              {{ savingUserId === profileItem.id ? 'Guardando...' : 'Guardar' }}
            </button>
          </div>
        </div>

        <div v-if="!filteredProfiles.length" class="empty-state">
          No hay usuarios que coincidan con el filtro actual.
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { getDefaultRouteForRole, useAuth } from '../composables/useAuth'
import { useFormat } from '../composables/useFormat'
import { useUserProfiles } from '../composables/useUserProfiles'
import type { AppRole, UserProfile } from '../types'

const { profiles, loading, creating, errorMsg, fetchProfiles, updateUserRole, createUser } = useUserProfiles()
const { user, refreshProfile } = useAuth()
const { formatDate } = useFormat()
const router = useRouter()

const searchTerm = ref('')
const roleFilter = ref<'ALL' | AppRole>('ALL')
const showCreateForm = ref(false)
const savingUserId = ref<string | null>(null)
const infoMsg = ref<string | null>(null)
const localError = ref<string | null>(null)
const draftRoles = reactive<Record<string, AppRole>>({})
const createForm = reactive({
  full_name: '',
  email: '',
  password: '',
  confirmPassword: '',
  role: 'empleado' as AppRole
})

const currentUserId = computed(() => user.value?.id ?? null)

const adminCount = computed(() => profiles.value.filter((profile) => profile.role === 'admin').length)
const employeeCount = computed(() => profiles.value.filter((profile) => profile.role === 'empleado').length)

const filteredProfiles = computed(() => {
  const q = searchTerm.value.trim().toLowerCase()

  return profiles.value.filter((profile) => {
    if (roleFilter.value !== 'ALL' && profile.role !== roleFilter.value) return false

    if (!q) return true

    const fullName = (profile.full_name || '').toLowerCase()
    const email = (profile.email || '').toLowerCase()
    return fullName.includes(q) || email.includes(q)
  })
})

function syncDraftRoles() {
  for (const key of Object.keys(draftRoles)) delete draftRoles[key]
  for (const profile of profiles.value) draftRoles[profile.id] = profile.role
}

function resetCreateForm() {
  createForm.full_name = ''
  createForm.email = ''
  createForm.password = ''
  createForm.confirmPassword = ''
  createForm.role = 'empleado'
}

function toggleCreateForm() {
  showCreateForm.value = !showCreateForm.value
  if (!showCreateForm.value) resetCreateForm()
}

async function reloadProfiles() {
  localError.value = null
  await fetchProfiles()
  syncDraftRoles()
}

function roleLabel(role: AppRole) {
  return role === 'admin' ? 'Administrador' : 'Empleado'
}

function rolePillClasses(role: AppRole) {
  return role === 'admin'
    ? ['role-pill', 'role-admin']
    : ['role-pill', 'role-employee']
}

function isLastAdmin(profile: UserProfile) {
  return profile.role === 'admin' && adminCount.value === 1
}

function isSaveDisabled(profile: UserProfile) {
  return savingUserId.value === profile.id
    || isLastAdmin(profile)
    || draftRoles[profile.id] === profile.role
}

async function handleCreateUser() {
  localError.value = null
  infoMsg.value = null

  if (!createForm.email.trim()) {
    localError.value = 'El correo es obligatorio'
    return
  }

  if (createForm.password.length < 8) {
    localError.value = 'La contrasena debe tener al menos 8 caracteres'
    return
  }

  if (createForm.password !== createForm.confirmPassword) {
    localError.value = 'Las contrasenas no coinciden'
    return
  }

  try {
    const createdProfile = await createUser({
      email: createForm.email,
      password: createForm.password,
      full_name: createForm.full_name || null,
      role: createForm.role
    })

    draftRoles[createdProfile.id] = createdProfile.role
    infoMsg.value = `Usuario creado: ${createdProfile.email || createdProfile.full_name || 'nuevo usuario'}`
    setTimeout(() => { infoMsg.value = null }, 3000)
    resetCreateForm()
    showCreateForm.value = false
  } catch (error: any) {
    localError.value = error?.message || 'No se pudo crear el usuario'
  }
}

async function saveRole(profile: UserProfile) {
  const nextRole = draftRoles[profile.id]
  if (!nextRole || nextRole === profile.role) return

  localError.value = null
  infoMsg.value = null
  savingUserId.value = profile.id

  try {
    const updatedProfile = await updateUserRole(profile.id, nextRole)
    draftRoles[profile.id] = updatedProfile.role
    infoMsg.value = `Rol actualizado para ${updatedProfile.full_name || updatedProfile.email || 'el usuario'}`
    setTimeout(() => { infoMsg.value = null }, 2500)

    if (updatedProfile.id === currentUserId.value) {
      await refreshProfile()
      if (updatedProfile.role !== 'admin') {
        router.push(getDefaultRouteForRole(updatedProfile.role))
      }
    }
  } catch (error: any) {
    localError.value = error?.message || 'No se pudo actualizar el rol'
    draftRoles[profile.id] = profile.role
  } finally {
    savingUserId.value = null
  }
}

onMounted(async () => {
  await reloadProfiles()
})
</script>

<style scoped>
.page-header { display:flex;justify-content:space-between;align-items:center;margin-bottom:12px;flex-wrap:wrap;gap:8px }
.page-title { margin:0;font-size:1.25rem }
.page-sub { margin:0;color:#666 }
.section-note { margin:4px 0 0;color:#64748b;font-size:0.92rem }
.stats-grid { display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:12px;margin:12px 0 }
.stat-card { background:#fff;border:1px solid #eee;padding:12px;border-radius:8px }
.stat-num { font-weight:700;font-size:1.1rem }
.stat-label { color:#666 }
.create-section { background:#fff;border:1px solid #eee;border-radius:8px;padding:16px;margin-top:16px }
.create-header { display:flex;justify-content:space-between;align-items:flex-start;gap:12px;flex-wrap:wrap }
.create-form { margin-top:16px }
.form-grid { display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:12px }
.form-grid label { display:flex;flex-direction:column;gap:6px;font-weight:600;color:#334155 }
.create-actions { display:flex;justify-content:flex-end;gap:8px;margin-top:14px;flex-wrap:wrap }
.list-controls { display:flex;justify-content:space-between;align-items:center;gap:12px;margin-top:12px;margin-bottom:8px;flex-wrap:wrap }
.search-wrap { flex:1;min-width:260px }
.search-wrap input { width:100%;padding:12px;border:1px solid #ddd;border-radius:6px;box-sizing:border-box }
.input { padding:10px 12px;border:1px solid #ddd;border-radius:6px;background:#fff }
.role-filter { min-width:170px }
.role-select { width:100% }
.btn-primary { background:#059669;color:white;padding:8px 12px;border-radius:6px;border:none;white-space:nowrap }
.btn-primary:disabled { opacity:.55;cursor:not-allowed }
.btn-ghost { background:#fff;border:1px solid #ddd;padding:8px 12px;border-radius:6px;cursor:pointer }
.orders-table { margin-top:12px;border-top:1px solid #eee;overflow-x:auto;-webkit-overflow-scrolling:touch }
.orders-row { display:grid;grid-template-columns:2fr 2fr 1fr 1fr 1.25fr 1fr;align-items:center;padding:12px;border-bottom:1px solid #f3f3f3;min-width:860px;gap:12px }
.orders-row.header { font-weight:600;color:#444;background:#fafafa }
.user-cell { display:flex;flex-direction:column;gap:4px }
.user-name { font-weight:700 }
.user-sub { color:#64748b;font-size:0.85rem }
.email-cell { word-break:break-word }
.actions { display:flex;justify-content:flex-end }
.role-pill { display:inline-flex;align-items:center;justify-content:center;padding:5px 10px;border-radius:999px;font-weight:700;font-size:12px;text-transform:uppercase;letter-spacing:.04em }
.role-admin { background:#dbeafe;color:#1d4ed8 }
.role-employee { background:#ecfccb;color:#3f6212 }
.info-toast { background:#ecfdf5;border:1px solid #bbf7d0;color:#065f46;padding:8px 12px;border-radius:8px;margin-bottom:8px }
.error-toast { background:#fef2f2;border:1px solid #fecaca;color:#b91c1c;padding:8px 12px;border-radius:8px;margin-bottom:8px }
.empty-state { padding:16px;color:#64748b;text-align:center }

@media (max-width: 768px) {
  .page-header { flex-direction:column;align-items:flex-start }
  .stats-grid { grid-template-columns:repeat(2,1fr);gap:8px }
  .create-header { flex-direction:column;align-items:stretch }
  .list-controls { flex-direction:column;align-items:stretch }
  .search-wrap { min-width:0 }
}

/* Dark mode */
:is(.dark) .users-page{background:transparent}
:is(.dark) .page-title{color:#e2e8f0}
:is(.dark) .page-sub{color:#94a3b8}
:is(.dark) .section-note{color:#94a3b8}
:is(.dark) .stat-card{background:#111c2e;border-color:#1e293b}
:is(.dark) .stat-num{color:#e2e8f0}
:is(.dark) .stat-label{color:#94a3b8}
:is(.dark) .create-section{background:#111c2e;border-color:#1e293b}
:is(.dark) .form-grid label{color:#cbd5e1}
:is(.dark) .search-wrap input{background:#0f1729;border-color:#334155;color:#e2e8f0}
:is(.dark) .search-wrap input::placeholder{color:#475569}
:is(.dark) .input{background:#0f1729;border-color:#334155;color:#e2e8f0}
:is(.dark) .btn-ghost{background:#0f1729;border-color:#334155;color:#cbd5e1}
:is(.dark) .orders-table{border-top-color:#1e293b}
:is(.dark) .orders-row{border-bottom-color:#1e293b;color:#cbd5e1}
:is(.dark) .orders-row.header{background:#0f1729;color:#94a3b8}
:is(.dark) .user-name{color:#e2e8f0}
:is(.dark) .user-sub{color:#94a3b8}
:is(.dark) .role-admin{background:#1e3a8a;color:#bfdbfe}
:is(.dark) .role-employee{background:#365314;color:#d9f99d}
:is(.dark) .info-toast{background:#052e16;border-color:#064e3b;color:#6ee7b7}
:is(.dark) .error-toast{background:#450a0a;border-color:#7f1d1d;color:#fca5a5}
:is(.dark) .empty-state{color:#94a3b8}
</style>