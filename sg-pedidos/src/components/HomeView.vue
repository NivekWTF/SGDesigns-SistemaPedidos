<template>
  <div class="min-h-screen bg-[#f4f7fb] text-slate-900 dark:bg-[#081224] dark:text-white">
    <div class="mx-auto w-full max-w-[1500px] px-4 py-6 sm:px-6 lg:px-8">
      <div class="space-y-8">
        <!-- Header -->
        <div class="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div class="min-w-0">
            <h2 class="font-display text-3xl font-bold tracking-tight text-slate-900 dark:text-white">
              Dashboard Gerencial
            </h2>
            <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">
              Vista ejecutiva — {{ todayFormatted }}
            </p>
          </div>
        </div>

        <!-- ROW 1: Hero KPI cards -->
        <section class="grid grid-cols-1 gap-6 xl:grid-cols-3">
          <!-- Ventas Hoy -->
          <div
            class="min-w-0 overflow-hidden rounded-3xl border border-emerald-200 bg-gradient-to-br from-emerald-50 to-emerald-100/70 p-8 shadow-[0_8px_24px_rgba(15,23,42,0.06)] dark:border-emerald-500/20 dark:bg-gradient-to-br dark:from-[#0d3320] dark:to-[#052e16] dark:shadow-[0_10px_30px_rgba(0,0,0,0.22)]"
          >
            <div class="flex items-start justify-between gap-4">
              <div class="min-w-0 flex-1">
                <p class="text-xs font-bold uppercase tracking-[0.18em] text-emerald-700 dark:text-emerald-400/80">
                  Ventas Hoy
                </p>
                <p class="mt-3 text-4xl font-black tracking-tight text-slate-900 dark:text-white">
                  {{ formatCurrency(dayTotal) }}
                </p>
                <div class="mt-3 flex items-center gap-2">
                  <span
                    class="inline-block h-2 w-2 rounded-full"
                    :class="dayTotal > 0 ? 'bg-emerald-500 dark:bg-emerald-400' : 'bg-slate-400 dark:bg-slate-500'"
                  ></span>
                  <span
                    class="text-xs font-semibold"
                    :class="dayTotal > 0 ? 'text-emerald-700 dark:text-emerald-400' : 'text-slate-500 dark:text-slate-400'"
                  >
                    {{ dayRows.length }} pedido{{ dayRows.length !== 1 ? 's' : '' }} hoy
                  </span>
                </div>
              </div>

              <div
                class="flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl border border-emerald-200 bg-white/80 dark:border-emerald-400/10 dark:bg-emerald-500/15"
              >
                <DollarSign class="h-7 w-7 text-emerald-600 dark:text-emerald-400" />
              </div>
            </div>
          </div>

          <!-- Ventas del Mes -->
          <div
            class="min-w-0 overflow-hidden rounded-3xl border border-blue-200 bg-gradient-to-br from-blue-50 to-blue-100/70 p-8 shadow-[0_8px_24px_rgba(15,23,42,0.06)] dark:border-blue-500/20 dark:bg-gradient-to-br dark:from-[#0c2744] dark:to-[#0a1e36] dark:shadow-[0_10px_30px_rgba(0,0,0,0.22)]"
          >
            <div class="flex items-start justify-between gap-4">
              <div class="min-w-0 flex-1">
                <p class="text-xs font-bold uppercase tracking-[0.18em] text-blue-700 dark:text-blue-400/80">
                  Ventas del Mes
                </p>
                <p class="mt-3 text-4xl font-black tracking-tight text-slate-900 dark:text-white">
                  {{ formatCurrency(totalWeekly) }}
                </p>
                <div class="mt-3 flex items-center gap-2">
                  <TrendingUp class="h-3.5 w-3.5 text-blue-600 dark:text-blue-400" />
                  <span class="text-xs font-semibold text-blue-700 dark:text-blue-400">Últimas 8 semanas</span>
                </div>
              </div>

              <div
                class="flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl border border-blue-200 bg-white/80 dark:border-blue-400/10 dark:bg-blue-500/15"
              >
                <CalendarDays class="h-7 w-7 text-blue-600 dark:text-blue-400" />
              </div>
            </div>
          </div>

          <!-- Ventas del Año -->
          <div
            class="min-w-0 overflow-hidden rounded-3xl border border-cyan-200 bg-gradient-to-br from-cyan-50 to-cyan-100/70 p-8 shadow-[0_8px_24px_rgba(15,23,42,0.06)] dark:border-cyan-500/20 dark:bg-gradient-to-br dark:from-[#083344] dark:to-[#042f3e] dark:shadow-[0_10px_30px_rgba(0,0,0,0.22)]"
          >
            <div class="flex items-start justify-between gap-4">
              <div class="min-w-0 flex-1">
                <p class="text-xs font-bold uppercase tracking-[0.18em] text-cyan-700 dark:text-cyan-400/80">
                  Ventas del Año
                </p>
                <p class="mt-3 text-4xl font-black tracking-tight text-slate-900 dark:text-white">
                  {{ formatCurrency(totalMonthly) }}
                </p>
                <div class="mt-3 flex items-center gap-2">
                  <BarChart3 class="h-3.5 w-3.5 text-cyan-600 dark:text-cyan-400" />
                  <span class="text-xs font-semibold text-cyan-700 dark:text-cyan-400">Últimos 12 meses</span>
                </div>
              </div>

              <div
                class="flex h-14 w-14 shrink-0 items-center justify-center rounded-2xl border border-cyan-200 bg-white/80 dark:border-cyan-400/10 dark:bg-cyan-500/15"
              >
                <BarChart3 class="h-7 w-7 text-cyan-600 dark:text-cyan-400" />
              </div>
            </div>
          </div>
        </section>

        <!-- ROW 2: Financial metrics -->
        <section class="grid grid-cols-1 gap-5 md:grid-cols-2 2xl:grid-cols-4">
          <!-- Utilidad Total -->
          <div
            class="min-w-0 rounded-2xl border border-slate-200/80 bg-white p-6 shadow-[0_8px_24px_rgba(15,23,42,0.06)] dark:border-emerald-500/15 dark:bg-[#111c2e] dark:shadow-[0_8px_24px_rgba(0,0,0,0.18)]"
          >
            <div class="flex items-start justify-between gap-3">
              <div class="min-w-0 flex-1">
                <p class="text-[11px] font-bold uppercase tracking-[0.18em] text-slate-500">
                  Utilidad Total
                </p>
                <p
                  class="mt-3 truncate text-3xl font-black tracking-tight"
                  :class="totalProfit >= 0 ? 'text-emerald-600 dark:text-emerald-400' : 'text-red-600 dark:text-red-400'"
                >
                  {{ formatCurrency(totalProfit) }}
                </p>
                <p
                  v-if="totalMonthly"
                  class="mt-2 text-xs font-semibold"
                  :class="profitMargin >= 0 ? 'text-emerald-600 dark:text-emerald-400/80' : 'text-red-600 dark:text-red-400/80'"
                >
                  Margen: {{ profitMargin >= 0 ? '+' : '' }}{{ profitMargin.toFixed(1) }}%
                </p>
              </div>

              <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-emerald-50 dark:bg-emerald-500/10">
                <CircleDollarSign class="h-5 w-5 text-emerald-600 dark:text-emerald-400/70" />
              </div>
            </div>
          </div>

          <!-- Gastos Totales -->
          <div
            class="min-w-0 rounded-2xl border border-slate-200/80 bg-white p-6 shadow-[0_8px_24px_rgba(15,23,42,0.06)] dark:border-orange-500/15 dark:bg-[#111c2e] dark:shadow-[0_8px_24px_rgba(0,0,0,0.18)]"
          >
            <div class="flex items-start justify-between gap-3">
              <div class="min-w-0 flex-1">
                <p class="text-[11px] font-bold uppercase tracking-[0.18em] text-slate-500">
                  Gastos Totales
                </p>
                <p class="mt-3 truncate text-3xl font-black tracking-tight text-orange-600 dark:text-orange-400">
                  {{ formatCurrency(totalExpenses) }}
                </p>
                <p class="mt-2 text-xs font-semibold text-orange-600/70 dark:text-orange-400/70">
                  12 meses acumulado
                </p>
              </div>

              <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-orange-50 dark:bg-orange-500/10">
                <Wallet class="h-5 w-5 text-orange-600 dark:text-orange-400/70" />
              </div>
            </div>
          </div>

          <!-- Ganancia 8 sem -->
          <div
            class="min-w-0 rounded-2xl border border-slate-200/80 bg-white p-6 shadow-[0_8px_24px_rgba(15,23,42,0.06)] dark:border-teal-500/15 dark:bg-[#111c2e] dark:shadow-[0_8px_24px_rgba(0,0,0,0.18)]"
          >
            <div class="flex items-start justify-between gap-3">
              <div class="min-w-0 flex-1">
                <p class="text-[11px] font-bold uppercase tracking-[0.18em] text-slate-500">
                  Ganancia (8 sem)
                </p>
                <p
                  class="mt-3 truncate text-3xl font-black tracking-tight"
                  :class="totalWeeklyProfit >= 0 ? 'text-teal-600 dark:text-teal-400' : 'text-red-600 dark:text-red-400'"
                >
                  {{ formatCurrency(totalWeeklyProfit) }}
                </p>
                <p class="mt-2 text-xs font-semibold text-teal-600/70 dark:text-teal-400/70">
                  Acumulado semanal
                </p>
              </div>

              <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-teal-50 dark:bg-teal-500/10">
                <TrendingUp class="h-5 w-5 text-teal-600 dark:text-teal-400/70" />
              </div>
            </div>
          </div>

          <!-- Gastos 8 sem -->
          <div
            class="min-w-0 rounded-2xl border border-slate-200/80 bg-white p-6 shadow-[0_8px_24px_rgba(15,23,42,0.06)] dark:border-red-500/15 dark:bg-[#111c2e] dark:shadow-[0_8px_24px_rgba(0,0,0,0.18)]"
          >
            <div class="flex items-start justify-between gap-3">
              <div class="min-w-0 flex-1">
                <p class="text-[11px] font-bold uppercase tracking-[0.18em] text-slate-500">
                  Gastos (8 sem)
                </p>
                <p class="mt-3 truncate text-3xl font-black tracking-tight text-red-600 dark:text-red-400">
                  {{ formatCurrency(totalWeeklyExpenses) }}
                </p>
                <p class="mt-2 text-xs font-semibold text-red-600/70 dark:text-red-400/70">
                  Acumulado semanal
                </p>
              </div>

              <div class="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-red-50 dark:bg-red-500/10">
                <Wallet class="h-5 w-5 text-red-600 dark:text-red-400/70" />
              </div>
            </div>
          </div>
        </section>

        <!-- ROW 3: Charts -->
        <section class="grid grid-cols-1 gap-6 2xl:grid-cols-2">
          <!-- Ventas por semana -->
          <div class="min-w-0 overflow-hidden rounded-2xl border border-slate-200/80 bg-white shadow-[0_8px_24px_rgba(15,23,42,0.06)] dark:border-white/10 dark:bg-[#111c2e] dark:shadow-[0_8px_24px_rgba(0,0,0,0.18)]">
            <div class="flex items-center justify-between border-b border-slate-200/70 px-6 py-4 dark:border-white/5">
              <div class="flex min-w-0 items-center gap-2.5">
                <div class="flex h-8 w-8 items-center justify-center rounded-xl bg-blue-50 dark:bg-blue-500/10">
                  <CalendarDays class="h-4 w-4 text-blue-600 dark:text-blue-400" />
                </div>
                <h3 class="font-display text-sm font-bold tracking-wide text-slate-800 dark:text-white/90">
                  Ventas por semana
                </h3>
              </div>
            </div>

            <div>
              <div v-if="loading" class="flex items-center justify-center py-12">
                <div class="h-8 w-8 animate-spin rounded-full border-4 border-slate-200 border-t-blue-500 dark:border-slate-700 dark:border-t-blue-400"></div>
              </div>

              <template v-else>
                <div v-if="!weekly.length" class="py-12 text-center text-sm text-slate-400">
                  No hay datos
                </div>

                <ul v-else class="divide-y divide-slate-200/70 dark:divide-white/5">
                  <li
                    v-for="(row, i) in weekly"
                    :key="row.period"
                    class="flex items-center justify-between gap-4 px-6 py-4 transition hover:bg-blue-50/50 dark:hover:bg-blue-500/5"
                    :class="i % 2 === 0 ? 'bg-white dark:bg-transparent' : 'bg-slate-50/50 dark:bg-white/[0.02]'"
                  >
                    <span class="truncate text-sm font-medium text-slate-500 dark:text-slate-400">{{ row.period }}</span>
                    <span class="shrink-0 text-sm font-bold text-slate-900 dark:text-white">{{ formatCurrency(row.total) }}</span>
                  </li>
                </ul>
              </template>
            </div>
          </div>

          <!-- Ventas por mes -->
          <div class="min-w-0 overflow-hidden rounded-2xl border border-slate-200/80 bg-white shadow-[0_8px_24px_rgba(15,23,42,0.06)] dark:border-white/10 dark:bg-[#111c2e] dark:shadow-[0_8px_24px_rgba(0,0,0,0.18)]">
            <div class="flex items-center justify-between border-b border-slate-200/70 px-6 py-4 dark:border-white/5">
              <div class="flex min-w-0 items-center gap-2.5">
                <div class="flex h-8 w-8 items-center justify-center rounded-xl bg-cyan-50 dark:bg-cyan-500/10">
                  <BarChart3 class="h-4 w-4 text-cyan-600 dark:text-cyan-400" />
                </div>
                <h3 class="font-display text-sm font-bold tracking-wide text-slate-800 dark:text-white/90">
                  Ventas por mes
                </h3>
              </div>
            </div>

            <div class="space-y-4 p-6">
              <div v-if="loading" class="flex items-center justify-center py-12">
                <div class="h-8 w-8 animate-spin rounded-full border-4 border-slate-200 border-t-cyan-500 dark:border-slate-700 dark:border-t-cyan-400"></div>
              </div>

              <div v-else-if="isChartEmpty" class="py-12 text-center text-sm text-slate-400">
                No hay datos
              </div>

              <div v-else class="space-y-4">
                <div class="min-w-0 overflow-x-auto rounded-xl bg-[#f8fafc] p-4 dark:bg-[#0b1728]">
                  <SVGBarChart :series="chartSeries" />
                </div>

                <ul class="divide-y divide-slate-200/70 dark:divide-white/5">
                  <li
                    v-for="(row, i) in monthly"
                    :key="row.period"
                    class="flex items-center justify-between gap-4 rounded-lg px-3 py-3 transition hover:bg-cyan-50/50 dark:hover:bg-cyan-500/5"
                    :class="i % 2 === 0 ? 'bg-white dark:bg-transparent' : 'bg-slate-50/50 dark:bg-white/[0.02]'"
                  >
                    <span class="truncate text-sm font-medium text-slate-500 dark:text-slate-400">{{ row.period }}</span>
                    <span class="shrink-0 text-sm font-bold text-slate-900 dark:text-white">{{ formatCurrency(row.total) }}</span>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </section>

        <!-- ROW 4: Ingresos vs Egresos -->
        <section>
          <div class="min-w-0 overflow-hidden rounded-2xl border border-slate-200/80 bg-white shadow-[0_8px_24px_rgba(15,23,42,0.06)] dark:border-white/10 dark:bg-[#111c2e] dark:shadow-[0_8px_24px_rgba(0,0,0,0.18)]">
            <div class="flex flex-col gap-3 border-b border-slate-200/70 px-6 py-4 sm:flex-row sm:items-center sm:justify-between dark:border-white/5">
              <div class="flex min-w-0 items-center gap-2.5">
                <div class="flex h-8 w-8 items-center justify-center rounded-xl bg-emerald-50 dark:bg-emerald-500/10">
                  <TrendingUp class="h-4 w-4 text-emerald-600 dark:text-emerald-400" />
                </div>
                <h3 class="font-display text-sm font-bold tracking-wide text-slate-800 dark:text-white/90">
                  Ingresos vs Egresos
                </h3>
              </div>

              <div class="flex items-center gap-4 text-xs font-semibold">
                <span class="flex items-center gap-1.5">
                  <span class="h-2.5 w-2.5 rounded-full bg-emerald-500"></span>
                  <span class="text-slate-500 dark:text-slate-400">Ingresos</span>
                </span>
                <span class="flex items-center gap-1.5">
                  <span class="h-2.5 w-2.5 rounded-full bg-red-500"></span>
                  <span class="text-slate-500 dark:text-slate-400">Egresos</span>
                </span>
              </div>
            </div>

            <div class="space-y-5 p-6">
              <div v-if="loading" class="flex items-center justify-center py-10">
                <div class="h-8 w-8 animate-spin rounded-full border-4 border-slate-200 border-t-emerald-500 dark:border-slate-700 dark:border-t-emerald-400"></div>
              </div>

              <div v-else-if="isWeeklyProfitChartEmpty" class="py-10 text-center text-sm text-slate-400">
                No hay datos
              </div>

              <div v-else class="min-w-0 overflow-x-auto rounded-xl bg-[#f8fafc] p-4 dark:bg-[#0b1728]">
                <SVGBarChart :series="weeklyProfitChartSeries" />
              </div>

              <ul
                v-if="weeklyProfitRows.length"
                class="overflow-hidden rounded-xl border border-slate-200/70 divide-y divide-slate-200/70 dark:border-white/5 dark:divide-white/5"
              >
                <li
                  v-for="(row, i) in weeklyProfitRows"
                  :key="row.period"
                  class="grid grid-cols-1 gap-2 px-6 py-4 transition lg:grid-cols-[80px_1fr_1fr_auto] lg:items-center lg:gap-4"
                  :class="i % 2 === 0 ? 'bg-white dark:bg-transparent' : 'bg-slate-50/50 dark:bg-white/[0.02]'"
                >
                  <span class="font-display text-sm font-bold text-slate-700 dark:text-slate-300">{{ row.period }}</span>
                  <span class="text-sm text-slate-500 dark:text-slate-400">
                    Ingresos:
                    <strong class="font-bold text-slate-900 dark:text-white">{{ formatCurrency(row.ingresos) }}</strong>
                  </span>
                  <span class="text-sm text-slate-500 dark:text-slate-400">
                    Gastos:
                    <strong class="font-bold text-red-600 dark:text-red-400">{{ formatCurrency(row.gastos) }}</strong>
                  </span>
                  <span
                    class="text-sm font-bold"
                    :class="row.profit >= 0 ? 'text-emerald-600 dark:text-emerald-400' : 'text-red-600 dark:text-red-400'"
                  >
                    {{ row.profit >= 0 ? '+' : '' }}{{ formatCurrency(row.profit) }}
                  </span>
                </li>
              </ul>
            </div>
          </div>
        </section>

        <!-- ROW 5: Ventas por día -->
        <section>
          <div class="min-w-0 overflow-hidden rounded-2xl border border-slate-200/80 bg-white shadow-[0_8px_24px_rgba(15,23,42,0.06)] dark:border-white/10 dark:bg-[#111c2e] dark:shadow-[0_8px_24px_rgba(0,0,0,0.18)]">
            <div class="flex flex-col gap-3 border-b border-slate-200/70 px-6 py-4 sm:flex-row sm:items-center sm:justify-between dark:border-white/5">
              <div class="flex min-w-0 items-center gap-2.5">
                <div class="flex h-8 w-8 items-center justify-center rounded-xl bg-amber-50 dark:bg-amber-500/10">
                  <Calendar class="h-4 w-4 text-amber-600 dark:text-amber-400" />
                </div>
                <h3 class="font-display text-sm font-bold tracking-wide text-slate-800 dark:text-white/90">
                  Ventas por día
                </h3>
              </div>

              <div class="flex flex-wrap items-center gap-2">
                <input
                  v-model="selectedDate"
                  type="date"
                  class="rounded-xl border border-slate-200 bg-white px-3 py-2 text-sm text-slate-800 focus:border-amber-400 focus:outline-none focus:ring-2 focus:ring-amber-200 dark:border-white/10 dark:bg-[#0b1728] dark:text-white dark:focus:ring-amber-500/20"
                />
                <button
                  @click="consultarDia"
                  class="inline-flex items-center gap-1.5 rounded-xl bg-amber-500 px-4 py-2 text-sm font-bold text-white shadow-sm shadow-amber-200 transition hover:bg-amber-600 dark:text-slate-950 dark:shadow-none dark:hover:bg-amber-400"
                >
                  <Search class="h-3.5 w-3.5" />
                  Consultar
                </button>
              </div>
            </div>

            <div class="space-y-5 p-6">
              <div v-if="loading" class="flex items-center justify-center py-10">
                <div class="h-8 w-8 animate-spin rounded-full border-4 border-slate-200 border-t-amber-500 dark:border-slate-700 dark:border-t-amber-400"></div>
              </div>

              <div
                v-else-if="!daily.length || daily.every(d => !d.value)"
                class="py-10 text-center text-sm text-slate-400"
              >
                No hay datos para este día
              </div>

              <div v-else class="min-w-0 overflow-x-auto rounded-xl bg-[#f8fafc] p-4 dark:bg-[#0b1728]">
                <SVGBarChart :series="dailyChartSeries" />
              </div>

              <div v-if="dayRows.length">
                <div class="mb-4 flex items-center gap-3 rounded-xl border border-amber-200 bg-amber-50 px-5 py-3.5 dark:border-amber-500/20 dark:bg-amber-500/10">
                  <Receipt class="h-5 w-5 text-amber-600 dark:text-amber-400" />
                  <span class="font-display text-base font-bold text-slate-900 dark:text-white">Total del día:</span>
                  <span class="text-xl font-black text-amber-600 dark:text-amber-400">{{ formatCurrency(dayTotal) }}</span>
                </div>

                <ul class="overflow-hidden rounded-xl border border-slate-200/70 divide-y divide-slate-200/70 dark:border-white/5 dark:divide-white/5">
                  <li
                    v-for="(r, i) in dayRows"
                    :key="r.id"
                    class="flex items-center justify-between gap-4 px-6 py-4 transition"
                    :class="i % 2 === 0 ? 'bg-white dark:bg-transparent' : 'bg-slate-50/50 dark:bg-white/[0.02]'"
                  >
                    <div class="min-w-0">
                      <span class="block text-sm font-bold text-slate-900 dark:text-white">
                        {{ formatCurrency(r.total || 0) }}
                      </span>
                      <span class="block truncate text-xs font-medium text-slate-500 dark:text-slate-400">
                        {{ formatLocalDateTime(r.created_at) }}
                      </span>
                    </div>

                    <span
                      v-if="r.cliente_nombre"
                      class="shrink-0 rounded-full bg-amber-100 px-3 py-1 text-xs font-semibold text-amber-700 dark:bg-amber-500/15 dark:text-amber-300"
                    >
                      {{ r.cliente_nombre }}
                    </span>
                  </li>
                </ul>
              </div>

              <div v-else-if="!loading" class="text-sm text-slate-400">
                No hay ventas para la fecha seleccionada.
              </div>
            </div>
          </div>
        </section>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { useReportes, reportTimeZone } from '../composables/useReportes'
import SVGBarChart from './ui/SVGBarChart.vue'
import {
  TrendingUp,
  BarChart3,
  CircleDollarSign,
  Wallet,
  CalendarDays,
  Calendar,
  Search,
  Receipt,
  DollarSign,
} from 'lucide-vue-next'

const {
  ventasPorSemana,
  ventasPorMes,
  ventasPorDia,
  pedidosPorDia,
  gananciasYGastos,
  gananciasYGastosSemanales,
  loading,
} = useReportes()

const todayFormatted = computed(() => {
  const d = new Date()
  return d.toLocaleDateString('es-MX', {
    weekday: 'long',
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  })
})

function formatDateInTimeZone(date: Date, timeZone: string): string {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(date)
  const year = parts.find((p) => p.type === 'year')?.value
  const month = parts.find((p) => p.type === 'month')?.value
  const day = parts.find((p) => p.type === 'day')?.value
  if (!year || !month || !day) return ''
  return `${year}-${month}-${day}`
}

const weekly = ref<Array<{ period: string; total: number }>>([])
const monthly = ref<Array<{ period: string; total: number }>>([])
const profitRows = ref<any[]>([])
const weeklyProfitRows = ref<any[]>([])

async function load() {
  weekly.value = await ventasPorSemana(8, reportTimeZone)
  monthly.value = await ventasPorMes(12, reportTimeZone)
  profitRows.value = await gananciasYGastos(12, reportTimeZone)
  weeklyProfitRows.value = await gananciasYGastosSemanales(8, reportTimeZone)
}

onMounted(load)

const today = formatDateInTimeZone(new Date(), reportTimeZone)
const daily = ref<Array<{ category: string; value: number }>>([])

async function loadToday() {
  const s = await ventasPorDia(today, reportTimeZone)
  daily.value = (s || []).map((r: any) => ({
    category: utcHourToLocal(r.period, today) + ':00',
    value: Number(r.total || 0),
  }))
}

onMounted(loadToday)

const totalWeekly = computed(() => weekly.value.reduce((s, r) => s + (r.total || 0), 0))
const totalMonthly = computed(() => monthly.value.reduce((s, r) => s + (r.total || 0), 0))
const totalProfit = computed(() => profitRows.value.reduce((s, r) => s + (r.profit || 0), 0))
const totalExpenses = computed(() => profitRows.value.reduce((s, r) => s + (r.gastos || 0), 0))

const profitMargin = computed(() => {
  const revenue = totalMonthly.value
  if (!revenue) return 0
  return (totalProfit.value / revenue) * 100
})

const totalWeeklyProfit = computed(() =>
  weeklyProfitRows.value.reduce((s, r) => s + (r.profit || 0), 0)
)

const totalWeeklyExpenses = computed(() =>
  weeklyProfitRows.value.reduce((s, r) => s + (r.gastos || 0), 0)
)

const weeklyProfitChartSeries = computed(() =>
  (weeklyProfitRows.value || []).map((r: any) => ({
    category: r.period,
    value: r.profit || 0,
  }))
)

const isWeeklyProfitChartEmpty = computed(() => {
  const s = weeklyProfitChartSeries.value || []
  if (!s.length) return true
  return s.every((it) => !it.value)
})

function formatCurrency(n: number) {
  return new Intl.NumberFormat('es-MX', {
    style: 'currency',
    currency: 'MXN',
    maximumFractionDigits: 2,
  }).format(n || 0)
}

function formatLocalDateTime(iso: string) {
  if (!iso) return ''
  const d = new Date(iso)
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`
}

function utcHourToLocal(utcHour: string, dateStr: string): string {
  const d = new Date(dateStr + 'T' + utcHour.padStart(2, '0') + ':00:00Z')
  return String(d.getHours()).padStart(2, '0')
}

const chartSeries = computed(() =>
  (monthly.value || []).map((r) => ({
    category: r.period,
    value: r.total || 0,
  }))
)

const isChartEmpty = computed(() => {
  const s = chartSeries.value || []
  if (!s.length) return true
  return s.every((it) => !it.value)
})

const selectedDate = ref<string | null>(today)
const dayRows = ref<any[]>([])
const dayTotal = ref<number>(0)

async function consultarDia() {
  if (!selectedDate.value) return

  const series = await ventasPorDia(selectedDate.value, reportTimeZone)
  const d = selectedDate.value
  daily.value = (series || []).map((r: any) => ({
    category: utcHourToLocal(r.period, d) + ':00',
    value: Number(r.total || 0),
  }))

  const res = await pedidosPorDia(selectedDate.value, reportTimeZone)
  dayRows.value = res.rows || []
  dayTotal.value = res.total || 0
}

onMounted(async () => {
  const res = await pedidosPorDia(today, reportTimeZone)
  dayRows.value = res.rows || []
  dayTotal.value = res.total || 0
})

const dailyChartSeries = computed(() => daily.value || [])
</script>