<template>
  <aside
    :class="sidebarClasses"
    @mouseenter="onMouseEnter"
    @mouseleave="onMouseLeave"
  >
    <!-- Close button for mobile overlay -->
    <button class="mobile-close-btn" @click="$emit('close-mobile')" aria-label="Cerrar menú">
      <X class="h-5 w-5" />
    </button>

    <!-- Brand / Logo -->
    <div class="brand">
      <button class="logo-btn" @click.stop="toggleMenu" :title="user ? displayName : 'SpaFlow'">
        <svg width="22" height="22" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" aria-hidden>
          <!-- Lotus flower icon -->
          <path d="M12 3C10 7 6 9 4 9c0 4 4 8 8 8s8-4 8-8c-2 0-6-2-8-6z" stroke="currentColor" stroke-width="1.4" stroke-linejoin="round" fill="none"/>
          <path d="M12 17v3" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/>
          <path d="M9 20h6" stroke="currentColor" stroke-width="1.4" stroke-linecap="round"/>
        </svg>
      </button>

      <div v-show="!effectiveCollapsed || mobileOpen" class="brand-text">
        <template v-if="user">
          <div class="brand-row">
            <img v-if="user.user_metadata?.avatar_url" :src="user.user_metadata.avatar_url" alt="avatar" class="avatar" />
            <div>
              <div class="brand-name">{{ displayName }}</div>
              <div v-if="role" class="role-badge" :class="`role-${role}`">{{ roleLabel }}</div>
            </div>
          </div>
          <div v-if="menuOpen" class="quick-menu" @click.stop>
            <div class="menu-meta">{{ roleLabel }}</div>
            <a class="menu-item" @click="handleSignOut">Cerrar sesión</a>
          </div>
        </template>
        <template v-else>
          <span class="brand-app-name">SpaFlow</span>
        </template>
      </div>

      <div v-if="effectiveCollapsed && !mobileOpen" class="brand-collapsed">
        <button class="menu-btn-collapsed" @click.stop="toggleMenu">
          <img v-if="user?.user_metadata?.avatar_url" :src="user.user_metadata.avatar_url" class="avatar" />
          <Flower2 v-else class="h-4 w-4" />
        </button>
      </div>
    </div>

    <!-- SuperAdmin Nav -->
    <nav v-if="isSuperAdmin" class="nav-list">
      <div v-show="!effectiveCollapsed || mobileOpen" class="nav-section-label">SuperAdmin</div>
      <router-link to="/superadmin" class="nav-item" :title="effectiveCollapsed && !mobileOpen ? 'Panel Admin' : ''" @click="closeMobile">
        <span class="icon"><ShieldCheck class="h-[18px] w-[18px]" /></span>
        <span v-show="!effectiveCollapsed || mobileOpen" class="label">Panel Admin</span>
      </router-link>
    </nav>

    <!-- Spa Nav -->
    <nav v-else class="nav-list">
      <!-- Dashboard (admin + recepcionista) -->
      <router-link v-if="!isTerapeuta" to="/" class="nav-item" :title="effectiveCollapsed && !mobileOpen ? 'Dashboard' : ''" @click="closeMobile">
        <span class="icon"><LayoutDashboard class="h-[18px] w-[18px]" /></span>
        <span v-show="!effectiveCollapsed || mobileOpen" class="label">Dashboard</span>
      </router-link>

      <!-- Agenda / Citas (todos) -->
      <router-link to="/citas" class="nav-item" :title="effectiveCollapsed && !mobileOpen ? 'Agenda' : ''" @click="closeMobile">
        <span class="icon"><CalendarDays class="h-[18px] w-[18px]" /></span>
        <span v-show="!effectiveCollapsed || mobileOpen" class="label">Agenda</span>
      </router-link>

      <!-- Clientes (admin + recepcionista) -->
      <router-link v-if="!isTerapeuta" to="/clientes" class="nav-item" :title="effectiveCollapsed && !mobileOpen ? 'Clientes' : ''" @click="closeMobile">
        <span class="icon"><Users class="h-[18px] w-[18px]" /></span>
        <span v-show="!effectiveCollapsed || mobileOpen" class="label">Clientes</span>
      </router-link>

      <!-- Sección Admin Spa -->
      <template v-if="isAdminSpa">
        <div v-show="!effectiveCollapsed || mobileOpen" class="nav-section-label">Catálogos</div>

        <router-link to="/servicios" class="nav-item" :title="effectiveCollapsed && !mobileOpen ? 'Servicios' : ''" @click="closeMobile">
          <span class="icon"><Sparkles class="h-[18px] w-[18px]" /></span>
          <span v-show="!effectiveCollapsed || mobileOpen" class="label">Servicios</span>
        </router-link>

        <router-link to="/productos" class="nav-item" :title="effectiveCollapsed && !mobileOpen ? 'Productos' : ''" @click="closeMobile">
          <span class="icon"><ShoppingBag class="h-[18px] w-[18px]" /></span>
          <span v-show="!effectiveCollapsed || mobileOpen" class="label">Productos</span>
        </router-link>

        <router-link to="/paquetes" class="nav-item" :title="effectiveCollapsed && !mobileOpen ? 'Paquetes' : ''" @click="closeMobile">
          <span class="icon"><Gift class="h-[18px] w-[18px]" /></span>
          <span v-show="!effectiveCollapsed || mobileOpen" class="label">Paquetes</span>
        </router-link>

        <router-link to="/personal" class="nav-item" :title="effectiveCollapsed && !mobileOpen ? 'Personal' : ''" @click="closeMobile">
          <span class="icon"><UserCheck class="h-[18px] w-[18px]" /></span>
          <span v-show="!effectiveCollapsed || mobileOpen" class="label">Personal</span>
        </router-link>

        <div v-show="!effectiveCollapsed || mobileOpen" class="nav-section-label">Finanzas</div>

        <router-link to="/caja" class="nav-item" :title="effectiveCollapsed && !mobileOpen ? 'Caja' : ''" @click="closeMobile">
          <span class="icon"><Banknote class="h-[18px] w-[18px]" /></span>
          <span v-show="!effectiveCollapsed || mobileOpen" class="label">Caja</span>
        </router-link>

        <router-link to="/gastos" class="nav-item" :title="effectiveCollapsed && !mobileOpen ? 'Gastos' : ''" @click="closeMobile">
          <span class="icon"><Wallet class="h-[18px] w-[18px]" /></span>
          <span v-show="!effectiveCollapsed || mobileOpen" class="label">Gastos</span>
        </router-link>

        <div v-show="!effectiveCollapsed || mobileOpen" class="nav-section-label">Ajustes</div>

        <router-link to="/usuarios" class="nav-item" :title="effectiveCollapsed && !mobileOpen ? 'Usuarios' : ''" @click="closeMobile">
          <span class="icon"><Shield class="h-[18px] w-[18px]" /></span>
          <span v-show="!effectiveCollapsed || mobileOpen" class="label">Usuarios</span>
        </router-link>

        <router-link to="/config" class="nav-item" :title="effectiveCollapsed && !mobileOpen ? 'Configuración' : ''" @click="closeMobile">
          <span class="icon"><Settings class="h-[18px] w-[18px]" /></span>
          <span v-show="!effectiveCollapsed || mobileOpen" class="label">Configuración</span>
        </router-link>
      </template>

      <!-- Caja visible para recepcionista también -->
      <template v-if="isRecepcionista">
        <div v-show="!effectiveCollapsed || mobileOpen" class="nav-section-label">Finanzas</div>
        <router-link to="/caja" class="nav-item" :title="effectiveCollapsed && !mobileOpen ? 'Caja' : ''" @click="closeMobile">
          <span class="icon"><Banknote class="h-[18px] w-[18px]" /></span>
          <span v-show="!effectiveCollapsed || mobileOpen" class="label">Caja</span>
        </router-link>
      </template>
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
import {
  LayoutDashboard, CalendarDays, Users, Sparkles, ShoppingBag,
  Gift, UserCheck, Banknote, Wallet, Shield, Settings,
  ShieldCheck, Flower2,
  ChevronLeft, ChevronRight, X, Sun, Moon
} from 'lucide-vue-next'
import { useRouter } from 'vue-router'

const props = defineProps<{
  mobileOpen?: boolean
}>()

const emit = defineEmits<{
  (e: 'close-mobile'): void
}>()

const router = useRouter()
const { user, profile, role, isAdmin, isAdminSpa, isRecepcionista, isTerapeuta, isSuperAdmin, signOut } = useAuth()

const STORAGE_KEY = 'sidebar-collapsed'
const collapsed = ref<boolean>(localStorage.getItem(STORAGE_KEY) === '1')
const hovered = ref(false)
const menuOpen = ref(false)
const preventHoverExpand = ref(false)

const effectiveCollapsed = computed(() => collapsed.value && !hovered.value)

const sidebarClasses = computed(() => {
  const classes = ['sidebar']
  if (effectiveCollapsed.value) classes.push('collapsed')
  if (props.mobileOpen) classes.push('mobile-open')
  return classes
})

const displayName = computed(() =>
  profile.value?.full_name
  || user.value?.user_metadata?.full_name
  || user.value?.user_metadata?.name
  || user.value?.email
  || 'Usuario'
)

const roleLabel = computed(() => {
  switch (role.value) {
    case 'superadmin':    return 'Super Admin'
    case 'admin_spa':     return 'Admin'
    case 'recepcionista': return 'Recepcionista'
    case 'terapeuta':     return 'Terapeuta'
    default:              return 'Sin rol'
  }
})

function toggle() {
  collapsed.value = !collapsed.value
  localStorage.setItem(STORAGE_KEY, collapsed.value ? '1' : '0')
  try { window.dispatchEvent(new CustomEvent('sidebar-toggle', { detail: { collapsed: collapsed.value } })) } catch(e) {}
}

function closeMobile() { emit('close-mobile') }

function onMouseEnter() {
  if (collapsed.value && !preventHoverExpand.value) hovered.value = true
}

function onMouseLeave() {
  if (collapsed.value) hovered.value = false
}

async function handleSignOut() {
  menuOpen.value = false
  emit('close-mobile')
  await signOut()
  router.push('/login')
}

function toggleMenu() {
  menuOpen.value = !menuOpen.value
  preventHoverExpand.value = menuOpen.value
  if (preventHoverExpand.value) {
    setTimeout(() => { preventHoverExpand.value = false }, 1000)
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

applyTheme()
</script>

<style scoped>
/* ── Base Sidebar ── */
.sidebar {
  width: 230px;
  background: var(--sidebar);
  border-right: 1px solid var(--sidebar-border);
  display: flex;
  flex-direction: column;
  padding: 12px 8px;
  transition: width .22s cubic-bezier(.2,.9,.3,1), transform .22s cubic-bezier(.2,.9,.3,1), background .3s ease;
  box-sizing: border-box;
  overflow: hidden;
  position: fixed;
  top: 0; left: 0;
  height: 100vh;
  z-index: 90;
}
.sidebar.collapsed { width: 72px; }

/* ── Brand ── */
.brand { display: flex; align-items: center; gap: 10px; padding: 8px 6px 12px; border-bottom: 1px solid var(--sidebar-border); margin-bottom: 8px; }
.logo-btn {
  width: 40px; height: 40px; border-radius: 12px; flex-shrink: 0;
  background: linear-gradient(135deg, var(--primary), #6d28d9);
  color: white;
  display: flex; align-items: center; justify-content: center;
  border: none; padding: 0;
  box-shadow: 0 2px 8px rgba(139, 92, 246, 0.35);
  transition: box-shadow .2s ease;
}
.logo-btn:hover { box-shadow: 0 4px 14px rgba(139, 92, 246, 0.5); }
.brand-app-name { font-family: 'Playfair Display', Georgia, serif; font-weight: 700; font-size: 18px; color: var(--sidebar-foreground); letter-spacing: 0.01em; }
.brand-text { flex: 1; min-width: 0; }
.brand-row { display: flex; align-items: center; gap: 8px; }
.avatar { width: 32px; height: 32px; border-radius: 999px; object-fit: cover; border: 2px solid var(--sidebar-border); }
.brand-name { font-weight: 700; font-size: 13px; color: var(--sidebar-foreground); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 140px; }
.brand-collapsed { display: flex; align-items: center; justify-content: center; }
.menu-btn-collapsed { background: transparent; border: none; cursor: pointer; padding: 4px; width: 40px; height: 40px; border-radius: 999px; display: inline-flex; align-items: center; justify-content: center; color: var(--sidebar-foreground); }

/* ── Role Badge ── */
.role-badge {
  display: inline-flex; align-items: center; margin-top: 3px;
  padding: 2px 8px; border-radius: 999px;
  font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: .06em;
  background: var(--sidebar-accent); color: var(--sidebar-accent-foreground);
}
.role-badge.role-superadmin { background: #4c1d95; color: #e9d5ff; }
.role-badge.role-admin_spa  { background: var(--sidebar-accent); color: var(--sidebar-accent-foreground); }
.role-badge.role-recepcionista { background: #ecfdf5; color: #047857; }
.role-badge.role-terapeuta  { background: #fdf4ff; color: #7e22ce; }

:is(.dark) .role-badge.role-recepcionista { background: #064e3b; color: #6ee7b7; }
:is(.dark) .role-badge.role-terapeuta     { background: #2d1f4a; color: #c4b5fd; }

/* ── Nav Section Labels ── */
.nav-section-label {
  font-size: 10px; font-weight: 700; text-transform: uppercase; letter-spacing: .08em;
  color: var(--muted-foreground); padding: 10px 10px 4px;
  white-space: nowrap;
}

/* ── Nav ── */
.nav-list { display: flex; flex-direction: column; gap: 2px; }
.nav-item {
  display: flex; align-items: center; gap: 12px;
  padding: 9px 10px; border-radius: 10px;
  color: var(--sidebar-foreground); text-decoration: none;
  font-size: 14px;
  transition: background .15s ease, color .15s ease;
}
.nav-item:hover { background: var(--sidebar-accent); color: var(--sidebar-accent-foreground); }
.nav-item.router-link-active {
  background: linear-gradient(135deg, #f3eeff, #ede9fd);
  color: var(--primary);
  font-weight: 700;
  border-left: 3px solid var(--primary);
}
:is(.dark) .nav-item.router-link-active {
  background: linear-gradient(135deg, #2d1f4a, #1f1535);
  color: #a78bfa;
  border-left-color: #a78bfa;
}
.icon { width: 28px; height: 28px; display: inline-flex; align-items: center; justify-content: center; flex-shrink: 0; }
.label { font-weight: 600; white-space: nowrap; font-family: 'Inter', sans-serif; }

/* ── Quick Menu ── */
.quick-menu {
  position: fixed; left: 88px; top: 56px;
  background: var(--card); border: 1px solid var(--border);
  padding: 8px; border-radius: 10px;
  box-shadow: 0 8px 24px rgba(45, 34, 53, 0.14);
  z-index: 200; min-width: 160px;
}
.menu-meta { padding: 6px 8px; color: var(--muted-foreground); font-size: 11px; font-weight: 700; text-transform: uppercase; letter-spacing: .04em; }
.menu-item { display: block; padding: 8px 10px; color: var(--foreground); text-decoration: none; cursor: pointer; border-radius: 6px; font-size: 14px; transition: background .12s; }
.menu-item:hover { background: var(--muted); }

/* ── Controls ── */
.spacer { flex: 1; }
.controls { display: flex; flex-direction: column; gap: 6px; align-items: stretch; padding: 8px; border-top: 1px solid var(--sidebar-border); margin-top: 8px; }
.collapse-btn {
  background: var(--card); border: 1px solid var(--border);
  padding: 8px; border-radius: 8px; cursor: pointer;
  display: flex; align-items: center; justify-content: center;
  color: var(--foreground);
  transition: background .15s;
}
.collapse-btn:hover { background: var(--muted); }
.theme-btn {
  display: flex; align-items: center; gap: 10px; padding: 9px 10px;
  border-radius: 8px; cursor: pointer; border: 1px solid var(--border);
  background: var(--card); color: var(--foreground);
  font-family: 'Inter', sans-serif; font-weight: 600; font-size: 14px;
  transition: background .15s, border-color .15s;
}
.theme-btn:hover { background: var(--muted); }

/* ── Mobile close ── */
.mobile-close-btn {
  display: none;
  position: absolute; top: 12px; right: 12px;
  background: transparent; border: none; padding: 4px;
  color: var(--muted-foreground); cursor: pointer; border-radius: 6px; z-index: 10;
}
.mobile-close-btn:hover { background: var(--muted); }

.desktop-only {}

/* ── Responsive ── */
@media (max-width: 768px) {
  .sidebar { transform: translateX(-100%); width: 260px; box-shadow: none; }
  .sidebar.mobile-open { transform: translateX(0); box-shadow: 4px 0 24px rgba(45,34,53,.2); }
  .sidebar.collapsed { transform: translateX(-100%); width: 260px; }
  .sidebar.collapsed.mobile-open { transform: translateX(0); width: 260px; }
  .sidebar.mobile-open .label { display: inline !important; }
  .sidebar.mobile-open .brand-text { display: block !important; }
  .mobile-close-btn { display: flex; align-items: center; justify-content: center; }
  .desktop-only { display: none !important; }
}
</style>
