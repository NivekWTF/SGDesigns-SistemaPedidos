<template>
  <aside :class="['sidebar', { collapsed: effectiveCollapsed }]" @mouseenter="onMouseEnter" @mouseleave="onMouseLeave">
    <div class="brand">
      <div class="logo">SG</div>
      <div v-show="!effectiveCollapsed" class="brand-text">SG Designs</div>
    </div>

    <nav class="nav-list">
      <router-link to="/" class="nav-item" :title="effectiveCollapsed ? 'Inicio' : ''">
        <span class="icon">🏠</span>
        <span v-show="!effectiveCollapsed" class="label">Inicio</span>
      </router-link>

      <router-link to="/pedidos" class="nav-item" :title="effectiveCollapsed ? 'Pedidos' : ''">
        <span class="icon">📦</span>
        <span v-show="!effectiveCollapsed" class="label">Pedidos</span>
      </router-link>

      <router-link to="/clientes" class="nav-item" :title="effectiveCollapsed ? 'Clientes' : ''">
        <span class="icon">👥</span>
        <span v-show="!effectiveCollapsed" class="label">Clientes</span>
      </router-link>

      <router-link to="/productos" class="nav-item" :title="effectiveCollapsed ? 'Productos' : ''">
        <span class="icon">🛒</span>
        <span v-show="!effectiveCollapsed" class="label">Productos</span>
      </router-link>
    </nav>

    <div class="spacer" />

    <div class="controls">
      <button class="collapse-btn" @click="toggle" :title="effectiveCollapsed ? 'Expandir' : 'Colapsar'">
        <span v-if="effectiveCollapsed">➡️</span>
        <span v-else>⬅️</span>
      </button>
    </div>
  </aside>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'

const STORAGE_KEY = 'sidebar-collapsed'
// user preference: true = collapsed, false = expanded
const collapsed = ref<boolean>(localStorage.getItem(STORAGE_KEY) === '1')
const hovered = ref(false)

const effectiveCollapsed = computed(() => {
  // when user set collapsed=true, collapse unless hovered
  return collapsed.value && !hovered.value
})

function toggle() {
  collapsed.value = !collapsed.value
  localStorage.setItem(STORAGE_KEY, collapsed.value ? '1' : '0')
  // notify other parts of the app (layout) about the change
  try { window.dispatchEvent(new CustomEvent('sidebar-toggle', { detail: { collapsed: collapsed.value } })) } catch(e) {}
}

function onMouseEnter() {
  // expand on hover only if currently collapsed by preference
  if (collapsed.value) hovered.value = true
}

function onMouseLeave() {
  if (collapsed.value) hovered.value = false
}
</script>

<style scoped>
.sidebar{width:220px;background:#ffffff;border-right:1px solid #eef2f6;display:flex;flex-direction:column;padding:12px 8px;transition:width .22s cubic-bezier(.2,.9,.3,1), transform .22s cubic-bezier(.2,.9,.3,1);box-sizing:border-box;overflow:hidden;position:fixed;top:0;left:0;height:100vh;z-index:90}
.sidebar.collapsed{width:72px}
.brand-text{font-weight:700;color:#0f172a;transition:opacity .18s ease, transform .18s ease}
.brand-text[style*="display: none"]{opacity:0}
.label{font-weight:600;transition:opacity .18s ease, transform .18s ease}
.label[style*="display: none"]{opacity:0}
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

.nav-item .icon{transition:transform .18s ease}
.sidebar.collapsed .nav-item .icon{transform:none}
.sidebar .nav-item .label{white-space:nowrap}

/* compact styling inspired by reference: subtle labels, rounded cards, vertical list */

/* Responsive: on small screens make sidebar act as overlay */
@media (max-width: 768px) {
  .sidebar {
    /* hide by default on small screens using transform */
    transform: translateX(-100%);
    width: 220px; /* expanded width when visible */
  }

  .sidebar:not(.collapsed) {
    /* when not collapsed show overlay */
    transform: translateX(0);
  }

  .sidebar.collapsed {
    /* keep hidden when collapsed on mobile */
    transform: translateX(-100%);
  }
}
</style>
