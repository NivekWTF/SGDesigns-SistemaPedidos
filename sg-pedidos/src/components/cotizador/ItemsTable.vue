<script setup lang="ts">
import { inject, ref } from 'vue'
import { STORE_KEY } from '../../composables/useQuoteStore'
import type { ItemRow, QuoteState } from '../../types/cotizador'
import type { Producto } from '../../types'
import ProductPicker from './ProductPicker.vue'


const store = inject<any>(STORE_KEY)!
const s = store.state as QuoteState

const showPicker = ref(false)
const pickerTargetIdx = ref<number | null>(null)

function openPicker(idx: number) {
    pickerTargetIdx.value = idx
    showPicker.value = true
}

function onProductSelected(product: Producto) {
    const idx = pickerTargetIdx.value
    if (idx !== null && s.items[idx]) {
        s.items[idx].description = product.nombre
        s.items[idx].unitPrice = product.precio_base
        if (!s.items[idx].qty || s.items[idx].qty <= 0) {
            s.items[idx].qty = 1
        }
    }
    showPicker.value = false
    pickerTargetIdx.value = null
}

function addItemFromPicker() {
    store.addItem()
    // Open picker for the newly added row
    const newIdx = s.items.length - 1
    openPicker(newIdx)
}

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
                        <div class="desc-cell">
                            <input v-model="row.description" type="text" placeholder="Producto o servicio" />
                            <button
                                class="btn-pick-product no-print"
                                type="button"
                                @click="openPicker(idx)"
                                title="Buscar producto del sistema"
                            >📦</button>
                        </div>
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
            <button class="btn-pick-add" @click="addItemFromPicker" type="button">📦 Agregar desde sistema</button>
            <button class="flat" @click="store.addItem">Añadir renglón</button>
            <button class="ghost" @click="store.clearItems">Limpiar tabla</button>
        </div>
    </section>

    <!-- Product Picker Modal -->
    <ProductPicker
        v-if="showPicker"
        @select="onProductSelected"
        @close="showPicker = false"
    />
</template>

<style scoped>
.desc-cell {
    display: flex;
    align-items: center;
    gap: 4px;
}
.desc-cell input {
    flex: 1;
}
.btn-pick-product {
    background: none;
    border: 1px solid #e0e0e0;
    border-radius: 6px;
    padding: 3px 7px;
    cursor: pointer;
    font-size: .85rem;
    transition: background .12s, border-color .12s;
    flex-shrink: 0;
    line-height: 1;
}
.btn-pick-product:hover {
    background: #f0f6ff;
    border-color: #1b4276;
}
.btn-pick-add {
    background: #1b4276;
    color: #fff;
    border: none;
    padding: 6px 14px;
    border-radius: 10px;
    cursor: pointer;
    font-size: .88rem;
    font-weight: 600;
    transition: background .15s;
}
.btn-pick-add:hover {
    background: #143560;
}

/* Dark mode */
:is(.dark) .btn-pick-product {
    border-color: #334155;
    color: #cbd5e1;
}
:is(.dark) .btn-pick-product:hover {
    background: #1e293b;
    border-color: #3b82f6;
}
:is(.dark) .btn-pick-add {
    background: #2563eb;
}
:is(.dark) .btn-pick-add:hover {
    background: #1d4ed8;
}
</style>
