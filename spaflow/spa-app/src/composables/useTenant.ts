// src/composables/useTenant.ts
// Core del sistema multi-tenant: expone el spa activo del usuario autenticado.
// Todos los composables de dominio deben obtener el spa_id desde aquí.

import { ref, computed, readonly } from 'vue'
import { supabase } from '../lib/supabase'
import { useAuth, registerFetchSpaConfig } from './useAuth'

// Registrar fetchSpaConfig para que useAuth lo invoque automáticamente
// tras login / restauración de sesión (evita llamadas manuales en cada vista)
registerFetchSpaConfig(() => fetchSpaConfig())

export interface SpaConfig {
  id: string
  nombre: string
  slug: string
  logo_url: string | null
  color_primario: string
  zona_horaria: string
  plan: 'basic' | 'pro' | 'enterprise'
  activo: boolean
  trial_hasta: string | null
  created_at: string
}

const spaConfig = ref<SpaConfig | null>(null)
const loadingTenant = ref(false)
const tenantError = ref<string | null>(null)

async function fetchSpaConfig() {
  const { spaId, isSuperAdmin } = useAuth()

  // Superadmin no tiene spa_id: sin config de tenant
  if (isSuperAdmin.value) {
    spaConfig.value = null
    return null
  }

  const id = spaId.value
  if (!id) {
    tenantError.value = 'No hay spa_id en el perfil de usuario.'
    return null
  }

  loadingTenant.value = true
  tenantError.value = null

  const { data, error } = await supabase
    .from('spas')
    .select('*')
    .eq('id', id)
    .single()

  if (error) {
    tenantError.value = error.message
    spaConfig.value = null
  } else {
    spaConfig.value = data as SpaConfig
    // Aplicar color primario del spa en CSS
    if (data.color_primario) {
      document.documentElement.style.setProperty('--primary', data.color_primario)
    }
  }

  loadingTenant.value = false
  return spaConfig.value
}

async function updateSpaConfig(updates: Partial<Pick<SpaConfig, 'nombre' | 'logo_url' | 'color_primario' | 'zona_horaria'>>) {
  if (!spaConfig.value?.id) throw new Error('No hay spa activo')

  const { data, error } = await supabase
    .from('spas')
    .update(updates)
    .eq('id', spaConfig.value.id)
    .select()
    .single()

  if (error) throw error

  spaConfig.value = data as SpaConfig
  if (data.color_primario) {
    document.documentElement.style.setProperty('--primary', data.color_primario)
  }
  return data
}

// ── Computed helpers ──────────────────────────────────────────────
const spaId       = computed(() => spaConfig.value?.id ?? null)
const spaNombre   = computed(() => spaConfig.value?.nombre ?? 'SpaFlow')
const spaActivo   = computed(() => spaConfig.value?.activo ?? false)
const spaPlan     = computed(() => spaConfig.value?.plan ?? 'basic')
const spaZonaHora = computed(() => spaConfig.value?.zona_horaria ?? 'America/Mexico_City')

export function useTenant() {
  return {
    spaConfig:    readonly(spaConfig),
    spaId,
    spaNombre,
    spaActivo,
    spaPlan,
    spaZonaHora,
    loadingTenant: readonly(loadingTenant),
    tenantError:  readonly(tenantError),
    fetchSpaConfig,
    updateSpaConfig,
  }
}
