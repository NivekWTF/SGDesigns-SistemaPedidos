import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'

// ── Vistas existentes conservadas ──────────────────────────────────────────
import LoginView     from '../components/LoginView.vue'
import CajaView      from '../components/CajaView.vue'
import GastosView    from '../components/GastosView.vue'
import ClientsView   from '../components/ClientsView.vue'
import ProductosView from '../components/ProductosView.vue'
import AdminUsersView from '../components/AdminUsersView.vue'

// ── Vistas nuevas del spa (placeholders por ahora) ─────────────────────────
import DashboardView    from '../components/DashboardView.vue'
import CitasView        from '../components/CitasView.vue'
import ServiciosView    from '../components/ServiciosView.vue'
import PersonalView     from '../components/PersonalView.vue'
import PaquetesView     from '../components/PaquetesView.vue'
import ConfigSpaView    from '../components/ConfigSpaView.vue'
import SuperAdminView   from '../components/SuperAdminView.vue'

import { getDefaultRouteForRole, useAuth } from '../composables/useAuth'
import type { AppRole } from '../types'

// ── Role shorthands ────────────────────────────────────────────────────────
const SUPER:       AppRole[] = ['superadmin']
const ADMIN_SPA:   AppRole[] = ['admin_spa']
const STAFF:       AppRole[] = ['admin_spa', 'recepcionista']
const ALL_TENANT:  AppRole[] = ['admin_spa', 'recepcionista', 'terapeuta']

const routes: RouteRecordRaw[] = [
  // ── SuperAdmin (solo dueño del SaaS) ────────────────────────────────────
  {
    path: '/superadmin',
    name: 'SuperAdmin',
    component: SuperAdminView,
    meta: { title: 'Super Admin', allowedRoles: SUPER },
  },

  // ── Vistas del spa ───────────────────────────────────────────────────────
  {
    path: '/',
    name: 'Dashboard',
    component: DashboardView,
    meta: { title: 'Dashboard', allowedRoles: STAFF },
  },
  {
    path: '/citas',
    name: 'Citas',
    component: CitasView,
    meta: { title: 'Agenda', allowedRoles: ALL_TENANT },
  },
  {
    path: '/clientes',
    name: 'Clientes',
    component: ClientsView,
    meta: { title: 'Clientes', allowedRoles: STAFF },
  },
  {
    path: '/servicios',
    name: 'Servicios',
    component: ServiciosView,
    meta: { title: 'Servicios', allowedRoles: ADMIN_SPA },
  },
  {
    path: '/productos',
    name: 'Productos',
    component: ProductosView,
    meta: { title: 'Productos', allowedRoles: ADMIN_SPA },
  },
  {
    path: '/personal',
    name: 'Personal',
    component: PersonalView,
    meta: { title: 'Personal', allowedRoles: ADMIN_SPA },
  },
  {
    path: '/paquetes',
    name: 'Paquetes',
    component: PaquetesView,
    meta: { title: 'Paquetes', allowedRoles: ADMIN_SPA },
  },
  {
    path: '/caja',
    name: 'Caja',
    component: CajaView,
    meta: { title: 'Caja', allowedRoles: STAFF },
  },
  {
    path: '/gastos',
    name: 'Gastos',
    component: GastosView,
    meta: { title: 'Gastos', allowedRoles: ADMIN_SPA },
  },
  {
    path: '/usuarios',
    name: 'Usuarios',
    component: AdminUsersView,
    meta: { title: 'Usuarios', allowedRoles: ADMIN_SPA },
  },
  {
    path: '/config',
    name: 'Config',
    component: ConfigSpaView,
    meta: { title: 'Configuración', allowedRoles: ADMIN_SPA },
  },

  // ── Login ────────────────────────────────────────────────────────────────
  {
    path: '/login',
    name: 'Login',
    component: LoginView,
    meta: { title: 'Iniciar sesión', public: true },
  },

  // ── Catch-all ────────────────────────────────────────────────────────────
  {
    path: '/:pathMatch(.*)*',
    redirect: '/',
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach(async (to) => {
  const { initAuth, user, role } = useAuth()

  await initAuth()

  if (to.meta?.public) {
    if (!user.value) return true
    if (!role.value) return true
    return getDefaultRouteForRole(role.value)
  }

  if (!user.value) return { name: 'Login' }
  if (!role.value) return { name: 'Login' }

  const allowedRoles = (to.meta?.allowedRoles as AppRole[] | undefined) ?? ALL_TENANT
  if (!allowedRoles.includes(role.value)) {
    return getDefaultRouteForRole(role.value)
  }

  return true
})

export default router
