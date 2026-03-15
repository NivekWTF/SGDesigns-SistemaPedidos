<template>
  <div class="chart-container">
    <slot />
  </div>
</template>

<script setup lang="ts">
import { defineProps } from 'vue'

defineProps<{ config?: any }>()
</script>

<style scoped>
.chart-container{background:linear-gradient(180deg,#fff,#fbfdff);padding:12px;border-radius:8px;border:1px solid #eef2f6}
</style>
