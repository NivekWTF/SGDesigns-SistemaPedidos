import { ref } from 'vue'
import { supabase } from '../lib/supabase'

const loading = ref(false)
const errorMsg = ref<string | null>(null)

type TimeSeriesRow = { period: string; total: number }

async function ventasPorSemana(weeks = 8) {
  loading.value = true
  errorMsg.value = null
  // expects an RPC `report_sales_by_week(weeks integer)` returning { period, total }
  const { data, error } = await supabase.rpc('report_sales_by_week', { weeks })
  loading.value = false
  if (error) {
    errorMsg.value = error.message
    return [] as TimeSeriesRow[]
  }
  return (data as any) as TimeSeriesRow[]
}

async function ventasPorMes(months = 12) {
  loading.value = true
  errorMsg.value = null
  const { data, error } = await supabase.rpc('report_sales_by_month', { months })
  loading.value = false
  if (error) {
    errorMsg.value = error.message
    return [] as TimeSeriesRow[]
  }
  return (data as any) as TimeSeriesRow[]
}

async function gananciasYGastos(periods = 12) {
  loading.value = true
  errorMsg.value = null
  // expects RPC returning { period, ingresos, gastos, profit }
  const { data, error } = await supabase.rpc('report_profit_and_expenses', { periods })
  loading.value = false
  if (error) {
    errorMsg.value = error.message
    return [] as any
  }
  return data as any
}

export function useReportes() {
  return {
    ventasPorSemana,
    ventasPorMes,
    gananciasYGastos,
    loading,
    errorMsg
  }
}
