import { ref, readonly, computed } from 'vue'
import { supabase } from '../lib/supabase'

/**
 * Business configuration loaded from DB, with env var fallback.
 * Provides reactive state that the entire app can consume.
 */

export interface BusinessConfig {
  business_name: string
  business_rfc: string
  business_email: string
  business_address: string
  business_phone: string
  business_logo_url: string
  business_socials: string
  business_series: string
  tax_rate: number
  color_primary: string
  color_primary_dark: string
  color_accent: string
}

// Env-var defaults
function envDefaults(): BusinessConfig {
  return {
    business_name:     (import.meta.env.VITE_BUSINESS_NAME     as string) || 'Mi Imprenta',
    business_rfc:      (import.meta.env.VITE_BUSINESS_RFC      as string) || '',
    business_email:    (import.meta.env.VITE_BUSINESS_EMAIL    as string) || '',
    business_address:  (import.meta.env.VITE_BUSINESS_ADDRESS  as string) || '',
    business_phone:    (import.meta.env.VITE_BUSINESS_PHONE    as string) || '',
    business_logo_url: (import.meta.env.VITE_BUSINESS_LOGO_URL as string) || '/logo.png',
    business_socials:  (import.meta.env.VITE_BUSINESS_SOCIALS  as string) || '',
    business_series:   (import.meta.env.VITE_BUSINESS_SERIES   as string) || 'COT',
    tax_rate:          parseFloat((import.meta.env.VITE_BUSINESS_TAX_RATE as string) || '0.16'),
    color_primary:     '#0ea5e9',
    color_primary_dark:'#0284c7',
    color_accent:      '#38bdf8',
  }
}

// Singleton state
const config = ref<BusinessConfig>(envDefaults())
const loaded = ref(false)
const loading = ref(false)
const errorMsg = ref<string | null>(null)

const businessName = computed(() => config.value.business_name)
const businessInitials = computed(() =>
  config.value.business_name.split(/\s+/).map(w => w[0] || '').join('').slice(0, 2).toUpperCase()
)

/**
 * Apply theme colors as CSS custom properties on <html>
 */
function applyColors(c: BusinessConfig) {
  const root = document.documentElement
  root.style.setProperty('--brand-primary', c.color_primary)
  root.style.setProperty('--brand-primary-dark', c.color_primary_dark)
  root.style.setProperty('--brand-accent', c.color_accent)

  // Derive light/transparent variants
  root.style.setProperty('--brand-primary-10', c.color_primary + '1a')  // 10% opacity
  root.style.setProperty('--brand-primary-20', c.color_primary + '33')  // 20% opacity
}

let initPromise: Promise<void> | null = null

async function loadConfig() {
  if (initPromise) return initPromise
  initPromise = (async () => {
    loading.value = true
    errorMsg.value = null
    try {
      const { data, error } = await supabase
        .from('business_config')
        .select('*')
        .limit(1)
        .maybeSingle()

      if (error) {
        // Table might not exist yet — use env defaults silently
        console.warn('[useBusinessConfig] Could not load config from DB, using env defaults:', error.message)
        applyColors(config.value)
        loaded.value = true
        return
      }

      if (data) {
        // Merge DB values over env defaults (DB wins if non-null)
        const defaults = envDefaults()
        config.value = {
          business_name:     data.business_name     ?? defaults.business_name,
          business_rfc:      data.business_rfc      ?? defaults.business_rfc,
          business_email:    data.business_email    ?? defaults.business_email,
          business_address:  data.business_address  ?? defaults.business_address,
          business_phone:    data.business_phone    ?? defaults.business_phone,
          business_logo_url: data.business_logo_url ?? defaults.business_logo_url,
          business_socials:  data.business_socials  ?? defaults.business_socials,
          business_series:   data.business_series   ?? defaults.business_series,
          tax_rate:          data.tax_rate != null   ? Number(data.tax_rate) : defaults.tax_rate,
          color_primary:     data.color_primary     ?? defaults.color_primary,
          color_primary_dark:data.color_primary_dark ?? defaults.color_primary_dark,
          color_accent:      data.color_accent      ?? defaults.color_accent,
        }
      }

      applyColors(config.value)
      loaded.value = true
    } catch (e) {
      errorMsg.value = (e as Error).message
      applyColors(config.value)
      loaded.value = true
    } finally {
      loading.value = false
    }
  })()
  return initPromise
}

async function saveConfig(updates: Partial<BusinessConfig>) {
  errorMsg.value = null
  loading.value = true
  try {
    // Upsert: check if row exists
    const { data: existing } = await supabase
      .from('business_config')
      .select('id')
      .limit(1)
      .maybeSingle()

    if (existing?.id) {
      const { error } = await supabase
        .from('business_config')
        .update(updates)
        .eq('id', existing.id)
      if (error) throw error
    } else {
      const { error } = await supabase
        .from('business_config')
        .insert(updates)
      if (error) throw error
    }

    // Merge into local state
    Object.assign(config.value, updates)
    applyColors(config.value)
  } catch (e) {
    errorMsg.value = (e as Error).message
    throw e
  } finally {
    loading.value = false
  }
}

export function useBusinessConfig() {
  // Auto-load on first use
  if (!loaded.value && !initPromise) {
    void loadConfig()
  }

  return {
    config: readonly(config),
    businessName,
    businessInitials,
    loaded: readonly(loaded),
    loading: readonly(loading),
    errorMsg: readonly(errorMsg),
    loadConfig,
    saveConfig,
    applyColors,
  }
}
