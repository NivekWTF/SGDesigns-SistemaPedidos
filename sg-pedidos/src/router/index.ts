import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '../components/HomeView.vue'
import PedidosView from '../components/PedidosView.vue'
import ClientsView from '../components/ClientsView.vue'
import ProductosView from '../components/ProductosView.vue'
import GastosView from '../components/GastosView.vue'
import ReporteProductosView from '../components/ReporteProductosView.vue'
import LoginView from '../components/LoginView.vue'
import LabelCanvas from '../components/LabelCanvas.vue'
import { supabase } from '../lib/supabase'

const routes = [
  { path: '/', name: 'Home', component: HomeView },
  { path: '/pedidos', name: 'Pedidos', component: PedidosView },
  { path: '/clientes', name: 'Clientes', component: ClientsView },
  { path: '/productos', name: 'Productos', component: ProductosView }
  ,{ path: '/gastos', name: 'Gastos', component: GastosView }
  ,{ path: '/reporte-productos', name: 'ReporteProductos', component: ReporteProductosView }
  ,{ path: '/labels', name: 'Labels', component: LabelCanvas }
  ,{ path: '/login', name: 'Login', component: LoginView }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

// Global auth guard: require login for all routes except /login
router.beforeEach(async (to) => {
  // allow login route always
  if (to.path === '/login') {
    // if already logged in, redirect to home
    try {
      const { data } = await supabase.auth.getSession()
      if (data.session) return { name: 'Home' }
    } catch (e) {
      /* ignore */
    }
    return true
  }

  // for other routes, require active session
  try {
    const { data } = await supabase.auth.getSession()
    if (!data.session) return { name: 'Login' }
  } catch (e) {
    return { name: 'Login' }
  }

  return true
})

export default router
