<template>
  <div class="max-w-[1100px] space-y-6 font-body">
    <!-- Header -->
    <header>
      <h1 class="font-display text-3xl font-bold tracking-tight text-slate-900 dark:text-slate-100">Ventas por Producto</h1>
      <p class="mt-1.5 font-body text-sm font-medium text-slate-400 dark:text-slate-500">Consulta cuántas unidades de cada producto se han vendido</p>
    </header>

    <!-- Filtros -->
    <section class="flex flex-wrap items-end gap-4 rounded-2xl border border-slate-100 dark:border-white/10 bg-gradient-to-br from-white to-slate-50/60 dark:from-[#111c2e] dark:to-[#0f1729] p-5 shadow-sm">
      <div class="flex flex-1 min-w-[180px] flex-col gap-1.5">
        <label class="font-display text-xs font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500">Producto</label>
        <div class="relative">
          <Search class="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-slate-300 dark:text-slate-600" />
          <input
            v-model="productName"
            placeholder="Ej: tabloide, couche, vinil..."
            class="w-full rounded-lg border border-slate-200 dark:border-[#334155] bg-white dark:bg-[#0f1729] py-2.5 pl-9 pr-3 font-body text-sm text-slate-800 dark:text-slate-200 placeholder:text-slate-300 dark:placeholder:text-slate-600 focus:border-blue-400 focus:outline-none focus:ring-2 focus:ring-blue-200 dark:focus:ring-blue-800"
            @keyup.enter="consultar"
          />
        </div>
      </div>
      <div class="flex flex-col gap-1.5">
        <label class="font-display text-xs font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500">Desde</label>
        <input type="date" v-model="dateFrom" class="rounded-lg border border-slate-200 dark:border-[#334155] bg-white dark:bg-[#0f1729] px-3 py-2.5 font-body text-sm text-slate-800 dark:text-slate-200 focus:border-blue-400 focus:outline-none focus:ring-2 focus:ring-blue-200 dark:focus:ring-blue-800" />
      </div>
      <div class="flex flex-col gap-1.5">
        <label class="font-display text-xs font-semibold uppercase tracking-wider text-slate-400 dark:text-slate-500">Hasta</label>
        <input type="date" v-model="dateTo" class="rounded-lg border border-slate-200 dark:border-[#334155] bg-white dark:bg-[#0f1729] px-3 py-2.5 font-body text-sm text-slate-800 dark:text-slate-200 focus:border-blue-400 focus:outline-none focus:ring-2 focus:ring-blue-200 dark:focus:ring-blue-800" />
      </div>
      <div class="flex items-end gap-2">
        <button
          @click="consultar"
          :disabled="!productName.trim()"
          class="inline-flex items-center gap-1.5 rounded-lg bg-blue-500 px-4 py-2.5 font-body text-sm font-bold text-white shadow-sm shadow-blue-200 dark:shadow-blue-900/30 transition hover:bg-blue-600 disabled:cursor-not-allowed disabled:opacity-50"
        >
          <Search class="h-3.5 w-3.5" />
          Consultar
        </button>
        <button
          @click="limpiar"
          class="inline-flex items-center gap-1.5 rounded-lg border border-slate-200 dark:border-[#334155] bg-white dark:bg-[#0f1729] px-4 py-2.5 font-body text-sm font-bold text-slate-600 dark:text-slate-300 transition hover:bg-slate-50 dark:hover:bg-[#1e293b]"
        >
          <RotateCcw class="h-3.5 w-3.5" />
          Limpiar
        </button>
      </div>
    </section>

    <!-- Resultados -->
    <section v-if="hasSearched" class="space-y-5">
      <!-- Loading -->
      <div v-if="loading" class="flex items-center justify-center gap-3 py-14">
        <div class="h-7 w-7 animate-spin rounded-full border-[3px] border-slate-200 dark:border-slate-700 border-t-blue-500"></div>
        <span class="font-body text-sm text-slate-400 dark:text-slate-500">Cargando...</span>
      </div>

      <!-- Error -->
      <div v-else-if="errorMsg" class="flex items-center gap-3 rounded-xl border border-red-200 dark:border-red-800 bg-red-50 dark:bg-red-950/30 p-5 font-body text-sm text-red-600 dark:text-red-400">
        <AlertTriangle class="h-5 w-5 shrink-0" />
        {{ errorMsg }}
      </div>

      <!-- Empty -->
      <div v-else-if="!rows.length" class="rounded-2xl border border-slate-100 dark:border-white/10 bg-white dark:bg-[#111c2e] p-10 text-center font-body text-sm text-slate-400 dark:text-slate-500">
        No se encontraron ventas para "<strong class="font-bold text-slate-600 dark:text-slate-300">{{ lastSearch }}</strong>" en el periodo seleccionado.
      </div>

      <template v-else>
        <!-- Stat cards -->
        <div class="grid grid-cols-3 gap-4">
          <div class="relative overflow-hidden rounded-2xl border border-blue-100 dark:border-blue-900/40 bg-gradient-to-br from-blue-50 to-white dark:from-blue-950/30 dark:to-[#111c2e] p-5 text-center shadow-sm">
            <div class="absolute -right-3 -top-3 h-14 w-14 rounded-full bg-blue-100/30 dark:bg-blue-800/20"></div>
            <div class="relative flex items-center justify-center gap-1.5 font-display text-xs font-semibold uppercase tracking-wider text-blue-400">
              <PackageCheck class="h-3.5 w-3.5" /> Unidades Vendidas
            </div>
            <div class="relative mt-2 font-body text-2xl font-black text-slate-900 dark:text-slate-100">{{ totalCantidad }}</div>
          </div>
          <div class="relative overflow-hidden rounded-2xl border border-emerald-200 dark:border-emerald-900/40 bg-gradient-to-br from-emerald-50 to-white dark:from-emerald-950/30 dark:to-[#111c2e] p-5 text-center shadow-sm">
            <div class="absolute -right-3 -top-3 h-14 w-14 rounded-full bg-emerald-100/30 dark:bg-emerald-800/20"></div>
            <div class="relative flex items-center justify-center gap-1.5 font-display text-xs font-semibold uppercase tracking-wider text-emerald-400">
              <DollarSign class="h-3.5 w-3.5" /> Total Facturado
            </div>
            <div class="relative mt-2 font-body text-2xl font-black text-emerald-600 dark:text-emerald-400">{{ formatCurrency(totalVentas) }}</div>
          </div>
          <div class="relative overflow-hidden rounded-2xl border border-amber-100 dark:border-amber-900/40 bg-gradient-to-br from-amber-50 to-white dark:from-amber-950/30 dark:to-[#111c2e] p-5 text-center shadow-sm">
            <div class="absolute -right-3 -top-3 h-14 w-14 rounded-full bg-amber-100/30 dark:bg-amber-800/20"></div>
            <div class="relative flex items-center justify-center gap-1.5 font-display text-xs font-semibold uppercase tracking-wider text-amber-400">
              <ClipboardList class="h-3.5 w-3.5" /> Pedidos
            </div>
            <div class="relative mt-2 font-body text-2xl font-black text-slate-900 dark:text-slate-100">{{ totalPedidos }}</div>
          </div>
        </div>

        <!-- Table -->
        <div class="overflow-hidden rounded-2xl border border-slate-100 dark:border-white/10 bg-white dark:bg-[#111c2e] shadow-sm">
          <div class="grid grid-cols-[1fr_100px_130px_90px] items-center gap-2 bg-gradient-to-r from-slate-50 to-slate-100/60 dark:from-[#0f1729] dark:to-[#0f1729] px-5 py-3.5 font-display text-[11px] font-bold uppercase tracking-wider text-slate-400 dark:text-slate-500">
            <div>Producto</div>
            <div class="text-right">Unidades</div>
            <div class="text-right">Total Ventas</div>
            <div class="text-right">Pedidos</div>
          </div>
          <div
            v-for="(r, i) in rows" :key="r.producto_id"
            class="grid grid-cols-[1fr_100px_130px_90px] items-center gap-2 border-t border-slate-100/60 dark:border-white/5 px-5 py-3.5 transition"
            :class="i % 2 === 0 ? 'bg-white dark:bg-[#111c2e]' : 'bg-slate-50/40 dark:bg-[#0f1729]/50'"
          >
            <div class="font-body text-sm font-bold text-slate-800 dark:text-slate-200">{{ r.producto }}</div>
            <div class="text-right font-body text-sm font-black text-blue-600 dark:text-blue-400">{{ r.total_cantidad }}</div>
            <div class="text-right font-body text-sm font-bold text-emerald-600 dark:text-emerald-400">{{ formatCurrency(r.total_ventas) }}</div>
            <div class="text-right font-body text-sm font-medium text-slate-500 dark:text-slate-400">{{ r.num_pedidos }}</div>
          </div>
        </div>

        <p class="font-body text-xs text-slate-300">
          Búsqueda: "{{ lastSearch }}"
          <template v-if="lastDateFrom || lastDateTo">
            &mdash; {{ lastDateFrom || '...' }} a {{ lastDateTo || 'hoy' }}
          </template>
        </p>
      </template>
    </section>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useReportes } from '../composables/useReportes'
import { Search, RotateCcw, AlertTriangle, PackageCheck, DollarSign, ClipboardList } from 'lucide-vue-next'

const { ventasProducto, loading, errorMsg } = useReportes()

const productName = ref('')
const dateFrom = ref<string | null>(null)
const dateTo = ref<string | null>(null)
const rows = ref<any[]>([])
const hasSearched = ref(false)
const lastSearch = ref('')
const lastDateFrom = ref<string | null>(null)
const lastDateTo = ref<string | null>(null)

const totalCantidad = computed(() => rows.value.reduce((s, r) => s + Number(r.total_cantidad || 0), 0))
const totalVentas = computed(() => rows.value.reduce((s, r) => s + Number(r.total_ventas || 0), 0))
const totalPedidos = computed(() => rows.value.reduce((s, r) => s + Number(r.num_pedidos || 0), 0))

async function consultar() {
  const name = productName.value.trim()
  if (!name) return
  lastSearch.value = name
  lastDateFrom.value = dateFrom.value
  lastDateTo.value = dateTo.value
  hasSearched.value = true
  rows.value = await ventasProducto(name, dateFrom.value, dateTo.value)
}

function limpiar() {
  productName.value = ''
  dateFrom.value = null
  dateTo.value = null
  rows.value = []
  hasSearched.value = false
}

function formatCurrency(n: number) {
  return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN', maximumFractionDigits: 2 }).format(n || 0)
}
</script>
