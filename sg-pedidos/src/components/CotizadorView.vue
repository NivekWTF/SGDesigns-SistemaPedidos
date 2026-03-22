<script setup lang="ts">
import { provide } from 'vue'
import HeaderBox from './cotizador/HeaderBox.vue'
import ClientBox from './cotizador/ClientBox.vue'
import ItemsTable from './cotizador/ItemsTable.vue'
import NotesTotals from './cotizador/NotesTotals.vue'
import { useQuoteStore, STORE_KEY } from '../composables/useQuoteStore'

const store = useQuoteStore()
provide(STORE_KEY, store)

const printPage = () => window.print()
</script>

<template>
  <div class="cotizador-page">
    <div class="cot-container">
      <div class="sheet" id="quote-page">
        <HeaderBox />
        <ClientBox />
        <ItemsTable />
        <NotesTotals />
      </div>

      <div class="toolbar no-print" style="margin-top:16px">
        <button @click="store.saveDraft">Guardar (LocalStorage)</button>
        <button class="ghost" @click="store.loadDraft">Cargar</button>
        <button class="flat" @click="store.exportJSON">Exportar JSON</button>

        <label
          class="flat"
          style="display:inline-flex;align-items:center;gap:8px;padding:8px 12px;border-radius:10px;border:1px solid var(--brand);background:#fff;color:var(--brand);cursor:pointer"
        >
          Importar JSON
          <input
            type="file"
            accept="application/json"
            style="display:none"
            @change="store.importJSON($event)"
          />
        </label>

        <button class="flat" @click="store.makePDFText">Generar PDF (texto)</button>
        <button class="ghost" @click="printPage">Imprimir</button>
        <button class="flat" @click="store.resetAll">Nuevo</button>
      </div>
    </div>
  </div>
</template>
