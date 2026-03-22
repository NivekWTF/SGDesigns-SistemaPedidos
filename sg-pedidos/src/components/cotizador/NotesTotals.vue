<script setup lang="ts">
import { inject } from 'vue'
import { STORE_KEY } from '../../composables/useQuoteStore'
import type { QuoteState } from '../../types/cotizador'


const store = inject<any>(STORE_KEY)!
const s = store.state as QuoteState
</script>


<template>
    <section class="grid" style="grid-template-columns:1fr 320px;gap:16px">
        <div class="boxed">
            <div class="section-title">Notas / Observaciones</div>
            <textarea v-model="s.notes" placeholder="Condiciones, tiempos, vigencia, garantía, etc."></textarea>
        </div>


        <div class="boxed">
            <div class="section-title">Totales</div>
            <div class="row" style="justify-content:flex-end;margin-bottom:8px">
                <span class="label">IVA (%)</span>
                <input v-model.number="s.config.taxRate" type="number" step="0.01" min="0" max="1"
                    style="width:90px;text-align:right" />
            </div>
            <table>
                <tbody>
                    <tr>
                        <td>SUBTOTAL</td>
                        <td class="num">{{ store.currency(store.subtotal) }}</td>
                    </tr>
                    <tr>
                        <td>IVA</td>
                        <td class="num">{{ store.currency(store.ivaTotal) }}</td>
                    </tr>
                    <tr>
                        <th>TOTAL</th>
                        <th class="num">{{ store.currency(store.grandTotal) }}</th>
                    </tr>
                </tbody>
            </table>
        </div>
        <div style="margin-top:8px;font-size:13px;color:#555;font-weight:600">
            TOTAL EN LETRAS: {{ store.numeroALetras(Math.round(store.grandTotal)) }} PESOS MEXICANOS
        </div>

    </section>
</template>
