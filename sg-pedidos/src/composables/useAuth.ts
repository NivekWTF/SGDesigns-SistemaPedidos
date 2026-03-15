import { ref, readonly } from 'vue'
import { supabase } from '../lib/supabase'
import type { User } from '@supabase/supabase-js'

const user = ref<User | null | undefined>(undefined)

async function initAuth() {
  try {
    const { data } = await supabase.auth.getSession()
    user.value = data.session?.user ?? null
  } catch (e) {
    user.value = null
  }

  supabase.auth.onAuthStateChange((_event, session) => {
    user.value = session?.user ?? null
  })
}

async function signIn(email: string, password: string) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password })
  if (error) throw error
  user.value = data.user ?? null
  return data
}

async function signUp(email: string, password: string) {
  const { data, error } = await supabase.auth.signUp({ email, password })
  if (error) throw error
  user.value = data.user ?? null
  return data
}

async function signOut() {
  await supabase.auth.signOut()
  user.value = null
}

export function useAuth() {
  // initialize on first use
  if (user.value === undefined) initAuth()

  return {
    user: readonly(user),
    initAuth,
    signIn,
    signUp,
    signOut
  }
}
