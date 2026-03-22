<script setup lang="ts">
import { inject, ref } from 'vue'
import { STORE_KEY } from '../../composables/useQuoteStore'
import type { QuoteState } from '../../types/cotizador'


const store = inject<any>(STORE_KEY)!
const s = store.state as QuoteState


const fileInput = ref<HTMLInputElement | null>(null)


function onLogoPick() { fileInput.value?.click() }
function onFile(e: Event) {
    const input = e.target as HTMLInputElement
    const f = input.files?.[0]; if (!f) return
    const reader = new FileReader()
    reader.onload = ev => { s.header.logoDataUrl = String((ev.target as FileReader).result) }
    reader.readAsDataURL(f)
    input.value = ''
}
</script>


<template>
    <section class="grid" style="margin-bottom:16px">
        <div class="quote-head">
            <div>
                <div class="brand-block">
                    <div class="brand-logo" @click="onLogoPick" title="Subir logo (click)">
                        <img v-if="s.header.logoDataUrl" :src="s.header.logoDataUrl" alt="logo" />
                        <span v-else class="muted" style="font-size:12px">Logo</span>
                        <input ref="fileInput" class="no-print" type="file" accept="image/*" @change="onFile"
                            style="display:none" />
                    </div>
                    <div>
                        <div class="title big">{{ s.header.company.name }}</div>
                        <div class="muted" style="font-size:13px;white-space:pre-line">
                            {{ s.header.company.name }} · RFC: {{ s.header.company.rfc }}
                        </div>
                        <div class="muted" style="font-size:13px">
                            {{ s.header.company.email }} · Tel: {{ s.header.company.phone }}
                        </div>
                        <div class="muted" style="font-size:13px;white-space:pre-line">
                            {{ s.header.company.address }}
                        </div>
                    </div>
                </div>
            </div>
            <div style="text-align:right">
                <div class="title" style="font-size:34px">COTIZACIÓN</div>
                <div class="folio-box" style="margin-top:6px">
                    FOLIO<br>
                    <span style="font-size:18px">{{ s.header.folio }}</span>
                </div>
            </div>
        </div>


        <div class="boxed grid" style="grid-template-columns:1fr 1fr 1fr;align-items:end">
            <div>
                <div class="label">Serie</div>
                <input v-model="s.header.series" type="text" placeholder="Serie (p. ej. RC)" />
            </div>
            <div>
                <div class="label">Fecha</div>
                <input v-model="s.header.date" type="date" />
            </div>
            <div class="row" style="justify-content:flex-end;gap:8px">
                <button class="flat" @click="store.generateFolio">Generar folio</button>
            </div>


            <div style="grid-column:1 / -1" class="row">
                <div class="label" style="width:110px">Nombre empresa</div>
                <input v-model="s.header.company.name" type="text" />
            </div>
            <div class="row">
                <div class="label" style="width:110px">RFC</div>
                <input v-model="s.header.company.rfc" type="text" />
            </div>
            <div class="row">
                <div class="label" style="width:110px">Email</div>
                <input v-model="s.header.company.email" type="text" />
            </div>
            <div class="row">
                <div class="label" style="width:110px">Teléfono</div>
                <input v-model="s.header.company.phone" type="text" />
            </div>
            <div style="grid-column:1 / -1">
        <div class="label">Dirección</div>
        <textarea
          v-model="s.header.company.address"
          rows="2"
          placeholder="Calle y número, Colonia, Ciudad, Estado"
        />
      </div>
        </div>
    </section>
</template>
