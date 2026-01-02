import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '../components/HomeView.vue'
import PedidosView from '../components/PedidosView.vue'
import ClientsView from '../components/ClientsView.vue'
import ProductosView from '../components/ProductosView.vue'

const routes = [
  { path: '/', name: 'Home', component: HomeView },
  { path: '/pedidos', name: 'Pedidos', component: PedidosView },
  { path: '/clientes', name: 'Clientes', component: ClientsView },
  { path: '/productos', name: 'Productos', component: ProductosView }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
