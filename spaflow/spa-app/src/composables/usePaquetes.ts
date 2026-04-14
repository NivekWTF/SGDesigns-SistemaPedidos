// src/composables/usePaquetes.ts
import { ref } from 'vue'
import { supabase } from '../lib/supabase'
import { useTenant } from './useTenant'
import type { Servicio } from './useServicios'

export interface PaqueteServicio {
  id: string
  paquete_id: string
  servicio_id: string
  cantidad: number
  servicios?: Pick<Servicio, 'id' | 'nombre' | 'categoria' | 'precio' | 'duracion_min'>
}

export interface Paquete {
  id: string
  spa_id: string
  nombre: string
  descripcion: string | null
  precio: number
  activo: boolean
  vigencia_dias: number | null
  created_at: string
  updated_at: string
  paquete_servicios?: PaqueteServicio[]
}

export type PaqueteInput = Omit<Paquete, 'id' | 'spa_id' | 'created_at' | 'updated_at' | 'paquete_servicios'>

const paquetes = ref<Paquete[]>([])
const loading = ref(false)
const errorMsg = ref<string | null>(null)

async function fetchPaquetes() {
  loading.value = true
  errorMsg.value = null
  const { data, error } = await supabase
    .from('paquetes')
    .select(`*, paquete_servicios(id, paquete_id, servicio_id, cantidad, servicios(id, nombre, categoria, precio, duracion_min))`)
    .order('nombre', { ascending: true })

  if (error) { errorMsg.value = error.message }
  else { paquetes.value = (data ?? []) as Paquete[] }
  loading.value = false
}

async function crearPaquete(
  input: PaqueteInput,
  items: Array<{ servicio_id: string; cantidad: number }>
) {
  const { spaId } = useTenant()
  if (!spaId.value) throw new Error('No hay spa activo')

  const { data: p, error } = await supabase
    .from('paquetes').insert({ ...input, spa_id: spaId.value }).select().single()
  if (error) { errorMsg.value = error.message; throw error }

  if (items.length > 0) {
    const { error: ie } = await supabase
      .from('paquete_servicios')
      .insert(items.map(i => ({ ...i, paquete_id: (p as any).id })))
    if (ie) { errorMsg.value = ie.message; throw ie }
  }
  await fetchPaquetes()
  return p
}

async function actualizarPaquete(
  id: string,
  input: Partial<PaqueteInput>,
  items?: Array<{ servicio_id: string; cantidad: number }>
) {
  const { data, error } = await supabase
    .from('paquetes').update(input).eq('id', id).select().single()
  if (error) { errorMsg.value = error.message; throw error }

  if (items) {
    await supabase.from('paquete_servicios').delete().eq('paquete_id', id)
    if (items.length > 0) {
      await supabase.from('paquete_servicios')
        .insert(items.map(i => ({ ...i, paquete_id: id })))
    }
  }
  await fetchPaquetes()
  return data
}

async function eliminarPaquete(id: string) {
  const { error } = await supabase.from('paquetes').delete().eq('id', id)
  if (error) { errorMsg.value = error.message; throw error }
  paquetes.value = paquetes.value.filter(p => p.id !== id)
}

export function usePaquetes() {
  return { paquetes, loading, errorMsg, fetchPaquetes, crearPaquete, actualizarPaquete, eliminarPaquete }
}
