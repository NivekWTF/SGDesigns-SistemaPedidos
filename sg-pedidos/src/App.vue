<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount } from 'vue'
import Sidebar from './components/Sidebar.vue'

const STORAGE_KEY = 'sidebar-collapsed'
const collapsed = ref<boolean>(localStorage.getItem(STORAGE_KEY) === '1')

function updateCollapsedFromStorage() {
  collapsed.value = localStorage.getItem(STORAGE_KEY) === '1'
}

onMounted(() => {
  // listen to custom toggle events
  const handler = (e: any) => { if (e && e.detail && typeof e.detail.collapsed !== 'undefined') collapsed.value = !!e.detail.collapsed }
  window.addEventListener('sidebar-toggle', handler as EventListener)
  // also update when other tabs change localStorage
  const storageHandler = (ev: StorageEvent) => { if (ev.key === STORAGE_KEY) updateCollapsedFromStorage() }
  window.addEventListener('storage', storageHandler)

  // store handlers for cleanup
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
    <Sidebar />

    <div class="main-column" :style="{ paddingLeft: sidebarWidth() + 'px' }">
      <header class="topbar">
        <!-- Navigation moved to Sidebar; topbar left intentionally blank -->
      </header>

      <main class="content">
        <router-view />
      </main>
    </div>
  </div>
</template>

<style scoped>
.app-shell{display:flex;height:100vh;background:#f6f7fb}
.main-column{flex:1;display:flex;flex-direction:column;transition:padding-left .22s cubic-bezier(.2,.9,.3,1)}
.topbar{border-bottom:1px solid #eee;background:#fff}
.topbar-inner{display:flex;gap:12px;padding:12px}
.top-link{color:#334155;text-decoration:none}
.top-link.router-link-active{font-weight:700}
.content{padding:16px}

/* On small screens don't reserve padding for the sidebar (overlay) */
@media (max-width: 768px) {
  .main-column { padding-left: 0 !important }
}
</style>
