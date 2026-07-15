<script setup lang="ts">
import { inject, ref } from 'vue'
import { STORE_KEY } from '../../composables/useQuoteStore'
import type { Cliente } from '../../types'
import ClientPicker from './ClientPicker.vue'

const { state } = inject<any>(STORE_KEY)!

const showPicker = ref(false)

function onClientSelected(client: Cliente) {
    state.client.name = client.nombre
    // If the client has additional info, we could populate address too
    // For now we just set the name
    showPicker.value = false
}
</script>


<template>
    <section class="boxed" style="margin-bottom:16px">
        <div class="cb-title-row">
            <div class="section-title">Datos del cliente</div>
            <button
                class="btn-pick-client no-print"
                type="button"
                @click="showPicker = true"
                title="Buscar cliente del sistema"
            >👤 Buscar cliente</button>
        </div>
        <div class="grid" style="grid-template-columns:1fr 2fr;gap:12px">
            <div>
                <div class="label">Cliente</div>
                <input v-model="state.client.name" type="text" placeholder="Nombre o razón social" />
            </div>
            <div>
                <div class="label">Dirección</div>
                <input v-model="state.client.address" type="text" placeholder="Calle, ciudad, estado" />
            </div>
        </div>
    </section>

    <!-- Client Picker Modal -->
    <ClientPicker
        v-if="showPicker"
        @select="onClientSelected"
        @close="showPicker = false"
    />
</template>

<style scoped>
.cb-title-row {
    display: flex;
    align-items: center;
    justify-content: space-between;
    margin-bottom: 8px;
}
.btn-pick-client {
    background: #1b4276;
    color: #fff;
    border: none;
    padding: 5px 14px;
    border-radius: 8px;
    cursor: pointer;
    font-size: .85rem;
    font-weight: 600;
    transition: background .15s;
}
.btn-pick-client:hover {
    background: #143560;
}

/* Dark mode */
:is(.dark) .btn-pick-client {
    background: #2563eb;
}
:is(.dark) .btn-pick-client:hover {
    background: #1d4ed8;
}
</style>
