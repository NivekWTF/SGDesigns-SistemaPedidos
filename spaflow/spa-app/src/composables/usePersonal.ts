// src/composables/usePersonal.ts
import { ref } from 'vue'
import { supabase } from '../lib/supabase'
import { useTenant } from './useTenant'
import type { CategoriaServicio } from './useServicios'

export interface Terapeuta {
  id: string
  spa_id: string
  profile_id: string | null
  nombre: string
  especialidades: CategoriaServicio[]
  telefono: string | null
  activo: boolean
  color_agenda: string
  created_at: string
  updated_at: string
}

export type TerapeutaInput = Omit<Terapeuta, 'id' | 'spa_id' | 'created_at' | 'updated_at'>

export interface HorarioPersonal {
  id: string
  personal_id: string
  dia_semana: number       // 0=Dom … 6=Sáb
  hora_inicio: string      // "09:00"
  hora_fin: string         // "19:00"
  activo: boolean
}

export type HorarioInput = Omit<HorarioPersonal, 'id'>

export const DIAS_SEMANA = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb']

// Colores propuestos para el calendario
export const COLORES_AGENDA = [
  { value: '#8b5cf6', label: 'Lavanda' },
  { value: '#ec4899', label: 'Rosa' },
  { value: '#f59e0b', label: 'Ámbar' },
  { value: '#10b981', label: 'Esmeralda' },
  { value: '#3b82f6', label: 'Azul' },
  { value: '#ef4444', label: 'Rojo' },
  { value: '#8b5e3c', label: 'Café' },
  { value: '#06b6d4', label: 'Cian' },
]

const personal = ref<Terapeuta[]>([])
const loading = ref(false)
const errorMsg = ref<string | null>(null)

async function fetchPersonal(soloActivos = true) {
  loading.value = true
  errorMsg.value = null

  let query = supabase
    .from('personal')
    .select('*')
    .order('nombre', { ascending: true })

  if (soloActivos) query = query.eq('activo', true)

  const { data, error } = await query

  if (error) {
    errorMsg.value = error.message
  } else {
    personal.value = (data ?? []) as Terapeuta[]
  }

  loading.value = false
}

async function crearTerapeuta(input: TerapeutaInput) {
  errorMsg.value = null
  const { spaId } = useTenant()
  if (!spaId.value) throw new Error('No hay spa activo')

  const { data, error } = await supabase
    .from('personal')
    .insert({ ...input, spa_id: spaId.value })
    .select()
    .single()

  if (error) { errorMsg.value = error.message; throw error }

  personal.value.push(data as Terapeuta)
  personal.value.sort((a, b) => a.nombre.localeCompare(b.nombre))
  return data as Terapeuta
}

async function actualizarTerapeuta(id: string, input: Partial<TerapeutaInput>) {
  const { data, error } = await supabase
    .from('personal')
    .update(input)
    .eq('id', id)
    .select()
    .single()

  if (error) { errorMsg.value = error.message; throw error }

  const idx = personal.value.findIndex(p => p.id === id)
  if (idx !== -1) personal.value[idx] = data as Terapeuta
  return data as Terapeuta
}

async function eliminarTerapeuta(id: string) {
  const { error } = await supabase.from('personal').delete().eq('id', id)
  if (error) { errorMsg.value = error.message; throw error }
  personal.value = personal.value.filter(p => p.id !== id)
}

// ── Horarios ──────────────────────────────────────────────────────

async function fetchHorarios(personalId: string): Promise<HorarioPersonal[]> {
  const { data, error } = await supabase
    .from('horarios_personal')
    .select('*')
    .eq('personal_id', personalId)
    .order('dia_semana', { ascending: true })

  if (error) throw error
  return (data ?? []) as HorarioPersonal[]
}

async function guardarHorario(input: HorarioInput): Promise<HorarioPersonal> {
  const { data, error } = await supabase
    .from('horarios_personal')
    .upsert(input, { onConflict: 'personal_id,dia_semana' })
    .select()
    .single()

  if (error) throw error
  return data as HorarioPersonal
}

async function guardarHorariosSemana(personalId: string, horarios: Omit<HorarioInput, 'personal_id'>[]) {
  const rows = horarios.map(h => ({ ...h, personal_id: personalId }))

  const { data, error } = await supabase
    .from('horarios_personal')
    .upsert(rows, { onConflict: 'personal_id,dia_semana' })
    .select()

  if (error) throw error
  return data as HorarioPersonal[]
}

async function eliminarHorario(personalId: string, diaSemana: number) {
  const { error } = await supabase
    .from('horarios_personal')
    .delete()
    .eq('personal_id', personalId)
    .eq('dia_semana', diaSemana)

  if (error) throw error
}

export function usePersonal() {
  return {
    personal,
    loading,
    errorMsg,
    DIAS_SEMANA,
    COLORES_AGENDA,
    fetchPersonal,
    crearTerapeuta,
    actualizarTerapeuta,
    eliminarTerapeuta,
    fetchHorarios,
    guardarHorario,
    guardarHorariosSemana,
    eliminarHorario,
  }
}
