<script setup lang="ts">
import { inject } from 'vue'
import { STORE_KEY } from '../../composables/useQuoteStore'
import type { ItemRow, QuoteState } from '../../types/cotizador'


const store = inject<any>(STORE_KEY)!
const s = store.state as QuoteState


function rowSubtotal(row: ItemRow) {
    return Number(row.qty || 0) * Number(row.unitPrice || 0)
}
function rowIVA(row: ItemRow) {
    return row.applyTax ? rowSubtotal(row) * s.config.taxRate : 0
}
</script>


<template>
    <section class="boxed" style="margin-bottom:16px">
        <div class="section-title">Conceptos</div>
        <div class="muted" style="font-size:12px;margin-bottom:8px">IVA configurable en totales. Puedes
            activar/desactivar IVA por renglón.</div>


        <table>
            <thead>
                <tr>
                    <th style="width:80px">CANTIDAD</th>
                    <th>DESCRIPCIÓN</th>
                    <th style="width:140px">P. UNITARIO</th>
                    <th style="width:120px">IVA</th>
                    <th style="width:140px">IMPORTE</th>
                </tr>
            </thead>
            <tbody>
                <tr v-for="(row, idx) in s.items" :key="idx">
                    <td class="center">
                        <input v-model.number="row.qty" type="number" min="0" step="1"
                            style="text-align:center;width:100%">
                    </td>
                    <td>
                        <input v-model="row.description" type="text" placeholder="Producto o servicio" />
                    </td>
                    <td class="num">
                        <input v-model.number="row.unitPrice" type="number" min="0" step="0.01"
                            style="text-align:right;width:100%">
                    </td>
                    <td class="center">
                        <label style="display:flex;align-items:center;justify-content:center;gap:6px">
                            <input type="checkbox" v-model="row.applyTax"> <span>{{ row.applyTax ?
                                store.currency(rowIVA(row)) : 'N/A' }}</span>
                        </label>
                    </td>
                    <td class="num">{{ store.currency(rowSubtotal(row) + rowIVA(row)) }}</td>
                </tr>
            </tbody>
        </table>


        <div class="row no-print" style="margin-top:10px;justify-content:flex-end;gap:8px">
            <button class="flat" @click="store.addItem">Añadir renglón</button>
            <button class="ghost" @click="store.clearItems">Limpiar tabla</button>
        </div>
    </section>
</template>
