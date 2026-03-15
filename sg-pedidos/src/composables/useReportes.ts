import { ref } from 'vue'
import { supabase } from '../lib/supabase'

const loading = ref(false)
const errorMsg = ref<string | null>(null)
export const reportTimeZone = 'America/Mazatlan'

type TimeSeriesRow = { period: string; total: number }

async function ventasPorSemana(weeks = 8, tz = reportTimeZone) {
  loading.value = true
  errorMsg.value = null
  // expects an RPC `report_sales_by_week(weeks integer)` returning { period, total }
  const { data, error } = await supabase.rpc('report_sales_by_week', { weeks, tz })
  loading.value = false
  if (error) {
    errorMsg.value = error.message
    return [] as TimeSeriesRow[]
  }
  return (data as any) as TimeSeriesRow[]
}

async function ventasPorMes(months = 12, tz = reportTimeZone) {
  loading.value = true
  errorMsg.value = null
  const { data, error } = await supabase.rpc('report_sales_by_month', { months, tz })
  loading.value = false
  if (error) {
    errorMsg.value = error.message
    return [] as TimeSeriesRow[]
  }
  return (data as any) as TimeSeriesRow[]
}

async function gananciasYGastos(periods = 12, tz = reportTimeZone) {
  loading.value = true
  errorMsg.value = null
  // expects RPC returning { period, ingresos, gastos, profit }
  const { data, error } = await supabase.rpc('report_profit_and_expenses', { periods, tz })
  loading.value = false
  if (error) {
    errorMsg.value = error.message
    return [] as any
  }
  return data as any
}

async function gananciasYGastosSemanales(weeks = 8, tz = reportTimeZone) {
  loading.value = true
  errorMsg.value = null
  const { data, error } = await supabase.rpc('report_profit_and_expenses_weekly', { weeks, tz })
  loading.value = false
  if (error) {
    errorMsg.value = error.message
    return [] as any
  }
  return data as any
}

async function ventasPorDia(date: string, tz = reportTimeZone) {
  loading.value = true
  errorMsg.value = null
  // Use RPC `report_sales_by_day(day,date)` which returns hourly series { period, total }
  const { data, error } = await supabase.rpc('report_sales_by_day', { day: date, tz })
  loading.value = false
  if (error) {
    errorMsg.value = error.message
    return [] as TimeSeriesRow[]
  }
  return (data as any) as TimeSeriesRow[]
}

async function ventasProducto(
  productName: string,
  dateFrom?: string | null,
  dateTo?: string | null,
  tz = reportTimeZone
) {
  loading.value = true
  errorMsg.value = null
  const params: any = { product_name: productName, tz }
  if (dateFrom) params.date_from = dateFrom
  if (dateTo) params.date_to = dateTo
  const { data, error } = await supabase.rpc('report_product_sales', params)
  loading.value = false
  if (error) {
    errorMsg.value = error.message
    return [] as any[]
  }
  return (data as any) || []
}

async function pedidosPorDia(date: string, tz = reportTimeZone) {
  loading.value = true
  errorMsg.value = null
  const { data, error } = await supabase.rpc('report_orders_by_day', { day: date, tz })
  loading.value = false
  if (error) {
    errorMsg.value = error.message
    return { rows: [] as any[], total: 0 }
  }
  const rows = (data as any) || []
  const total = rows.reduce((s: number, r: any) => s + (r.total || 0), 0)
  return { rows, total }
}

export function useReportes() {
  return {
    ventasPorSemana,
    ventasPorMes,
    ventasPorDia,
    pedidosPorDia,
    gananciasYGastos,
    gananciasYGastosSemanales,
    ventasProducto,
    loading,
    errorMsg
  }
}
