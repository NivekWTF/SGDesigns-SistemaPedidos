<template>
  <div class="auth-card">
    <h3>Iniciar sesión</h3>

    <div v-if="user && user.id" class="logged">
      <p>Conectado como <strong>{{ profile?.email || user.email }}</strong></p>
      <div v-if="role" class="role-pill">Rol: {{ roleLabel }}</div>
      <div v-if="authError" class="error">{{ authError }}</div>
      <button class="btn-danger" @click="handleSignOut">Cerrar sesión</button>
    </div>

    <form v-else @submit.prevent="handleSignIn" class="form-grid">
      <label>Email</label>
      <input v-model="email" type="email" required class="input" />

      <label>Contraseña</label>
      <input v-model="password" type="password" required class="input" />

      <div class="actions">
        <button class="btn-primary" type="submit">Entrar</button>
        <button v-if="allowSelfSignup" type="button" class="btn-outline" @click="handleSignUp">Registrarse</button>
      </div>

      <div v-if="!allowSelfSignup" class="access-note">El acceso lo crea un administrador desde el panel de usuarios.</div>

      <div v-if="error" class="error">{{ error }}</div>
      <div v-if="info" class="info">{{ info }}</div>
      <div v-if="authError" class="error">{{ authError }}</div>
    </form>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { getDefaultRouteForRole, useAuth } from '../composables/useAuth'
import { useRouter } from 'vue-router'

const { user, profile, role, authError, signIn, signUp, signOut } = useAuth()
const router = useRouter()

const email = ref('')
const password = ref('')
const error = ref<string | null>(null)
const info = ref<string | null>(null)
const allowSelfSignup = import.meta.env.VITE_ALLOW_SELF_SIGNUP === 'true'
const roleLabel = computed(() => {
  if (role.value === 'admin') return 'Administrador'
  if (role.value === 'empleado') return 'Empleado'
  return 'Sin rol'
})

async function handleSignIn() {
  error.value = null
  info.value = null
  try {
    await signIn(email.value, password.value)
    info.value = 'Sesión iniciada'
    setTimeout(() => router.push(getDefaultRouteForRole(role.value)), 400)
  } catch (e:any) {
    error.value = e.message || String(e)
  }
}

async function handleSignUp(){
  error.value = null
  info.value = null
  try{
    await signUp(email.value, password.value)
    info.value = 'Cuenta creada. Revisa tu email si es necesaria verificación.'
  }catch(e:any){
    error.value = e.message || String(e)
  }
}

async function handleSignOut(){
  await signOut()
}
</script>

<style scoped>
.auth-card{max-width:420px;margin:36px auto;padding:20px;border-radius:10px;border:1px solid #eef2f5;background:#fff}
.form-grid{display:flex;flex-direction:column;gap:10px}
.actions{display:flex;gap:8px;justify-content:flex-end}
.error{color:#ef4444}
.info{color:#0b6f4b}
.logged{display:flex;flex-direction:column;gap:8px}
.access-note{color:#64748b;font-size:13px}
.role-pill{display:inline-flex;align-self:flex-start;padding:4px 10px;border-radius:999px;background:#e0f2fe;color:#0369a1;font-weight:700;font-size:12px;text-transform:uppercase;letter-spacing:.04em}
.input{padding:8px;border-radius:8px;border:1px solid #e6eef2}
.btn-primary{background:#059669;color:#fff;padding:8px 12px;border-radius:8px;border:none}
.btn-outline{background:#fff;border:1px solid #e6eef2;padding:8px 10px;border-radius:8px}
.btn-danger{background:#fff;border:1px solid #ffdddd;color:#ef4444;padding:8px 10px;border-radius:8px}

/* Dark mode */
:is(.dark) .auth-card{background:#111c2e;border-color:#1e293b;color:#e2e8f0}
:is(.dark) .auth-card h3{color:#e2e8f0}
:is(.dark) .input{background:#0f1729;border-color:#334155;color:#e2e8f0}
:is(.dark) .btn-outline{background:#0f1729;border-color:#334155;color:#cbd5e1}
:is(.dark) .btn-danger{background:#0f1729;border-color:#7f1d1d;color:#fca5a5}
:is(.dark) .error{color:#fca5a5}
:is(.dark) .info{color:#6ee7b7}
:is(.dark) .access-note{color:#94a3b8}
:is(.dark) .role-pill{background:#0c4a6e;color:#bae6fd}
</style>
