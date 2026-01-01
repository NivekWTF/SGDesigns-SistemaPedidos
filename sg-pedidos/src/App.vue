<script setup lang="ts">
</script>

<template>
  <div class="app-shell">
    <Sidebar />

    <div class="main-column">
      <header class="topbar">
        <!-- Navigation moved to Sidebar; topbar left intentionally blank -->
      </header>

      <main class="content">
        <router-view />
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
import Sidebar from './components/Sidebar.vue'
</script>

<style scoped>
.app-shell{display:flex;min-height:100vh;background:#f6f7fb}
.main-column{flex:1;display:flex;flex-direction:column}
.topbar{border-bottom:1px solid #eee;background:#fff}
.topbar-inner{display:flex;gap:12px;padding:12px}
.top-link{color:#334155;text-decoration:none}
.top-link.router-link-active{font-weight:700}
.content{padding:16px}
</style>
