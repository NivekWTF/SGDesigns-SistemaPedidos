<template>
  <ChartContainer>
    <div class="fallback-chart">
      <div class="bars">
        <div v-for="(d, i) in series" :key="i" class="bar-wrapper">
          <div
            class="bar"
            :style="{ height: getBarHeight(d), background: getColor(i) }"
            :title="d.category + ': ' + d.value"
          ></div>
          <div class="label">{{ d.category }}</div>
        </div>
      </div>
    </div>
  </ChartContainer>
</template>

<script setup lang="ts">
import { defineProps, withDefaults, onMounted, watch, computed } from 'vue'
import ChartContainer from './ChartContainer.vue'

type Item = { category: string; value: number }

const props = withDefaults(defineProps<{ series?: Item[] }>(), {
  series: () => [
    { category: 'Ene', value: 120 },
    { category: 'Feb', value: 80 },
    { category: 'Mar', value: 150 },
    { category: 'Abr', value: 90 },
    { category: 'May', value: 130 },
  ],
})

const series = computed(() => props.series || [])

onMounted(() => {
  // eslint-disable-next-line no-console
  console.log('[ChartDemo] mounted series:', series)
})

watch(() => props.series, (v) => {
  // eslint-disable-next-line no-console
  console.log('[ChartDemo] series changed:', v)
}, { deep: true })

function getColor(i: number) {
  const colors = ['#2563eb', '#0ea5a4', '#f59e0b', '#ef4444', '#7c3aed']
  return colors[i % colors.length]
}

function getBarHeight(d: Item) {
  const arr = series.value || []
  const values = arr.map(s => Number(s.value || 0))
  const max = Math.max(...values, 1)
  const pct = (Number(d.value || 0) / max) * 100
  return `${Math.max(pct, 2)}%`
}
</script>

<style scoped>
.fallback-chart{width:100%;}
.bars{display:flex;gap:10px;align-items:stretch;padding:12px;height:220px}
.bar-wrapper{display:flex;flex-direction:column;align-items:center;width:56px;height:100%}
.bar{width:100%;border-radius:6px;flex:1 1 auto;min-height:4px;border:1px solid rgba(0,0,0,0.06);box-shadow:inset 0 -6px 12px rgba(0,0,0,0.02)}
.label{font-size:11px;margin-top:6px;text-align:center;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
</style>
