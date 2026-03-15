<template>
  <div class="w-full" role="img">
    <svg :viewBox="`0 0 ${width} ${height}`" preserveAspectRatio="xMidYMid meet" class="w-full block" :style="{ height: height + 'px' }">
      <defs>
        <linearGradient v-for="(_, i) in series" :key="'g'+i" :id="'bar-grad-'+i" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0%" :stop-color="getColor(i)" stop-opacity="0.9" />
          <stop offset="100%" :stop-color="getColor(i)" stop-opacity="0.55" />
        </linearGradient>
      </defs>
      <!-- Grid lines -->
      <line
        v-for="tick in 4" :key="'grid'+tick"
        :x1="padding" :x2="width - padding"
        :y1="padding + ((height - padding * 2) / 4) * (4 - tick)"
        :y2="padding + ((height - padding * 2) / 4) * (4 - tick)"
        class="stroke-slate-200 dark:stroke-slate-700" stroke-width="1"
      />
      <!-- Bars -->
      <g v-for="(d, i) in series" :key="i">
        <rect
          :x="padding + i * (barW + gap) + gap / 2"
          :y="height - padding - getBarH(d)"
          :width="barW"
          :height="Math.max(getBarH(d), 0)"
          :fill="`url(#bar-grad-${i})`"
          rx="4" ry="4"
        >
          <title>{{ d.category }}: {{ typeof d.value === 'number' ? d.value.toLocaleString() : d.value }}</title>
        </rect>
        <!-- Value label on top -->
        <text
          v-if="getBarH(d) > 12"
          :x="padding + i * (barW + gap) + gap / 2 + barW / 2"
          :y="height - padding - getBarH(d) - 6"
          text-anchor="middle"
          class="fill-slate-500 dark:fill-slate-400 text-[10px] font-medium"
        >
          {{ formatShort(d.value) }}
        </text>
        <!-- Category label -->
        <text
          :x="padding + i * (barW + gap) + gap / 2 + barW / 2"
          :y="height - 4"
          text-anchor="middle"
          class="fill-slate-400 dark:fill-slate-500 text-[10px]"
        >
          {{ d.category }}
        </text>
      </g>
    </svg>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

type Item = { category: string; value: number }
const props = defineProps<{ series?: Item[] }>()

const width = 900
const height = 200
const padding = 24
const gap = 8

const series = computed(() => props.series || [])

const COLORS = ['#0ea5e9', '#14b8a6', '#f59e0b', '#ef4444', '#8b5cf6', '#ec4899', '#06b6d4', '#84cc16']

function getColor(i: number) {
  return COLORS[i % COLORS.length]
}

const barW = computed(() => {
  const n = Math.max(series.value.length, 1)
  const avail = width - padding * 2 - gap * n
  return Math.max(Math.floor(avail / n), 10)
})

function getBarH(d: Item) {
  const vals = series.value.map(s => Number(s.value || 0))
  const max = Math.max(...vals, 1)
  return Math.round(((height - padding * 2 - 16) * Number(d.value || 0)) / max)
}

function formatShort(n: number) {
  if (n >= 1000) return '$' + (n / 1000).toFixed(1) + 'k'
  return '$' + (n || 0).toFixed(0)
}
</script>
