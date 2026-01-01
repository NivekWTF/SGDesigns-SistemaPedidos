<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { supabase } from '../lib/supabase'

const clientes = ref<any[]>([])
const loading = ref(true)
const errorMsg = ref('')

onMounted(async () => {
  try {
    const { data, error } = await supabase
      .from('clientes')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) throw error
    clientes.value = data ?? []
  } catch (err: any) {
    errorMsg.value = err.message ?? 'Error al cargar clientes'
  } finally {
    loading.value = false
  }
})
</script>

<template>
  <div>
    <h1>SG Pedidos - Prueba Supabase</h1>

    <p v-if="loading">Cargando clientes...</p>
    <p v-else-if="errorMsg">⚠️ {{ errorMsg }}</p>

    <ul v-else>
      <li v-for="c in clientes" :key="c.id">
        {{ c.nombre }} - {{ c.telefono || 'Sin teléfono' }}
      </li>
    </ul>
  </div>
</template>
