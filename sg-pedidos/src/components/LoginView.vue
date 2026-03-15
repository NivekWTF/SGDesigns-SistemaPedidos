<template>
  <div class="auth-card">
    <h3>Iniciar sesión</h3>

    <div v-if="user && user.id" class="logged">
      <p>Conectado como <strong>{{ user.email }}</strong></p>
      <button class="btn-danger" @click="handleSignOut">Cerrar sesión</button>
    </div>

    <form v-else @submit.prevent="handleSignIn" class="form-grid">
      <label>Email</label>
      <input v-model="email" type="email" required class="input" />

      <label>Contraseña</label>
      <input v-model="password" type="password" required class="input" />

      <div class="actions">
        <button class="btn-primary" type="submit">Entrar</button>
        <button type="button" class="btn-outline" @click="handleSignUp">Registrarse</button>
      </div>

      <div v-if="error" class="error">{{ error }}</div>
      <div v-if="info" class="info">{{ info }}</div>
    </form>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useAuth } from '../composables/useAuth'
import { useRouter } from 'vue-router'

const { user, signIn, signUp, signOut } = useAuth()
const router = useRouter()

const email = ref('')
const password = ref('')
const error = ref<string | null>(null)
const info = ref<string | null>(null)

async function handleSignIn() {
  error.value = null
  info.value = null
  try {
    await signIn(email.value, password.value)
    info.value = 'Sesión iniciada'
    setTimeout(() => router.push('/'), 600)
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
</style>
