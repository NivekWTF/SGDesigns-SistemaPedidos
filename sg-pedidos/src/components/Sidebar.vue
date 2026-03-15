<template>
  <aside
    :class="['sidebar', { collapsed: effectiveCollapsed, 'mobile-open': mobileOpen }]"
    @mouseenter="onMouseEnter"
    @mouseleave="onMouseLeave"
  >
    <!-- Close button for mobile overlay -->
    <button class="mobile-close-btn" @click="$emit('close-mobile')" aria-label="Cerrar menú">
      <X class="h-5 w-5" />
    </button>

    <div class="brand">
      <button class="logo-btn" @click.stop="toggleMenu" :title="user ? (user.user_metadata?.full_name || user.email) : 'Perfil'">
        <svg width="28" height="28" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden>
          <circle cx="12" cy="8" r="3.2" stroke="#fff" stroke-width="1.2" />
          <path d="M4 20c1.6-3.6 4.8-6 8-6s6.4 2.4 8 6" stroke="#fff" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      </button>

      <div v-show="!effectiveCollapsed || mobileOpen" class="brand-text">
        <template v-if="user">
          <div class="brand-row">
            <img v-if="user.user_metadata?.avatar_url" :src="user.user_metadata.avatar_url" alt="avatar" class="avatar" />
            <div class="brand-name">{{ user.user_metadata?.full_name || user.user_metadata?.name || user.email }}</div>
          </div>

          <div v-if="menuOpen" class="quick-menu" @click.stop>
            <a class="menu-item" @click="goToProfile">Perfil</a>
            <a class="menu-item" @click="handleSignOut">Cerrar sesión</a>
          </div>
        </template>
        <template v-else>
          <span class="font-display text-lg font-bold tracking-wide">SG Designs</span>
        </template>
      </div>
      <div v-if="effectiveCollapsed && !mobileOpen" class="brand-collapsed">
        <button class="menu-btn-collapsed" @click.stop="toggleMenu">
          <img v-if="user?.user_metadata?.avatar_url" :src="user.user_metadata.avatar_url" class="avatar" />
          <span v-else>SG</span>
        </button>
      </div>
    </div>

    <nav class="nav-list">
      <router-link to="/" class="nav-item" :title="effectiveCollapsed && !mobileOpen ? 'Inicio' : ''" @click="closeMobile">
        <span class="icon"><LayoutDashboard class="h-[18px] w-[18px]" /></span>
        <span v-show="!effectiveCollapsed || mobileOpen" class="label">Inicio</span>
      </router-link>

      <router-link to="/pedidos" class="nav-item" :title="effectiveCollapsed && !mobileOpen ? 'Pedidos' : ''" @click="closeMobile">
        <span class="icon"><Package class="h-[18px] w-[18px]" /></span>
        <span v-show="!effectiveCollapsed || mobileOpen" class="label">Pedidos</span>
      </router-link>

      <router-link to="/clientes" class="nav-item" :title="effectiveCollapsed && !mobileOpen ? 'Clientes' : ''" @click="closeMobile">
        <span class="icon"><Users class="h-[18px] w-[18px]" /></span>
        <span v-show="!effectiveCollapsed || mobileOpen" class="label">Clientes</span>
      </router-link>

      <router-link to="/productos" class="nav-item" :title="effectiveCollapsed && !mobileOpen ? 'Productos' : ''" @click="closeMobile">
        <span class="icon"><ShoppingCart class="h-[18px] w-[18px]" /></span>
        <span v-show="!effectiveCollapsed || mobileOpen" class="label">Productos</span>
      </router-link>

      <router-link to="/gastos" class="nav-item" :title="effectiveCollapsed && !mobileOpen ? 'Gastos' : ''" @click="closeMobile">
        <span class="icon"><Wallet class="h-[18px] w-[18px]" /></span>
        <span v-show="!effectiveCollapsed || mobileOpen" class="label">Gastos</span>
      </router-link>

      <router-link to="/reporte-productos" class="nav-item" :title="effectiveCollapsed && !mobileOpen ? 'Ventas Producto' : ''" @click="closeMobile">
        <span class="icon"><BarChart3 class="h-[18px] w-[18px]" /></span>
        <span v-show="!effectiveCollapsed || mobileOpen" class="label">Ventas Producto</span>
      </router-link>
    </nav>

    <div class="spacer" />

    <div class="controls">
      <button class="theme-btn" @click="toggleTheme" :title="isDark ? 'Modo claro' : 'Modo oscuro'">
        <Sun v-if="isDark" class="h-4 w-4" />
        <Moon v-else class="h-4 w-4" />
        <span v-show="!effectiveCollapsed || mobileOpen" class="label">{{ isDark ? 'Claro' : 'Oscuro' }}</span>
      </button>
      <button class="collapse-btn desktop-only" @click="toggle" :title="effectiveCollapsed ? 'Expandir' : 'Colapsar'">
        <ChevronRight v-if="effectiveCollapsed" class="h-4 w-4" />
        <ChevronLeft v-else class="h-4 w-4" />
      </button>
    </div>
  </aside>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useAuth } from '../composables/useAuth'
import { LayoutDashboard, Package, Users, ShoppingCart, Wallet, BarChart3, ChevronLeft, ChevronRight, X, Sun, Moon } from 'lucide-vue-next'

const props = defineProps<{
  mobileOpen?: boolean
}>()

const emit = defineEmits<{
  (e: 'close-mobile'): void
}>()

const { user } = useAuth()

const STORAGE_KEY = 'sidebar-collapsed'
const collapsed = ref<boolean>(localStorage.getItem(STORAGE_KEY) === '1')
const hovered = ref(false)

const menuOpen = ref(false)
const preventHoverExpand = ref(false)

import { useRouter } from 'vue-router'
const router = useRouter()
const { signOut } = useAuth()

const effectiveCollapsed = computed(() => {
  return collapsed.value && !hovered.value
})

function toggle() {
  collapsed.value = !collapsed.value
  localStorage.setItem(STORAGE_KEY, collapsed.value ? '1' : '0')
  try { window.dispatchEvent(new CustomEvent('sidebar-toggle', { detail: { collapsed: collapsed.value } })) } catch(e) {}
}

function closeMobile() {
  emit('close-mobile')
}

function onMouseEnter() {
  if (collapsed.value && !preventHoverExpand.value) hovered.value = true
}

function onMouseLeave() {
  if (collapsed.value) hovered.value = false
}

function goToProfile(){
  menuOpen.value = false
  emit('close-mobile')
  router.push('/profile')
}

async function handleSignOut(){
  menuOpen.value = false
  emit('close-mobile')
  await signOut()
  router.push('/login')
}

function toggleMenu(){
  menuOpen.value = !menuOpen.value
  preventHoverExpand.value = menuOpen.value
  if (preventHoverExpand.value) {
    setTimeout(()=>{ preventHoverExpand.value = false }, 1000)
  }
}

// Dark mode
const THEME_KEY = 'theme'
const isDark = ref(localStorage.getItem(THEME_KEY) === 'dark')

function applyTheme() {
  document.documentElement.classList.toggle('dark', isDark.value)
}

function toggleTheme() {
  isDark.value = !isDark.value
  localStorage.setItem(THEME_KEY, isDark.value ? 'dark' : 'light')
  applyTheme()
}

// Apply on mount
applyTheme()
</script>

<style scoped>
.sidebar{width:220px;background:#ffffff;border-right:1px solid #eef2f6;display:flex;flex-direction:column;padding:12px 8px;transition:width .22s cubic-bezier(.2,.9,.3,1), transform .22s cubic-bezier(.2,.9,.3,1), background .3s ease, border-color .3s ease;box-sizing:border-box;overflow:hidden;position:fixed;top:0;left:0;height:100vh;z-index:90}
.sidebar.collapsed{width:72px}
:is(.dark) .sidebar{background:#0f1729;border-right-color:#1e293b}
.brand-text{font-weight:700;color:#0f172a;transition:opacity .18s ease, transform .18s ease}
:is(.dark) .brand-text{color:#e2e8f0}
.brand-text[style*="display: none"]{opacity:0}
.label{font-weight:600;transition:opacity .18s ease, transform .18s ease}
.label[style*="display: none"]{opacity:0}
.brand{display:flex;align-items:center;gap:10px;padding:8px 6px}
.logo-btn{width:40px;height:40px;border-radius:10px;background:linear-gradient(135deg,#0ea5e9,#0284c7);color:white;display:flex;align-items:center;justify-content:center;border:none;padding:0;box-shadow:0 2px 8px rgba(14,165,233,.3)}
.logo-btn svg{display:block}
.brand-text{font-weight:700;color:#0f172a}
:is(.dark) .brand-text{color:#e2e8f0}
.nav-list{display:flex;flex-direction:column;margin-top:8px;gap:6px}
.nav-item{display:flex;align-items:center;gap:12px;padding:10px;border-radius:8px;color:#0f172a;text-decoration:none;transition:background .15s ease, color .15s ease}
:is(.dark) .nav-item{color:#cbd5e1}
.nav-item:hover{background:#f1f5f9}
:is(.dark) .nav-item:hover{background:#1e293b}
.nav-item.router-link-active{background:linear-gradient(135deg,#eff6ff,#dbeafe);color:#0284c7;font-weight:700;border-left:3px solid #0284c7}
:is(.dark) .nav-item.router-link-active{background:linear-gradient(135deg,#0c2d5b,#0e3a6e);color:#38bdf8;border-left-color:#38bdf8}
.icon{width:28px;height:28px;display:inline-flex;align-items:center;justify-content:center;font-size:16px}
.label{font-family:'Montserrat',sans-serif;font-weight:600}
.spacer{flex:1}
.controls{display:flex;flex-direction:column;gap:6px;align-items:stretch;padding:8px}
.collapse-btn{background:#fff;border:1px solid #e6eef2;padding:8px;border-radius:8px;cursor:pointer;display:flex;align-items:center;justify-content:center}
:is(.dark) .collapse-btn{background:#1e293b;border-color:#334155;color:#94a3b8}
:is(.dark) .collapse-btn:hover{background:#334155;border-color:#475569}
.theme-btn{display:flex;align-items:center;gap:10px;padding:10px;border-radius:8px;cursor:pointer;border:1px solid #e6eef2;background:#fff;color:#0f172a;font-family:'Montserrat',sans-serif;font-weight:600;font-size:14px;transition:background .15s ease, color .15s ease, border-color .15s ease}
.theme-btn:hover{background:#f1f5f9;border-color:#cbd5e1}
:is(.dark) .theme-btn{background:#1e293b;border-color:#334155;color:#cbd5e1}
:is(.dark) .theme-btn:hover{background:#334155;border-color:#475569}

.brand-row{display:flex;align-items:center;gap:8px}
.avatar{width:32px;height:32px;border-radius:999px;object-fit:cover}
.brand-name{font-family:'Josefin Sans',sans-serif;font-weight:700}
:is(.dark) .brand-name{color:#e2e8f0}
.menu-btn{background:transparent;border:none;cursor:pointer;padding:4px}
.menu-btn-collapsed{background:transparent;border:none;cursor:pointer;padding:4px;width:40px;height:40px;border-radius:999px;display:inline-flex;align-items:center;justify-content:center}
.quick-menu{position:fixed;left:88px;top:56px;background:#fff;border:1px solid #e6eef2;padding:8px;border-radius:8px;box-shadow:0 8px 24px rgba(2,6,23,0.12);z-index:200}
:is(.dark) .quick-menu{background:#1e293b;border-color:#334155;box-shadow:0 8px 24px rgba(0,0,0,0.4)}
.menu-item{display:block;padding:6px 8px;color:#0f172a;text-decoration:none;cursor:pointer}
:is(.dark) .menu-item{color:#cbd5e1}
.menu-item:hover{background:#f1f5f9}
:is(.dark) .menu-item:hover{background:#334155}

.nav-item .icon{transition:transform .18s ease}
.sidebar.collapsed .nav-item .icon{transform:none}
.sidebar .nav-item .label{white-space:nowrap}

/* Mobile close button — hidden by default */
.mobile-close-btn{
  display:none;
  position:absolute;top:12px;right:12px;
  background:transparent;border:none;padding:4px;
  color:#64748b;cursor:pointer;border-radius:6px;
  z-index:10;
}
.mobile-close-btn:hover{background:#f1f5f9;color:#0f172a}
:is(.dark) .mobile-close-btn{color:#94a3b8}
:is(.dark) .mobile-close-btn:hover{background:#334155;color:#e2e8f0}
.brand-collapsed{display:flex;align-items:center;justify-content:center}

/* Desktop-only elements */
.desktop-only{}

/* Responsive: overlay on mobile */
@media (max-width: 768px) {
  .sidebar {
    transform: translateX(-100%);
    width: 260px;
    box-shadow:none;
  }

  .sidebar.mobile-open {
    transform: translateX(0);
    box-shadow: 4px 0 24px rgba(0,0,0,.12);
  }

  .sidebar.collapsed {
    transform: translateX(-100%);
    width: 260px;
  }

  .sidebar.collapsed.mobile-open {
    transform: translateX(0);
    width: 260px;
  }

  /* On mobile, always show labels when sidebar is open */
  .sidebar.mobile-open .label{display:inline!important}
  .sidebar.mobile-open .brand-text{display:block!important}

  .mobile-close-btn{display:flex;align-items:center;justify-content:center}
  .desktop-only{display:none!important}
}
</style>
