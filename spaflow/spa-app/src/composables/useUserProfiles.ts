import { ref } from 'vue'
import { supabase } from '../lib/supabase'
import type { AppRole, UserProfile } from '../types'

const profiles = ref<UserProfile[]>([])
const loading = ref(false)
const creating = ref(false)
const errorMsg = ref<string | null>(null)

const PROFILE_SELECT = 'id, email, full_name, role, created_at, updated_at'

interface CreateUserInput {
  email: string
  password: string
  full_name?: string | null
  role: AppRole
}

async function extractFunctionsErrorMessage(error: any) {
  const context = error?.context
  if (context?.json) {
    try {
      const body = await context.json()
      if (body?.code === 'NOT_FOUND') {
        return 'La function admin-create-user no esta desplegada en Supabase. Debes publicarla primero.'
      }
      return body?.error || body?.message || error?.message || 'Error en la function'
    } catch {
      return error?.message || 'Error en la function'
    }
  }

  return error?.message || 'Error en la function'
}

async function fetchProfiles() {
  loading.value = true
  errorMsg.value = null

  const { data, error } = await supabase
    .from('profiles')
    .select(PROFILE_SELECT)
    .order('created_at', { ascending: false })

  if (error) {
    errorMsg.value = error.message
    loading.value = false
    return [] as UserProfile[]
  }

  profiles.value = ((data ?? []) as UserProfile[])
  loading.value = false
  return profiles.value
}

async function updateUserRole(id: string, role: AppRole) {
  errorMsg.value = null

  const { data, error } = await supabase
    .from('profiles')
    .update({ role })
    .eq('id', id)
    .select(PROFILE_SELECT)
    .single()

  if (error) {
    errorMsg.value = error.message
    throw error
  }

  const updatedProfile = data as UserProfile
  const idx = profiles.value.findIndex((profile) => profile.id === id)
  if (idx !== -1) profiles.value[idx] = updatedProfile
  else profiles.value.unshift(updatedProfile)

  return updatedProfile
}

async function createUser(input: CreateUserInput) {
  creating.value = true
  errorMsg.value = null

  const { data, error } = await supabase.functions.invoke('admin-create-user', {
    body: input
  })

  if (error) {
    errorMsg.value = await extractFunctionsErrorMessage(error)
    creating.value = false
    throw new Error(errorMsg.value)
  }

  const createdProfile = (data?.profile ?? data) as UserProfile
  if (!createdProfile?.id) {
    creating.value = false
    errorMsg.value = 'La function no devolvio el perfil creado'
    throw new Error(errorMsg.value)
  }

  profiles.value.unshift(createdProfile)
  creating.value = false
  return createdProfile
}

export function useUserProfiles() {
  return {
    profiles,
    loading,
    creating,
    errorMsg,
    fetchProfiles,
    updateUserRole,
    createUser
  }
}