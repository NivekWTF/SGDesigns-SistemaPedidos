<script setup lang="ts">
import { inject } from 'vue'
import { STORE_KEY } from '../composables/useQuoteStore'
import type { QuoteState } from '../types'
const { state } = inject<any>(STORE_KEY)!
</script>


<template>
    <section class="boxed" style="margin-bottom:16px">
        <div class="section-title">Datos del cliente</div>
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
</template>