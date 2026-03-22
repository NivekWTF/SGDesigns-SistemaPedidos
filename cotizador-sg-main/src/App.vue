<script setup lang="ts">
import { provide } from 'vue'
import HeaderBox from './components/HeaderBox.vue'
import ClientBox from './components/ClientBox.vue'
import ItemsTable from './components/ItemsTable.vue'
import NotesTotals from './components/NotesTotals.vue'
import { useQuoteStore, STORE_KEY } from './composables/useQuoteStore'

const store = useQuoteStore()
provide(STORE_KEY, store)

// Usar el objeto global correctamente desde script:
const printPage = () => window.print()
</script>

<template>
  <div class="container">
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
</template>
