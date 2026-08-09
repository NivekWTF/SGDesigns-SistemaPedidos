import { createApp } from 'vue'
import './style.css'
import App from './App.vue'
import router from './router'
import { useBusinessConfig } from './composables/useBusinessConfig'

// Load business config (brand colors, name, etc.) early
const { loadConfig } = useBusinessConfig()
void loadConfig()

createApp(App).use(router).mount('#app')
