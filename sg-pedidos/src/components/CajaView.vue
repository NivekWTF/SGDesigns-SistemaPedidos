<template>
  <div class="max-w-[1200px] space-y-6 px-4 py-6 font-body">
    <header>
      <h1 class="font-display text-3xl font-bold tracking-tight text-slate-900 dark:text-slate-100">Caja</h1>
      <p class="mt-1 text-sm text-slate-500 dark:text-slate-400">
        Control de efectivo, movimientos y gastos del negocio.
      </p>
    </header>

    <section class="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-[#111c2e]">
      <div class="flex flex-wrap items-end gap-4">
        <div class="flex flex-1 min-w-[200px] flex-col gap-1.5">
          <label class="text-xs font-semibold uppercase tracking-widest text-slate-400">Monto inicial</label>
          <input
            v-model.number="aperturaSaldo"
            type="number"
            min="0"
            step="0.01"
            class="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 dark:border-slate-700 dark:bg-[#0f1729] dark:text-slate-100"
            placeholder="0.00"
          />
        </div>
        <button
          class="rounded-lg bg-emerald-500 px-4 py-2 text-sm font-semibold text-white hover:bg-emerald-600"
          :disabled="aperturaWorking"
          @click="abrirCajaNueva"
        >
          Abrir caja
        </button>
      </div>
      <div class="mt-2 text-xs text-slate-400">
        {{ cajaActiva ? 'Abrir una nueva caja cerrara la caja actual.' : 'No hay caja abierta.' }}
      </div>
      <div v-if="aperturaError" class="mt-2 text-xs text-rose-500">{{ aperturaError }}</div>
    </section>

    <section class="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
      <div class="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-[#111c2e]">
        <div class="text-xs font-semibold uppercase tracking-widest text-slate-400">Saldo inicial</div>
        <div class="mt-2 text-2xl font-black text-slate-900 dark:text-white">{{ formatCurrency(saldoInicial) }}</div>
        <div class="mt-2 text-xs text-slate-400">Caja activa: {{ cajaActiva?.nombre || 'Caja principal' }}</div>
      </div>
      <div class="rounded-2xl border border-emerald-100 bg-emerald-50/60 p-5 shadow-sm dark:border-emerald-900/40 dark:bg-emerald-950/20">
        <div class="text-xs font-semibold uppercase tracking-widest text-emerald-600 dark:text-emerald-300">Entradas efectivo</div>
        <div class="mt-2 text-2xl font-black text-emerald-700 dark:text-emerald-300">{{ formatCurrency(entradasEfectivo) }}</div>
        <div class="mt-2 text-xs text-emerald-700/70 dark:text-emerald-300/70">Solo metodo EFECTIVO</div>
      </div>
      <div class="rounded-2xl border border-rose-100 bg-rose-50/60 p-5 shadow-sm dark:border-rose-900/40 dark:bg-rose-950/20">
        <div class="text-xs font-semibold uppercase tracking-widest text-rose-600 dark:text-rose-300">Salidas efectivo</div>
        <div class="mt-2 text-2xl font-black text-rose-700 dark:text-rose-300">{{ formatCurrency(salidasEfectivo) }}</div>
        <div class="mt-2 text-xs text-rose-700/70 dark:text-rose-300/70">Solo metodo EFECTIVO</div>
      </div>
      <div class="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-[#111c2e]">
        <div class="text-xs font-semibold uppercase tracking-widest text-slate-400">Saldo esperado</div>
        <div class="mt-2 text-2xl font-black text-slate-900 dark:text-white">{{ formatCurrency(saldoEsperado) }}</div>
        <div class="mt-2 text-xs text-slate-400">Saldo inicial + entradas - salidas</div>
      </div>
      <div class="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-[#111c2e]">
        <div class="flex items-center justify-between text-xs font-semibold uppercase tracking-widest text-slate-400">
          <span>Saldo contado</span>
          <button class="text-[10px] text-blue-500 hover:underline" @click="saldoContado = saldoEsperado">Usar esperado</button>
        </div>
        <input
          v-model.number="saldoContado"
          type="number"
          min="0"
          step="0.01"
          class="mt-2 w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-lg font-black text-slate-900 dark:border-slate-700 dark:bg-[#0f1729] dark:text-white"
        />
        <div class="mt-2 text-xs text-slate-400">Captura el efectivo real en caja.</div>
      </div>
      <div class="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-[#111c2e]">
        <div class="text-xs font-semibold uppercase tracking-widest text-slate-400">Diferencia</div>
        <div
          class="mt-2 text-2xl font-black"
          :class="diferencia === 0 ? 'text-slate-900 dark:text-white' : diferencia > 0 ? 'text-emerald-600' : 'text-rose-600'"
        >
          {{ formatCurrency(diferencia) }}
        </div>
        <div class="mt-2 text-xs text-slate-400">Contado - esperado.</div>
      </div>
    </section>

    <section class="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-[#111c2e]">
      <div class="flex flex-wrap items-end gap-4">
        <div class="flex flex-1 min-w-[200px] flex-col gap-1.5">
          <label class="text-xs font-semibold uppercase tracking-widest text-slate-400">Buscar</label>
          <input
            v-model="searchTerm"
            placeholder="Concepto, categoria, notas..."
            class="w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 dark:border-slate-700 dark:bg-[#0f1729] dark:text-slate-100"
          />
        </div>
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-semibold uppercase tracking-widest text-slate-400">Desde</label>
          <input v-model="dateFrom" type="date" class="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 dark:border-slate-700 dark:bg-[#0f1729] dark:text-slate-100" />
        </div>
        <div class="flex flex-col gap-1.5">
          <label class="text-xs font-semibold uppercase tracking-widest text-slate-400">Hasta</label>
          <input v-model="dateTo" type="date" class="rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 dark:border-slate-700 dark:bg-[#0f1729] dark:text-slate-100" />
        </div>
        <div class="flex items-center gap-2">
          <button class="rounded-lg bg-blue-500 px-4 py-2 text-sm font-semibold text-white hover:bg-blue-600" @click="applyFilters">Aplicar</button>
          <button class="rounded-lg border border-slate-200 px-4 py-2 text-sm font-semibold text-slate-600 hover:bg-slate-50 dark:border-slate-700 dark:text-slate-300 dark:hover:bg-slate-800" @click="clearFilters">Limpiar</button>
        </div>
      </div>
    </section>

    <section class="grid grid-cols-1 gap-6 lg:grid-cols-[1.2fr_1fr]">
      <div class="rounded-2xl border border-slate-100 bg-white shadow-sm dark:border-white/10 dark:bg-[#111c2e]">
        <div class="border-b border-slate-100 px-5 py-4 text-sm font-bold uppercase tracking-widest text-slate-400 dark:border-white/10">
          Movimientos
        </div>
        <div class="overflow-x-auto">
          <div class="min-w-[720px]">
            <div class="grid grid-cols-[140px_130px_1fr_120px_120px] gap-3 px-5 py-3 text-[11px] font-bold uppercase tracking-wider text-slate-400">
              <div>Fecha</div>
              <div>Tipo</div>
              <div>Concepto</div>
              <div>Metodo</div>
              <div class="text-right">Monto</div>
            </div>
            <div v-if="loading" class="px-5 py-6 text-sm text-slate-400">Cargando...</div>
            <div v-else-if="errorMsg" class="px-5 py-6 text-sm text-rose-500">{{ errorMsg }}</div>
            <div v-else>
              <div
                v-for="mov in filteredMovimientos"
                :key="mov.id"
                class="grid grid-cols-[140px_130px_1fr_120px_120px] gap-3 border-t border-slate-100 px-5 py-3 text-sm text-slate-700 dark:border-white/10 dark:text-slate-200"
              >
                <div class="text-xs text-slate-400">{{ formatDateTime(mov.created_at) }}</div>
                <div>
                  <span
                    class="rounded-full px-2 py-1 text-[10px] font-bold uppercase"
                    :class="mov.es_entrada ? 'bg-emerald-100 text-emerald-700 dark:bg-emerald-900/40 dark:text-emerald-300' : 'bg-rose-100 text-rose-700 dark:bg-rose-900/40 dark:text-rose-300'"
                  >
                    {{ mov.tipo }}
                  </span>
                </div>
                <div>
                  <div class="font-semibold text-slate-800 dark:text-slate-100">{{ mov.concepto }}</div>
                  <div v-if="mov.categoria" class="text-xs text-slate-400">{{ mov.categoria }}</div>
                </div>
                <div class="text-xs font-semibold uppercase text-slate-500">{{ normalizeMetodo(mov.metodo_pago) }}</div>
                <div class="text-right font-bold" :class="mov.es_entrada ? 'text-emerald-600' : 'text-rose-600'">
                  {{ mov.es_entrada ? '+' : '-' }}{{ formatCurrency(mov.monto) }}
                </div>
              </div>
              <div v-if="!filteredMovimientos.length" class="px-5 py-6 text-sm text-slate-400">
                Sin movimientos para los filtros seleccionados.
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="rounded-2xl border border-slate-100 bg-white p-5 shadow-sm dark:border-white/10 dark:bg-[#111c2e]">
        <div class="text-sm font-bold uppercase tracking-widest text-slate-400">Registrar movimiento</div>
        <form class="mt-4 space-y-3" @submit.prevent="guardarMovimiento">
          <div>
            <label class="text-xs font-semibold uppercase tracking-widest text-slate-400">Tipo</label>
            <select v-model="form.tipo" class="mt-1 w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 dark:border-slate-700 dark:bg-[#0f1729] dark:text-slate-100">
              <option v-for="opt in tipoOptions" :key="opt.value" :value="opt.value">
                {{ opt.label }}
              </option>
            </select>
          </div>
          <div>
            <label class="text-xs font-semibold uppercase tracking-widest text-slate-400">Concepto</label>
            <input v-model="form.concepto" placeholder="Ej: Compra de papel" class="mt-1 w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 dark:border-slate-700 dark:bg-[#0f1729] dark:text-slate-100" />
          </div>
          <div>
            <label class="text-xs font-semibold uppercase tracking-widest text-slate-400">Categoria</label>
            <input v-model="form.categoria" placeholder="Ej: insumos" class="mt-1 w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 dark:border-slate-700 dark:bg-[#0f1729] dark:text-slate-100" />
          </div>
          <div class="grid grid-cols-2 gap-3">
            <div>
              <label class="text-xs font-semibold uppercase tracking-widest text-slate-400">Metodo</label>
              <select v-model="form.metodo_pago" class="mt-1 w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 dark:border-slate-700 dark:bg-[#0f1729] dark:text-slate-100">
                <option value="EFECTIVO">EFECTIVO</option>
                <option value="TRANSFERENCIA">TRANSFERENCIA</option>
                <option value="TARJETA">TARJETA</option>
                <option value="OTRO">OTRO</option>
              </select>
            </div>
            <div>
              <label class="text-xs font-semibold uppercase tracking-widest text-slate-400">Monto</label>
              <input v-model.number="form.monto" type="number" min="0.01" step="0.01" class="mt-1 w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 dark:border-slate-700 dark:bg-[#0f1729] dark:text-slate-100" />
            </div>
          </div>
          <div>
            <label class="text-xs font-semibold uppercase tracking-widest text-slate-400">Notas</label>
            <textarea v-model="form.notas" rows="2" class="mt-1 w-full rounded-lg border border-slate-200 bg-white px-3 py-2 text-sm text-slate-900 dark:border-slate-700 dark:bg-[#0f1729] dark:text-slate-100"></textarea>
          </div>
          <div class="flex items-center justify-between">
            <div class="text-xs text-slate-400">{{ form.es_entrada ? 'Entrada' : 'Salida' }}</div>
            <button
              type="submit"
              class="rounded-lg bg-emerald-500 px-4 py-2 text-sm font-semibold text-white hover:bg-emerald-600"
              :disabled="!form.concepto || !form.monto"
            >
              Registrar
            </button>
          </div>
          <p v-if="formError" class="text-xs text-rose-500">{{ formError }}</p>
        </form>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { useCaja } from '../composables/useCaja'
import type { MovimientoCajaInput, TipoMovimientoCaja } from '../types'

const { cajaActiva, movimientos, loading, errorMsg, ensureCajaActiva, abrirCaja, fetchMovimientos, crearMovimiento } = useCaja()

const dateFrom = ref<string | null>(null)
const dateTo = ref<string | null>(null)
const searchTerm = ref('')
const saldoContado = ref(0)
const formError = ref<string | null>(null)
const aperturaSaldo = ref(0)
const aperturaWorking = ref(false)
const aperturaError = ref<string | null>(null)

const tipoOptions: Array<{ value: TipoMovimientoCaja; label: string; esEntrada: boolean }> = [
  { value: 'VENTA', label: 'VENTA (entrada)', esEntrada: true },
  { value: 'ANTICIPO', label: 'ANTICIPO (entrada)', esEntrada: true },
  { value: 'ABONO', label: 'ABONO (entrada)', esEntrada: true },
  { value: 'AJUSTE_ENTRADA', label: 'AJUSTE ENTRADA', esEntrada: true },
  { value: 'PRESTAMO_RECIBIDO', label: 'PRESTAMO RECIBIDO', esEntrada: true },
  { value: 'GASTO_NEGOCIO', label: 'GASTO NEGOCIO', esEntrada: false },
  { value: 'GASTO_PERSONAL', label: 'GASTO PERSONAL', esEntrada: false },
  { value: 'RETIRO_DUENO', label: 'RETIRO DUENO', esEntrada: false },
  { value: 'COMPRA_MATERIAL', label: 'COMPRA MATERIAL', esEntrada: false },
  { value: 'PAGO_SERVICIO', label: 'PAGO SERVICIO', esEntrada: false },
  { value: 'AJUSTE_SALIDA', label: 'AJUSTE SALIDA', esEntrada: false }
]

const form = ref<MovimientoCajaInput>({
  tipo: 'GASTO_NEGOCIO',
  concepto: '',
  categoria: '',
  metodo_pago: 'EFECTIVO',
  es_entrada: false,
  monto: 0,
  notas: ''
})

watch(
  () => form.value.tipo,
  (tipo) => {
    const opt = tipoOptions.find((o) => o.value === tipo)
    form.value.es_entrada = opt ? opt.esEntrada : false
  },
  { immediate: true }
)

const filteredMovimientos = computed(() => {
  const q = searchTerm.value.toLowerCase().trim()
  if (!q) return movimientos.value
  return movimientos.value.filter((m) => {
    return [m.concepto, m.categoria, m.notas]
      .filter(Boolean)
      .some((value) => String(value).toLowerCase().includes(q))
  })
})

const saldoInicial = computed(() => Number(cajaActiva.value?.saldo_inicial || 0))

const entradasEfectivo = computed(() => {
  return filteredMovimientos.value
    .filter((m) => m.es_entrada && normalizeMetodo(m.metodo_pago) === 'EFECTIVO')
    .reduce((s, m) => s + Number(m.monto || 0), 0)
})

const salidasEfectivo = computed(() => {
  return filteredMovimientos.value
    .filter((m) => !m.es_entrada && normalizeMetodo(m.metodo_pago) === 'EFECTIVO')
    .reduce((s, m) => s + Number(m.monto || 0), 0)
})

const saldoEsperado = computed(() => saldoInicial.value + entradasEfectivo.value - salidasEfectivo.value)
const diferencia = computed(() => Number(saldoContado.value || 0) - saldoEsperado.value)

function formatCurrency(n: number) {
  return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN', maximumFractionDigits: 2 }).format(n || 0)
}

function formatDateTime(iso: string) {
  if (!iso) return '-'
  const d = new Date(iso)
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())} ${pad(d.getHours())}:${pad(d.getMinutes())}`
}

function normalizeMetodo(value: string | null | undefined) {
  return String(value || 'EFECTIVO').toUpperCase()
}

function formatLocalDate(date: Date): string {
  const pad = (n: number) => String(n).padStart(2, '0')
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}`
}

async function applyFilters() {
  await fetchMovimientos({ dateFrom: dateFrom.value, dateTo: dateTo.value })
}

async function clearFilters() {
  dateFrom.value = null
  dateTo.value = null
  await fetchMovimientos({ dateFrom: null, dateTo: null })
}

async function abrirCajaNueva() {
  aperturaError.value = null
  const saldo = Number(aperturaSaldo.value)
  if (!Number.isFinite(saldo) || saldo < 0) {
    aperturaError.value = 'Ingresa un monto inicial valido.'
    return
  }

  if (cajaActiva.value) {
    const ok = confirm('Hay una caja abierta. Se cerrara y se abrira una nueva. ?Continuar?')
    if (!ok) return
  }

  try {
    aperturaWorking.value = true
    await abrirCaja(saldo)
    const today = formatLocalDate(new Date())
    dateFrom.value = today
    dateTo.value = today
    saldoContado.value = saldo
    await fetchMovimientos({ dateFrom: dateFrom.value, dateTo: dateTo.value })
  } catch (e) {
    aperturaError.value = 'No se pudo abrir la caja.'
  } finally {
    aperturaWorking.value = false
  }
}

async function guardarMovimiento() {
  formError.value = null
  if (!form.value.concepto || !form.value.monto) {
    formError.value = 'Concepto y monto son obligatorios.'
    return
  }

  try {
    await crearMovimiento({
      tipo: form.value.tipo,
      concepto: form.value.concepto.trim(),
      categoria: form.value.categoria?.trim() || null,
      metodo_pago: normalizeMetodo(form.value.metodo_pago),
      es_entrada: form.value.es_entrada,
      monto: Number(form.value.monto),
      notas: form.value.notas?.trim() || null
    })
    await fetchMovimientos({ dateFrom: dateFrom.value, dateTo: dateTo.value })
    form.value.concepto = ''
    form.value.categoria = ''
    form.value.monto = 0
    form.value.notas = ''
  } catch (e) {
    formError.value = 'No se pudo guardar el movimiento.'
  }
}

onMounted(async () => {
  await ensureCajaActiva()
  const today = formatLocalDate(new Date())
  dateFrom.value = today
  dateTo.value = today
  await fetchMovimientos({ dateFrom: dateFrom.value, dateTo: dateTo.value })
})
</script>
