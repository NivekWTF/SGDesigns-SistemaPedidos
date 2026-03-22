import { computed, readonly, ref } from 'vue'
import { supabase } from '../lib/supabase'
import type { Session, User } from '@supabase/supabase-js'
import type { AppRole, UserProfile } from '../types'

const user = ref<User | null | undefined>(undefined)
const profile = ref<UserProfile | null | undefined>(undefined)
const authReady = ref(false)
const authError = ref<string | null>(null)

const PROFILE_SELECT = 'id, email, full_name, role, created_at, updated_at'

let initPromise: Promise<void> | null = null
let authListenerRegistered = false

function buildMissingProfileMessage() {
  return 'Tu usuario no tiene un perfil con rol asignado. Ejecuta la migración de roles en Supabase y vuelve a iniciar sesión.'
}

async function loadProfile(userId: string) {
  const { data, error } = await supabase
    .from('profiles')
    .select(PROFILE_SELECT)
    .eq('id', userId)
    .maybeSingle()

  if (error) {
    profile.value = null
    authError.value = 'No se pudo cargar el perfil de usuario. Verifica que la tabla profiles y sus políticas ya estén desplegadas.'
    console.error('Error loading user profile', error)
    return null
  }

  if (!data) {
    profile.value = null
    authError.value = buildMissingProfileMessage()
    return null
  }

  profile.value = data as UserProfile
  authError.value = null
  return profile.value
}

async function syncSessionState(session: Session | null) {
  user.value = session?.user ?? null

  if (!user.value) {
    profile.value = null
    authError.value = null
    authReady.value = true
    return
  }

  await loadProfile(user.value.id)
  authReady.value = true
}

async function initAuth() {
  if (!initPromise) {
    initPromise = (async () => {
      try {
        const { data, error } = await supabase.auth.getSession()
        if (error) throw error
        await syncSessionState(data.session ?? null)
      } catch (e) {
        user.value = null
        profile.value = null
        authError.value = null
        authReady.value = true
      }

      if (!authListenerRegistered) {
        supabase.auth.onAuthStateChange((_event, session) => {
          void syncSessionState(session ?? null)
        })
        authListenerRegistered = true
      }
    })()
  }

  return initPromise
}

async function signIn(email: string, password: string) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password })
  if (error) throw error

  await syncSessionState(data.session ?? null)

  if (!profile.value) {
    await supabase.auth.signOut()
    user.value = null
    throw new Error(authError.value || buildMissingProfileMessage())
  }

  return data
}

async function signUp(email: string, password: string) {
  const { data, error } = await supabase.auth.signUp({ email, password })
  if (error) throw error

  if (data.session) {
    await syncSessionState(data.session)
  }

  return data
}

async function signOut() {
  await supabase.auth.signOut()
  user.value = null
  profile.value = null
  authError.value = null
}

async function refreshProfile() {
  if (!user.value?.id) {
    profile.value = null
    return null
  }

  return loadProfile(user.value.id)
}

const role = computed<AppRole | null>(() => profile.value?.role ?? null)
const isAdmin = computed(() => role.value === 'admin')
const canAccessPedidos = computed(() => role.value === 'admin' || role.value === 'empleado')

export function getDefaultRouteForRole(currentRole: AppRole | null | undefined) {
  return currentRole === 'empleado'
    ? { name: 'Pedidos' as const }
    : { name: 'Home' as const }
}

export function useAuth() {
  // initialize on first use
  if (user.value === undefined) void initAuth()

  return {
    user: readonly(user),
    profile: readonly(profile),
    role: readonly(role),
    isAdmin: readonly(isAdmin),
    canAccessPedidos: readonly(canAccessPedidos),
    authReady: readonly(authReady),
    authError: readonly(authError),
    initAuth,
    refreshProfile,
    signIn,
    signUp,
    signOut
  }
}
