import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'
import HomeView from '../components/HomeView.vue'
import PedidosView from '../components/PedidosView.vue'
import ClientsView from '../components/ClientsView.vue'
import ProductosView from '../components/ProductosView.vue'
import GastosView from '../components/GastosView.vue'
import CajaView from '../components/CajaView.vue'
import AdminUsersView from '../components/AdminUsersView.vue'
import ReporteProductosView from '../components/ReporteProductosView.vue'
import LoginView from '../components/LoginView.vue'
import LabelCanvas from '../components/LabelCanvas.vue'
import CotizadorView from '../components/CotizadorView.vue'
import QRGeneratorView from '../components/QRGeneratorView.vue'
import { getDefaultRouteForRole, useAuth } from '../composables/useAuth'
import type { AppRole } from '../types'

const adminOnly: AppRole[] = ['admin']
const adminAndEmployee: AppRole[] = ['admin', 'empleado']

const routes: RouteRecordRaw[] = [
  { path: '/', name: 'Home', component: HomeView, meta: { title: 'Inicio', allowedRoles: adminOnly } },
  { path: '/pedidos', name: 'Pedidos', component: PedidosView, meta: { title: 'Pedidos', allowedRoles: adminAndEmployee } },
  { path: '/usuarios', name: 'Usuarios', component: AdminUsersView, meta: { title: 'Usuarios', allowedRoles: adminOnly } },
  { path: '/clientes', name: 'Clientes', component: ClientsView, meta: { title: 'Clientes', allowedRoles: adminOnly } },
  { path: '/productos', name: 'Productos', component: ProductosView, meta: { title: 'Productos', allowedRoles: adminOnly } },
  { path: '/gastos', name: 'Gastos', component: GastosView, meta: { title: 'Gastos', allowedRoles: adminOnly } },
  { path: '/caja', name: 'Caja', component: CajaView, meta: { title: 'Caja', allowedRoles: adminOnly } },
  { path: '/reporte-productos', name: 'ReporteProductos', component: ReporteProductosView, meta: { title: 'Ventas Producto', allowedRoles: adminOnly } },
  { path: '/labels', name: 'Labels', component: LabelCanvas, meta: { title: 'Etiquetas', allowedRoles: adminOnly } },
  { path: '/cotizador', name: 'Cotizador', component: CotizadorView, meta: { title: 'Cotizador', allowedRoles: adminAndEmployee } },
  { path: '/qr', name: 'QRGenerator', component: QRGeneratorView, meta: { title: 'Generador QR', allowedRoles: adminAndEmployee } },
  { path: '/login', name: 'Login', component: LoginView, meta: { title: 'Iniciar sesión', public: true } }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach(async (to) => {
  const { initAuth, user, role } = useAuth()

  await initAuth()

  if (to.meta?.public) {
    if (!user.value) return true
    if (!role.value) return true
    return getDefaultRouteForRole(role.value)
  }

  if (!user.value) {
    return { name: 'Login' }
  }

  if (!role.value) {
    return { name: 'Login' }
  }

  const allowedRoles = (to.meta?.allowedRoles as AppRole[] | undefined) ?? adminAndEmployee
  if (!allowedRoles.includes(role.value)) {
    return getDefaultRouteForRole(role.value)
  }

  return true
})

export default router
