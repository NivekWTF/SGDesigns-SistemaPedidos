<template>
  <div class="auth-card">
    <h3>Iniciar sesión</h3>

    <div v-if="user && user.id" class="logged">
      <p>Conectado como <strong>{{ profile?.email || user.email }}</strong></p>
      <div v-if="role" class="role-pill">Rol: {{ roleLabel }}</div>
      <div v-if="authError" class="error">{{ authError }}</div>
      <button class="btn-danger" @click="handleSignOut">Cerrar sesión</button>
    </div>

    <div v-else class="login-container">
      <!-- Google Sign-In Button -->
      <button
        class="btn-google"
        :disabled="googleLoading"
        @click="handleGoogleSignIn"
      >
        <svg v-if="!googleLoading" class="google-icon" viewBox="0 0 24 24" width="20" height="20" xmlns="http://www.w3.org/2000/svg">
          <path d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.28-4.74 3.28-8.1z" fill="#4285F4"/>
          <path d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84C3.99 20.53 7.7 23 12 23z" fill="#34A853"/>
          <path d="M5.84 14.09c-.22-.66-.35-1.36-.35-2.09s.13-1.43.35-2.09V7.07H2.18C1.43 8.55 1 10.22 1 12s.43 3.45 1.18 4.93l2.85-2.22.81-.62z" fill="#FBBC05"/>
          <path d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1 7.7 1 3.99 3.47 2.18 7.07l3.66 2.84c.87-2.6 3.3-4.53 6.16-4.53z" fill="#EA4335"/>
        </svg>
        <span v-if="!googleLoading" class="google-label">Continuar con Google</span>
        <span v-else class="google-label">Conectando…</span>
      </button>

      <!-- Separator -->
      <div class="separator">
        <span>o</span>
      </div>

      <!-- Email/Password Form -->
      <form @submit.prevent="handleSignIn" class="form-grid">
        <label>Email</label>
        <input v-model="email" type="email" required class="input" />

        <label>Contraseña</label>
        <input v-model="password" type="password" required class="input" />

        <div class="actions">
          <button class="btn-primary" type="submit">Entrar</button>
          <button v-if="allowSelfSignup" type="button" class="btn-outline" @click="handleSignUp">Registrarse</button>
        </div>

        <div v-if="!allowSelfSignup" class="access-note">El acceso lo crea un administrador desde el panel de usuarios.</div>
      </form>

      <div v-if="error" class="error">{{ error }}</div>
      <div v-if="info" class="info">{{ info }}</div>
      <div v-if="authError" class="error">{{ authError }}</div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { getDefaultRouteForRole, useAuth } from '../composables/useAuth'
import { useRouter } from 'vue-router'

const { user, profile, role, authError, signIn, signInWithGoogle, signUp, signOut } = useAuth()
const router = useRouter()

const email = ref('')
const password = ref('')
const error = ref<string | null>(null)
const info = ref<string | null>(null)
const googleLoading = ref(false)
const allowSelfSignup = import.meta.env.VITE_ALLOW_SELF_SIGNUP === 'true'
const roleLabel = computed(() => {
  if (role.value === 'admin') return 'Administrador'
  if (role.value === 'empleado') return 'Empleado'
  return 'Sin rol'
})

async function handleGoogleSignIn() {
  error.value = null
  info.value = null
  googleLoading.value = true
  try {
    await signInWithGoogle()
    // Supabase redirects to Google, so this point is only reached if there's an issue
  } catch (e: any) {
    error.value = e.message || String(e)
    googleLoading.value = false
  }
}

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
.login-container{display:flex;flex-direction:column;gap:16px}
.form-grid{display:flex;flex-direction:column;gap:10px}
.actions{display:flex;gap:8px;justify-content:flex-end}
.error{color:#ef4444;margin-top:4px}
.info{color:#0b6f4b;margin-top:4px}
.logged{display:flex;flex-direction:column;gap:8px}
.access-note{color:#64748b;font-size:13px}
.role-pill{display:inline-flex;align-self:flex-start;padding:4px 10px;border-radius:999px;background:#e0f2fe;color:#0369a1;font-weight:700;font-size:12px;text-transform:uppercase;letter-spacing:.04em}
.input{padding:8px;border-radius:8px;border:1px solid #e6eef2}
.btn-primary{background:#059669;color:#fff;padding:8px 12px;border-radius:8px;border:none;cursor:pointer}
.btn-primary:hover{background:#047857}
.btn-outline{background:#fff;border:1px solid #e6eef2;padding:8px 10px;border-radius:8px;cursor:pointer}
.btn-outline:hover{background:#f1f5f9}
.btn-danger{background:#fff;border:1px solid #ffdddd;color:#ef4444;padding:8px 10px;border-radius:8px;cursor:pointer}
.btn-danger:hover{background:#fef2f2}

/* Google Button */
.btn-google{
  display:flex;align-items:center;justify-content:center;gap:10px;
  width:100%;padding:10px 16px;
  background:#fff;border:1px solid #dadce0;border-radius:8px;
  cursor:pointer;transition:background .15s ease, box-shadow .15s ease;
  font-size:14px;font-weight:500;color:#3c4043;
}
.btn-google:hover{background:#f7f8f8;box-shadow:0 1px 3px rgba(0,0,0,.1)}
.btn-google:active{background:#eee}
.btn-google:disabled{opacity:.6;cursor:not-allowed}
.google-icon{flex-shrink:0}
.google-label{line-height:1}

/* Separator */
.separator{
  display:flex;align-items:center;gap:12px;
  color:#94a3b8;font-size:13px;
}
.separator::before,.separator::after{
  content:'';flex:1;height:1px;background:#e2e8f0;
}

/* Dark mode */
:is(.dark) .auth-card{background:#111c2e;border-color:#1e293b;color:#e2e8f0}
:is(.dark) .auth-card h3{color:#e2e8f0}
:is(.dark) .input{background:#0f1729;border-color:#334155;color:#e2e8f0}
:is(.dark) .btn-outline{background:#0f1729;border-color:#334155;color:#cbd5e1}
:is(.dark) .btn-outline:hover{background:#1e293b}
:is(.dark) .btn-danger{background:#0f1729;border-color:#7f1d1d;color:#fca5a5}
:is(.dark) .btn-danger:hover{background:#1a0f0f}
:is(.dark) .error{color:#fca5a5}
:is(.dark) .info{color:#6ee7b7}
:is(.dark) .access-note{color:#94a3b8}
:is(.dark) .role-pill{background:#0c4a6e;color:#bae6fd}
:is(.dark) .btn-google{background:#1e293b;border-color:#334155;color:#e2e8f0}
:is(.dark) .btn-google:hover{background:#253347;box-shadow:0 1px 3px rgba(0,0,0,.3)}
:is(.dark) .btn-google:active{background:#334155}
:is(.dark) .separator{color:#64748b}
:is(.dark) .separator::before,:is(.dark) .separator::after{background:#334155}
</style>
