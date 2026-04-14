// src/composables/useServicios.ts
import { ref } from 'vue'
import { supabase } from '../lib/supabase'
import { useTenant } from './useTenant'

export type CategoriaServicio = 'MASAJE' | 'FACIAL' | 'CORPORAL' | 'UÑAS' | 'CABELLO' | 'OTRO'

export interface Servicio {
  id: string
  spa_id: string
  nombre: string
  descripcion: string | null
  categoria: CategoriaServicio
  duracion_min: number
  precio: number
  activo: boolean
  imagen_url: string | null
  created_at: string
  updated_at: string
}

export type ServicioInput = Omit<Servicio, 'id' | 'spa_id' | 'created_at' | 'updated_at'>

export const CATEGORIAS_SERVICIO: { value: CategoriaServicio; label: string; emoji: string }[] = [
  { value: 'MASAJE',   label: 'Masaje',   emoji: '💆' },
  { value: 'FACIAL',   label: 'Facial',   emoji: '✨' },
  { value: 'CORPORAL', label: 'Corporal', emoji: '🛁' },
  { value: 'UÑAS',     label: 'Uñas',     emoji: '💅' },
  { value: 'CABELLO',  label: 'Cabello',  emoji: '💇' },
  { value: 'OTRO',     label: 'Otro',     emoji: '🌿' },
]

const servicios = ref<Servicio[]>([])
const loading = ref(false)
const errorMsg = ref<string | null>(null)

async function fetchServicios(soloActivos = true) {
  loading.value = true
  errorMsg.value = null

  let query = supabase
    .from('servicios')
    .select('*')
    .order('categoria', { ascending: true })
    .order('nombre', { ascending: true })

  if (soloActivos) query = query.eq('activo', true)

  const { data, error } = await query

  if (error) {
    errorMsg.value = error.message
  } else {
    servicios.value = (data ?? []) as Servicio[]
  }

  loading.value = false
}

async function crearServicio(input: ServicioInput) {
  errorMsg.value = null
  const { spaId } = useTenant()
  if (!spaId.value) throw new Error('No hay spa activo')

  const { data, error } = await supabase
    .from('servicios')
    .insert({ ...input, spa_id: spaId.value })
    .select()
    .single()

  if (error) { errorMsg.value = error.message; throw error }

  servicios.value.push(data as Servicio)
  servicios.value.sort((a, b) => a.nombre.localeCompare(b.nombre))
  return data as Servicio
}

async function actualizarServicio(id: string, input: Partial<ServicioInput>) {
  const { data, error } = await supabase
    .from('servicios')
    .update(input)
    .eq('id', id)
    .select()
    .single()

  if (error) { errorMsg.value = error.message; throw error }

  const idx = servicios.value.findIndex(s => s.id === id)
  if (idx !== -1) servicios.value[idx] = data as Servicio
  return data as Servicio
}

async function toggleActivoServicio(id: string, activo: boolean) {
  return actualizarServicio(id, { activo })
}

async function eliminarServicio(id: string) {
  const { error } = await supabase.from('servicios').delete().eq('id', id)
  if (error) { errorMsg.value = error.message; throw error }
  servicios.value = servicios.value.filter(s => s.id !== id)
}

export function useServicios() {
  return {
    servicios,
    loading,
    errorMsg,
    fetchServicios,
    crearServicio,
    actualizarServicio,
    toggleActivoServicio,
    eliminarServicio,
    CATEGORIAS_SERVICIO,
  }
}
