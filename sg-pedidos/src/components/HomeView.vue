<template>
  <div class="home">
    <h2>Resumen</h2>

    <div class="cards">
      <div class="card">
        <div class="title">Ventas (últimas 8 semanas)</div>
        <div class="value">{{ formatCurrency(totalWeekly) }}</div>
      </div>

      <div class="card">
        <div class="title">Ventas (últimos 12 meses)</div>
        <div class="value">{{ formatCurrency(totalMonthly) }}</div>
      </div>

      <div class="card">
        <div class="title">Ganancias</div>
        <div class="value">{{ formatCurrency(totalProfit) }}</div>
      </div>

      <div class="card">
        <div class="title">Gastos</div>
        <div class="value">{{ formatCurrency(totalExpenses) }}</div>
      </div>
    </div>

    <section class="charts">
      <div>
        <h3>Ventas por semana</h3>
        <ul class="series">
          <li v-for="row in weekly" :key="row.period">{{ row.period }} — {{ formatCurrency(row.total) }}</li>
        </ul>
      </div>

      <div>
        <h3>Ventas por mes</h3>
        <ul class="series">
          <li v-for="row in monthly" :key="row.period">{{ row.period }} — {{ formatCurrency(row.total) }}</li>
        </ul>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useReportes } from '../composables/useReportes'

const { ventasPorSemana, ventasPorMes, gananciasYGastos, loading, errorMsg } = useReportes()

const weekly = ref<Array<{ period: string; total: number }>>([])
const monthly = ref<Array<{ period: string; total: number }>>([])
const profitRows = ref<any[]>([])

async function load() {
  weekly.value = await ventasPorSemana(8)
  monthly.value = await ventasPorMes(12)
  profitRows.value = await gananciasYGastos(12)
}

onMounted(load)

const totalWeekly = computed(() => weekly.value.reduce((s, r) => s + (r.total || 0), 0))
const totalMonthly = computed(() => monthly.value.reduce((s, r) => s + (r.total || 0), 0))
const totalProfit = computed(() => profitRows.value.reduce((s, r) => s + (r.profit || 0), 0))
const totalExpenses = computed(() => profitRows.value.reduce((s, r) => s + (r.gastos || 0), 0))

function formatCurrency(n: number) {
  return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN', maximumFractionDigits: 2 }).format(n || 0)
}
</script>

<style scoped>
.cards{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:12px;margin-bottom:18px}
.card{background:#fff;padding:12px;border-radius:8px;border:1px solid #eef2f6}
.card .title{color:#64748b;font-size:13px}
.card .value{font-weight:700;font-size:18px;margin-top:6px}
.charts{display:flex;gap:20px;flex-wrap:wrap}
.series{list-style:none;padding:0;margin:0}
.series li{padding:6px 0;border-bottom:1px dashed #eef2f6}
</style>
