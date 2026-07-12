<template>
  <!-- Single bone -->
  <div v-if="variant === 'text'" class="skeleton-bone skeleton-text" :style="{ width: width || '100%', height: height || '14px' }" />

  <!-- Title bone -->
  <div v-else-if="variant === 'title'" class="skeleton-bone skeleton-title" :style="{ width: width || '55%', height: height || '24px' }" />

  <!-- Circle / avatar -->
  <div v-else-if="variant === 'circle'" class="skeleton-bone skeleton-circle" :style="{ width: width || '40px', height: height || '40px' }" />

  <!-- Stat card skeleton -->
  <div v-else-if="variant === 'card'" class="skeleton-card-grid">
    <div v-for="n in count" :key="n" class="skeleton-stat-card">
      <div class="skeleton-bone" style="width:45%;height:28px;border-radius:8px" />
      <div class="skeleton-bone" style="width:65%;height:13px;margin-top:10px;border-radius:6px" />
    </div>
  </div>

  <!-- KPI hero card skeleton (HomeView) -->
  <div v-else-if="variant === 'kpi'" class="skeleton-kpi-grid">
    <div v-for="n in count" :key="n" class="skeleton-kpi-card">
      <div class="skeleton-kpi-body">
        <div>
          <div class="skeleton-bone" style="width:90px;height:11px;border-radius:5px" />
          <div class="skeleton-bone" style="width:140px;height:36px;margin-top:14px;border-radius:8px" />
          <div style="display:flex;align-items:center;gap:8px;margin-top:14px">
            <div class="skeleton-bone" style="width:8px;height:8px;border-radius:50%" />
            <div class="skeleton-bone" style="width:100px;height:11px;border-radius:5px" />
          </div>
        </div>
        <div class="skeleton-bone skeleton-kpi-icon" />
      </div>
    </div>
  </div>

  <!-- Table rows skeleton -->
  <div v-else-if="variant === 'table-row'" class="skeleton-table">
    <div v-for="n in count" :key="n" class="skeleton-row" :style="{ '--cols': columns }">
      <div
        v-for="c in columns"
        :key="c"
        class="skeleton-bone skeleton-cell"
        :style="{ width: cellWidth(c), height: '14px' }"
      />
    </div>
  </div>

  <!-- Chart placeholder skeleton -->
  <div v-else-if="variant === 'chart'" class="skeleton-chart-wrapper">
    <div class="skeleton-chart-bars">
      <div v-for="n in 7" :key="n" class="skeleton-bone skeleton-bar" :style="{ height: barHeight(n) }" />
    </div>
    <div class="skeleton-bone" style="width:100%;height:1px;border-radius:0;margin-top:4px" />
  </div>

  <!-- List rows skeleton -->
  <div v-else-if="variant === 'list'" class="skeleton-list">
    <div v-for="n in count" :key="n" class="skeleton-list-item">
      <div class="skeleton-bone" style="height:14px;border-radius:6px" :style="{ width: n % 2 === 0 ? '55%' : '70%' }" />
      <div class="skeleton-bone" style="width:80px;height:14px;border-radius:6px" />
    </div>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  variant: 'text' | 'title' | 'circle' | 'card' | 'kpi' | 'table-row' | 'chart' | 'list'
  count?: number
  columns?: number
  width?: string
  height?: string
}>()

function cellWidth(colIndex: number): string {
  const widths = ['60%', '80%', '50%', '70%', '45%', '55%', '65%']
  return widths[(colIndex - 1) % widths.length]
}

function barHeight(n: number): string {
  const heights = ['55%', '80%', '45%', '95%', '60%', '75%', '40%']
  return heights[(n - 1) % heights.length]
}
</script>

<style scoped>
/* ---- Stat Card Grid ---- */
.skeleton-card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
  gap: 12px;
}

.skeleton-stat-card {
  background: #fff;
  border: 1px solid #eee;
  padding: 16px;
  border-radius: 8px;
}
:is(.dark) .skeleton-stat-card {
  background: #111c2e;
  border-color: #1e293b;
}

/* ---- KPI Hero Grid ---- */
.skeleton-kpi-grid {
  display: grid;
  grid-template-columns: repeat(1, 1fr);
  gap: 24px;
}
@media (min-width: 1024px) {
  .skeleton-kpi-grid { grid-template-columns: repeat(2, 1fr); }
}
@media (min-width: 1280px) {
  .skeleton-kpi-grid { grid-template-columns: repeat(4, 1fr); }
}

.skeleton-kpi-card {
  overflow: hidden;
  border-radius: 24px;
  border: 1px solid #e2e8f0;
  background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
  padding: 32px;
  box-shadow: 0 8px 24px rgba(15,23,42,0.06);
}
:is(.dark) .skeleton-kpi-card {
  border-color: rgba(255,255,255,0.08);
  background: linear-gradient(135deg, #111c2e 0%, #0f1729 100%);
  box-shadow: 0 10px 30px rgba(0,0,0,0.22);
}

.skeleton-kpi-body {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 16px;
}

.skeleton-kpi-icon {
  width: 56px;
  height: 56px;
  border-radius: 16px;
  flex-shrink: 0;
}

/* ---- Table Rows ---- */
.skeleton-table {
  display: flex;
  flex-direction: column;
}

.skeleton-row {
  display: grid;
  grid-template-columns: repeat(var(--cols, 5), 1fr);
  align-items: center;
  padding: 14px 12px;
  border-bottom: 1px solid #f3f3f3;
  gap: 12px;
}
:is(.dark) .skeleton-row {
  border-bottom-color: #1e293b;
}

.skeleton-cell {
  border-radius: 6px;
}

/* ---- Chart ---- */
.skeleton-chart-wrapper {
  padding: 16px;
  background: #f8fafc;
  border-radius: 12px;
}
:is(.dark) .skeleton-chart-wrapper {
  background: #0b1728;
}

.skeleton-chart-bars {
  display: flex;
  align-items: flex-end;
  gap: 12px;
  height: 140px;
}

.skeleton-bar {
  flex: 1;
  border-radius: 6px 6px 0 0;
}

/* ---- List ---- */
.skeleton-list {
  display: flex;
  flex-direction: column;
}

.skeleton-list-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 24px;
  border-bottom: 1px solid #f0f0f0;
}
:is(.dark) .skeleton-list-item {
  border-bottom-color: rgba(255,255,255,0.05);
}
</style>
