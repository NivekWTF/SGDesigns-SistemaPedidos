<template>
  <aside :class="['sidebar', { collapsed }]" @mouseleave="onMouseLeave">
    <div class="brand">
      <div class="logo">SG</div>
      <div v-if="!collapsed" class="brand-text">SG Designs</div>
    </div>

    <nav class="nav-list">
      <router-link to="/pedidos" class="nav-item" :title="collapsed ? 'Pedidos' : ''">
        <span class="icon">📦</span>
        <span v-if="!collapsed" class="label">Pedidos</span>
      </router-link>

      <router-link to="/clientes" class="nav-item" :title="collapsed ? 'Clientes' : ''">
        <span class="icon">👥</span>
        <span v-if="!collapsed" class="label">Clientes</span>
      </router-link>

      <router-link to="/productos" class="nav-item" :title="collapsed ? 'Productos' : ''">
        <span class="icon">🛒</span>
        <span v-if="!collapsed" class="label">Productos</span>
      </router-link>
    </nav>

    <div class="spacer" />

    <div class="controls">
      <button class="collapse-btn" @click="toggle">
        <span v-if="collapsed">➡️</span>
        <span v-else>⬅️</span>
      </button>
    </div>
  </aside>
</template>

<script setup lang="ts">
import { ref } from 'vue'

const STORAGE_KEY = 'sidebar-collapsed'
const collapsed = ref<boolean>(localStorage.getItem(STORAGE_KEY) === '1')

function toggle() {
  collapsed.value = !collapsed.value
  localStorage.setItem(STORAGE_KEY, collapsed.value ? '1' : '0')
}

// optional: expand when mouse enters if collapsed (small hover behavior)
let hoverTimeout: any = null
function onMouseLeave() {
  if (collapsed.value) return
  // no-op
}
</script>

<style scoped>
.sidebar{width:220px;background:#ffffff;border-right:1px solid #eef2f6;display:flex;flex-direction:column;padding:12px 8px;transition:width .18s ease;min-height:100vh;box-sizing:border-box}
.sidebar.collapsed{width:72px}
.brand{display:flex;align-items:center;gap:10px;padding:8px 6px}
.logo{width:40px;height:40px;border-radius:8px;background:#0ea5a4;color:white;display:flex;align-items:center;justify-content:center;font-weight:700}
.brand-text{font-weight:700;color:#0f172a}
.nav-list{display:flex;flex-direction:column;margin-top:8px;gap:6px}
.nav-item{display:flex;align-items:center;gap:12px;padding:10px;border-radius:8px;color:#0f172a;text-decoration:none}
.nav-item:hover{background:#f1f5f9}
.icon{width:28px;height:28px;display:inline-flex;align-items:center;justify-content:center;font-size:16px}
.label{font-weight:600}
.spacer{flex:1}
.controls{display:flex;justify-content:center;padding:8px}
.collapse-btn{background:#fff;border:1px solid #e6eef2;padding:8px;border-radius:8px;cursor:pointer}

/* compact styling inspired by reference: subtle labels, rounded cards, vertical list */
</style>
