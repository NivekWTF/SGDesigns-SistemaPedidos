import { reactive, computed, toRaw } from 'vue'
import html2canvas from 'html2canvas'
import jsPDF from 'jspdf'
import { isRef, type Ref } from 'vue'
import autoTable from 'jspdf-autotable'

// 🔑 clave para provide/inject
export const STORE_KEY = Symbol('quote-store')

export type Company = {
  name: string
  rfc: string
  email: string
  phone: string
  address: string
}

export type Header = {
  series: string
  date: string        // YYYY-MM-DD
  folio: string
  company: Company
  logoDataUrl: string // dataURL del logo
}

export type Client = { name: string; address: string }
export type Config = { taxRate: number } // 0.16 = 16%
export type ItemRow = { qty: number; description: string; unitPrice: number; applyTax: boolean }

export type QuoteState = {
  header: Header
  client: Client
  config: Config
  items: ItemRow[]
  notes: string
}

// ------------------ utilidades ------------------
function todayISO(): string {
  const d = new Date()
  return d.toISOString().slice(0, 10)
}
function pad(n: number | string, size = 4): string {
  return String(n).padStart(size, '0')
}
function dateCompact(iso?: string): string {
  return (iso || todayISO()).replace(/-/g, '')
}

function currency(n: number | Ref<number>): string {
  const val = isRef(n) ? n.value : n
  if (Number.isNaN(val as number)) return '$0.00'
  return (val ?? 0).toLocaleString('es-MX', { style: 'currency', currency: 'MXN' })
}

// ------------------ store ------------------
export function useQuoteStore() {
  const state = reactive<QuoteState>({
    header: {
      series: 'SG',
      date: todayISO(),
      folio: '',
      company: {
        name: 'SG Designs',
        rfc: 'SEGK0106071D1',
        email: '',
        phone: '(697) 104 2067',
        address: 'Av. Ignacio Rayón #79, Col. Centro,\nPericos, Mocorito, Sinaloa.',
      },
      logoDataUrl: '',
    },
    client: { name: '', address: '' },
    config: { taxRate: 0.16 },
    items: [{ qty: 1, description: '', unitPrice: 0, applyTax: true }],
    notes: '',
  })

  // Cargar el logo por defecto
  if (!state.header.logoDataUrl) {
    fetch('/logo sg 2.png')
      .then(res => res.blob())
      .then(blob => {
        const reader = new FileReader()
        reader.onload = () => {
          // Solo asignamos si no ha sido cambiado
          if (!state.header.logoDataUrl) {
            state.header.logoDataUrl = reader.result as string
          }
        }
        reader.readAsDataURL(blob)
      })
      .catch(err => console.warn('No se pudo cargar el logo por defecto', err))
  }

  // Folio automático SERIE-YYYYMMDD-#### (contador diario en LocalStorage)
  function generateFolio(): void {
    const { series, date } = state.header
    const d = dateCompact(date)
    const key = `folioCounter:${series}:${d}`
    const next = (parseInt(localStorage.getItem(key) || '0', 10) + 1)
    localStorage.setItem(key, String(next))
    state.header.folio = `${series}-${d}-${pad(next)}`
  }
  if (!state.header.folio) generateFolio()

  const subtotal = computed<number>(() =>
    state.items.reduce((s, i) => s + Number(i.qty || 0) * Number(i.unitPrice || 0), 0),
  )
  const ivaTotal = computed<number>(() =>
    state.items.reduce(
      (s, i) =>
        s + (i.applyTax ? Number(i.qty || 0) * Number(i.unitPrice || 0) * state.config.taxRate : 0),
      0,
    ),
  )
  const grandTotal = computed<number>(() => subtotal.value + ivaTotal.value)

  function addItem(): void {
    state.items.push({ qty: 1, description: '', unitPrice: 0, applyTax: true })
  }
  function removeItem(idx: number): void {
    if (state.items.length > 1) state.items.splice(idx, 1)
  }
  function clearItems(): void {
    state.items = [{ qty: 1, description: '', unitPrice: 0, applyTax: true }]
  }

  function saveDraft(): void {
    localStorage.setItem('ricardos:quote:draft', JSON.stringify(toRaw(state)))
  }
  function loadDraft(): void {
    const raw = localStorage.getItem('ricardos:quote:draft')
    if (raw) {
      const d = JSON.parse(raw) as QuoteState
      Object.assign(state, d)
    }
  }
  function resetAll(): void {
    Object.assign(state, {
      header: {
        series: 'SG',
        date: todayISO(),
        folio: '',
        company: {
          name: 'SG Designs',
          rfc: 'SEGK0106071D1',
          email: '',
          phone: '(697) 104 2067',
          address: 'Av. Ignacio Rayón #79, Col. Centro,\nPericos, Mocorito, Sinaloa.',
        },
        logoDataUrl: '',
      },
      client: { name: '', address: '' },
      config: { taxRate: 0.16 },
      items: [{ qty: 1, description: '', unitPrice: 0, applyTax: true }],
      notes: '',
    } as QuoteState)
    generateFolio()
    
    // Recargar el logo por defecto al resetear
    fetch('/logo sg 2.png')
      .then(res => res.blob())
      .then(blob => {
        const reader = new FileReader()
        reader.onload = () => {
          state.header.logoDataUrl = reader.result as string
        }
        reader.readAsDataURL(blob)
      })
      .catch(err => console.warn('No se pudo cargar el logo por defecto al resetear', err))
  }

  function exportJSON(): void {
    const blob = new Blob([JSON.stringify(toRaw(state), null, 2)], { type: 'application/json' })
    const a = document.createElement('a')
    a.href = URL.createObjectURL(blob)
    a.download = `cotizacion-${state.header.folio || 'sin-folio'}.json`
    a.click()
    URL.revokeObjectURL(a.href)
  }
  function importJSON(evt: Event): void {
    const input = evt.target as HTMLInputElement
    const file = input.files?.[0]
    if (!file) return
    const reader = new FileReader()
    reader.onload = (e) => {
      try {
        const data = JSON.parse(String((e.target as FileReader).result)) as QuoteState
        Object.assign(state, data)
      } catch {
        alert('Archivo JSON inválido')
      }
    }
    reader.readAsText(file)
    input.value = ''
  }

async function makePDFText(): Promise<void> {
  const pdf = new jsPDF('p', 'pt', 'letter') // 612x792 pt
  const pageW = pdf.internal.pageSize.getWidth()
  const pageH = pdf.internal.pageSize.getHeight()
  const M = 36 // margen
  let y = M

  // --- Encabezado: Logo + Título ---
  if (state.header.logoDataUrl) {
    try {
      pdf.addImage(state.header.logoDataUrl, 'PNG', M, y, 64, 64)
    } catch { /* si el logo no es válido, lo omitimos */ }
  }
  pdf.setFont('helvetica', 'bold')
  pdf.setFontSize(18)
  pdf.text(state.header.company.name || 'COTIZACIÓN', M + 76, y + 18)

  pdf.setFont('helvetica', 'normal')
  pdf.setFontSize(10)
  const infoLines = [
    `${state.header.company.name} · RFC: ${state.header.company.rfc}`,
    `${state.header.company.email} · Tel: ${state.header.company.phone}`,
    ...state.header.company.address.split('\n'),
  ]
  infoLines.forEach((ln, i) => pdf.text(ln, M + 76, y + 34 + i * 14))

  // Caja “Cotización / Folio” a la derecha
  pdf.setFont('helvetica', 'bold')
  pdf.setFontSize(22)
  const title = 'COTIZACIÓN'
  pdf.text(title, pageW - M - pdf.getTextWidth(title), y + 16)
  pdf.setLineWidth(1)
  pdf.roundedRect(pageW - 220, y + 24, 200, 46, 8, 8)
  pdf.setFontSize(9)
  pdf.text('FOLIO', pageW - 220 + 200 - 36 - pdf.getTextWidth('FOLIO'), y + 36)
  pdf.setFont('helvetica', 'bold')
  pdf.setFontSize(14)
  pdf.text(state.header.folio, pageW - 220 + 12, y + 60)

  y += 92

  // --- Datos del cliente / fecha ---
  pdf.setFont('helvetica', 'bold'); pdf.setFontSize(12)
  pdf.text('Cliente:', M, y)
  pdf.setFont('helvetica', 'normal')
  pdf.text(state.client.name || '-', M + 58, y)
  y += 16

  pdf.setFont('helvetica', 'bold')
  pdf.text('Dirección:', M, y)
  pdf.setFont('helvetica', 'normal')
  const addr = pdf.splitTextToSize(state.client.address || '-', pageW - M*2 - 70)
  pdf.text(addr, M + 70, y)
  y += 16 + (addr.length - 1) * 12

  pdf.setFont('helvetica', 'bold')
  pdf.text('Serie:', M, y)
  pdf.setFont('helvetica', 'normal')
  pdf.text(state.header.series, M + 42, y)
  pdf.setFont('helvetica', 'bold')
  pdf.text('Fecha:', M + 140, y)
  pdf.setFont('helvetica', 'normal')
  pdf.text(state.header.date, M + 188, y)

  y += 18

  // Línea separadora
  pdf.setDrawColor(170); pdf.setLineWidth(.8)
  pdf.line(M, y, pageW - M, y)
  y += 12

  // --- Tabla de conceptos ---
  const head = [['CANTIDAD', 'DESCRIPCIÓN', 'P. UNITARIO', 'IVA', 'IMPORTE']]
  const body = state.items.map((it) => {
    const qty = Number(it.qty || 0)
    const unit = Number(it.unitPrice || 0)
    const sub = qty * unit
    const iva = it.applyTax ? sub * state.config.taxRate : 0
    return [
      String(qty),
      it.description || '',
      currency(unit),
      it.applyTax ? currency(iva) : 'N/A',
      currency(sub + iva),
    ]
  })

  autoTable(pdf, {
    startY: y,
    head,
    body,
    theme: 'grid',
    styles: { font: 'helvetica', fontSize: 10, cellPadding: 4 },
    headStyles: { fillColor: [27, 66, 118], textColor: 255, halign: 'left' },
    columnStyles: {
      0: { halign: 'center', cellWidth: 70 },
      1: { cellWidth: pageW - M*2 - (70 + 110 + 90 + 110) }, // ancho dinámico
      2: { halign: 'right', cellWidth: 110 },
      3: { halign: 'center', cellWidth: 90 },
      4: { halign: 'right', cellWidth: 110 },
    },
    margin: { left: M, right: M },
    didDrawPage: (data) => { /* aquí podrías numerar páginas si lo deseas */ },
  })

  // Posición después de la tabla
  // @ts-ignore: lastAutoTable la añade el plugin
  const afterTableY: number = (pdf as any).lastAutoTable.finalY + 12

  // --- Notas y Totales (dos columnas) ---
  const colLeftW = pageW - M*2 - 220
  pdf.setFont('helvetica', 'bold'); pdf.setFontSize(12)
  pdf.text('Notas / Observaciones', M, afterTableY)
  pdf.setFont('helvetica', 'normal'); pdf.setFontSize(10)
  const notesLines = pdf.splitTextToSize(state.notes || '', colLeftW)
  pdf.text(notesLines, M, afterTableY + 16)

  // Totales a la derecha
  const totalsX = pageW - M - 220
  let ty = afterTableY
  pdf.setFont('helvetica', 'bold'); pdf.setFontSize(12)
  pdf.text('Totales', totalsX, ty); ty += 10

  pdf.setFontSize(10); pdf.setFont('helvetica', 'normal')
  const line = (label: string, value: string, bold = false) => {
    pdf.setFont('helvetica', bold ? 'bold' : 'normal')
    pdf.text(label, totalsX, ty)
    pdf.text(value, totalsX + 220 - pdf.getTextWidth(value), ty)
    ty += 14
  }
  line('SUBTOTAL', currency(subtotal.value))
  line('IVA',      currency(ivaTotal.value))
  line('TOTAL',    currency(grandTotal.value), true)

  ty += 8
  pdf.setFont('helvetica', 'bold')
  pdf.text(
    `TOTAL EN LETRAS: ${numeroALetras(Math.round(grandTotal.value))} PESOS MEXICANOS`,
    M,
    Math.max(ty, afterTableY + 16 + notesLines.length * 12) + 12
  )

  pdf.save(`COT-${state.header.folio}.pdf`)
}

  function numeroALetras(num: number): string {
    const unidades = [
      '', 'UNO', 'DOS', 'TRES', 'CUATRO', 'CINCO',
      'SEIS', 'SIETE', 'OCHO', 'NUEVE', 'DIEZ',
      'ONCE', 'DOCE', 'TRECE', 'CATORCE', 'QUINCE',
      'DIECISÉIS', 'DIECISIETE', 'DIECIOCHO', 'DIECINUEVE', 'VEINTE'
    ]
    const decenas = [
      '', '', 'VEINTE', 'TREINTA', 'CUARENTA', 'CINCUENTA',
      'SESENTA', 'SETENTA', 'OCHENTA', 'NOVENTA'
    ]
    const centenas = [
      '', 'CIENTO', 'DOSCIENTOS', 'TRESCIENTOS', 'CUATROCIENTOS',
      'QUINIENTOS', 'SEISCIENTOS', 'SETECIENTOS', 'OCHOCIENTOS', 'NOVECIENTOS'
    ]

    if (num === 0) return 'CERO'
    if (num === 100) return 'CIEN'

    function convertir(n: number): string {
      if (n < 21) return unidades[n]
      if (n < 100) {
        return decenas[Math.floor(n / 10)] + (n % 10 ? ' Y ' + unidades[n % 10] : '')
      }
      if (n < 1000) {
        return centenas[Math.floor(n / 100)] + (n % 100 ? ' ' + convertir(n % 100) : '')
      }
      if (n < 1000000) {
        const miles = Math.floor(n / 1000)
        const resto = n % 1000
        return (miles === 1 ? 'MIL' : convertir(miles) + ' MIL') + (resto ? ' ' + convertir(resto) : '')
      }
      return n.toString() // fallback para números muy grandes
    }

    return convertir(num)
  }

  return {
    state,
    // getters
    subtotal,
    ivaTotal,
    grandTotal,
    // acciones
    addItem,
    removeItem,
    clearItems,
    saveDraft,
    loadDraft,
    resetAll,
    exportJSON,
    importJSON,
    makePDFText,
    generateFolio,
    // util
    currency,
    numeroALetras,
  }
}
