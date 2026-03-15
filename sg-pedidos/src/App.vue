<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount } from 'vue'
import { useRoute } from 'vue-router'
import Sidebar from './components/Sidebar.vue'

const route = useRoute()

const STORAGE_KEY = 'sidebar-collapsed'
const collapsed = ref<boolean>(localStorage.getItem(STORAGE_KEY) === '1')
const mobileOpen = ref(false)

function updateCollapsedFromStorage() {
  collapsed.value = localStorage.getItem(STORAGE_KEY) === '1'
}

function toggleMobileSidebar() {
  mobileOpen.value = !mobileOpen.value
}

function closeMobileSidebar() {
  mobileOpen.value = false
}

// Close mobile sidebar on route change
import { watch } from 'vue'
watch(() => route.path, () => { mobileOpen.value = false })

onMounted(() => {
  const handler = (e: any) => { if (e && e.detail && typeof e.detail.collapsed !== 'undefined') collapsed.value = !!e.detail.collapsed }
  window.addEventListener('sidebar-toggle', handler as EventListener)
  const storageHandler = (ev: StorageEvent) => { if (ev.key === STORAGE_KEY) updateCollapsedFromStorage() }
  window.addEventListener('storage', storageHandler)
  ;(window as any).__sidebar_handlers = { handler, storageHandler }
})

onBeforeUnmount(() => {
  const h = (window as any).__sidebar_handlers
  if (h) {
    window.removeEventListener('sidebar-toggle', h.handler)
    window.removeEventListener('storage', h.storageHandler)
    delete (window as any).__sidebar_handlers
  }
})

const sidebarWidth = () => (collapsed.value ? 72 : 220)
</script>

<template>
  <div class="app-shell">
    <!-- Mobile backdrop -->
    <Transition name="fade">
      <div v-if="mobileOpen" class="mobile-backdrop" @click="closeMobileSidebar" />
    </Transition>

    <Sidebar :mobileOpen="mobileOpen" @close-mobile="closeMobileSidebar" />

    <div class="main-column" :style="{ paddingLeft: sidebarWidth() + 'px' }">
      <header class="topbar">
        <div class="topbar-inner">
          <button class="hamburger-btn" @click="toggleMobileSidebar" aria-label="Abrir menú">
            <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <line x1="3" y1="6" x2="21" y2="6"/>
              <line x1="3" y1="12" x2="21" y2="12"/>
              <line x1="3" y1="18" x2="21" y2="18"/>
            </svg>
          </button>
          <span class="topbar-title">{{ route.meta?.title || route.name || 'SG Designs' }}</span>
        </div>
      </header>

      <main class="content">
        <router-view />
      </main>
    </div>
  </div>
</template>

<style scoped>
.app-shell{display:flex;height:100vh;background:#f6f7fb;transition:background .3s ease}
:is(.dark) .app-shell{background:#0c1222}
.main-column{flex:1;display:flex;flex-direction:column;transition:padding-left .22s cubic-bezier(.2,.9,.3,1);min-width:0}
.topbar{border-bottom:1px solid #eee;background:#fff;display:none;transition:background .3s ease, border-color .3s ease}
:is(.dark) .topbar{background:#0f1729;border-bottom-color:#1e293b}
.topbar-inner{display:flex;gap:12px;padding:10px 16px;align-items:center}
.topbar-title{font-weight:700;font-size:16px;color:#0f172a}
:is(.dark) .topbar-title{color:#e2e8f0}
.hamburger-btn{
  display:flex;align-items:center;justify-content:center;
  background:transparent;border:1px solid #e6eef2;padding:6px;border-radius:8px;
  cursor:pointer;color:#334155;flex-shrink:0;
}
.hamburger-btn:hover{background:#f1f5f9}
:is(.dark) .hamburger-btn{border-color:#334155;color:#94a3b8}
:is(.dark) .hamburger-btn:hover{background:#1e293b}
.content{padding:16px;overflow-y:auto;flex:1}

/* Mobile backdrop overlay */
.mobile-backdrop{
  display:none;
  position:fixed;inset:0;
  background:rgba(0,0,0,.4);
  z-index:80;
  backdrop-filter:blur(2px);
}
.fade-enter-active,.fade-leave-active{transition:opacity .22s ease}
.fade-enter-from,.fade-leave-to{opacity:0}

/* On small screens: show topbar/hamburger, remove sidebar padding, show backdrop */
@media (max-width: 768px) {
  .main-column { padding-left: 0 !important }
  .topbar { display:block }
  .mobile-backdrop { display:block }
}
</style>
