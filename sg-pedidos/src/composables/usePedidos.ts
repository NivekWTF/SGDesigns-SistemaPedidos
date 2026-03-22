import { ref } from 'vue'
import { supabase } from '../lib/supabase'
import { getMaterialRules } from '../lib/costs'
import type { CrearPedidoInput, EstadoPedido, Pedido, PedidoItemInput } from '../types'

const pedidos = ref<Pedido[]>([])
const loading = ref(false)
const errorMsg = ref<string | null>(null)
const THERMAL_LOGO_MAX_WIDTH_PX = 384

async function fetchPedidos() {
  loading.value = true
  errorMsg.value = null

  const { data, error } = await supabase
    .from('pedidos')
    .select(`
      id,
      folio,
      estado,
      notas,
      total,
      created_at,
      cliente_id,
      clientes ( nombre ),
      pedido_items ( id, producto_id, descripcion_personalizada, cantidad, precio_unitario, subtotal, productos ( nombre ) ),
      pagos ( id, monto, metodo, referencia, creado_en, es_anticipo )
    `)
    .order('created_at', { ascending: false })

  if (error) {
    errorMsg.value = (error as any)?.message ?? JSON.stringify(error)
  } else {
    pedidos.value = (data as unknown as Pedido[]) || []
  }

  loading.value = false
}

async function fetchPedidoById(id: string) {
  errorMsg.value = null
  const { data, error } = await supabase
    .from('pedidos')
    .select(`
      id,
      folio,
      estado,
      notas,
      total,
      created_at,
      cliente_id,
      clientes ( nombre ),
      pedido_items ( id, producto_id, descripcion_personalizada, cantidad, precio_unitario, subtotal, productos ( id, nombre ) ),
      pagos ( id, monto, metodo, referencia, creado_en, es_anticipo )
    `)
    .eq('id', id)
    .single()

  if (error) {
    errorMsg.value = (error as any)?.message ?? JSON.stringify(error)
    throw error
  }

  return data as unknown as Pedido
}

async function crearPedido(input: CrearPedidoInput) {
  errorMsg.value = null
  // Prefer RPC: try to call DB function that creates pedido and decrements stock atomically
  try {
    // --- Compute material consumptions ---
    // 1. Fetch product names for items that have a producto_id
    const prodIds = input.items.map(i => i.producto_id).filter(Boolean) as string[]
    let productNames: Record<string, string> = {}
    if (prodIds.length) {
      const { data: prods } = await supabase
        .from('productos')
        .select('id, nombre')
        .in('id', prodIds)
      if (prods) {
        for (const p of prods) productNames[p.id] = p.nombre
      }
    }

    // 2. Compute materials needed based on rules
    const materialNeeds: Record<string, number> = {} // materialPattern -> total qty needed
    for (const item of input.items) {
      if (!item.producto_id) continue
      const nombre = productNames[item.producto_id] || ''
      const rules = getMaterialRules(nombre)
      for (const rule of rules) {
        const consumed = Math.ceil(item.cantidad / rule.unitsPerMaterial)
        materialNeeds[rule.materialPattern] = (materialNeeds[rule.materialPattern] || 0) + consumed
      }
    }

    // 3. Resolve material patterns to producto_ids
    const consumos: Array<{ producto_id: string; cantidad: number }> = []
    for (const [pattern, qty] of Object.entries(materialNeeds)) {
      const { data: mats } = await supabase
        .from('productos')
        .select('id, nombre')
        .ilike('nombre', '%' + pattern + '%')
        .limit(1)
      const material = mats?.[0]
      if (material) {
        consumos.push({ producto_id: material.id, cantidad: qty })
      }
    }

    const { data, error } = await supabase.rpc('create_pedido_with_stock', {
      cliente_id: input.cliente_id,
      notas: input.notas ?? null,
      items: input.items,
      anticipo: input.anticipo ?? null,
      consumos: consumos.length ? consumos : [],
      anticipo_metodo: input.anticipo_metodo ?? null
    })

    if (error) {
      // if function not found or other RPC error, rethrow and fallback to client flow
      throw error
    }

    // rpc returns a row with pedido_id
    const pedidoId = (data && Array.isArray(data) && data[0] && (data[0].pedido_id || data[0].create_pedido_with_stock)) ? (data[0].pedido_id || data[0].create_pedido_with_stock) : null

    if (!pedidoId) {
      throw new Error('RPC did not return pedido id')
    }

    // fetch the created pedido with relations
    const { data: created, error: fetchErr } = await supabase
      .from('pedidos')
      .select(`
        id,
        folio,
        estado,
        notas,
        total,
        created_at,
        cliente_id,
        clientes ( nombre ),
        pedido_items ( id, producto_id, descripcion_personalizada, cantidad, precio_unitario, subtotal, productos ( id, nombre ) )
      `)
      .eq('id', pedidoId)
      .single()

    if (fetchErr) {
      errorMsg.value = (fetchErr as any)?.message ?? JSON.stringify(fetchErr)
      throw fetchErr
    }

    // NOTE: No se crean gastos al crear un pedido.
    // El gasto real ocurre al momento de comprar stock (referencia: "stock_add").
    // El pedido solo descuenta stock ya pagado; registrar otro gasto aquí
    // duplicaría el costo.

    await fetchPedidos()
    return created
  } catch (rpcErr) {
    // fallback: rethrow so client-side caller can handle
    errorMsg.value = (rpcErr as any)?.message ?? String(rpcErr)
    throw rpcErr
  }
}

async function actualizarEstadoPedido(id: string, estado: EstadoPedido) {
  const { error } = await supabase
    .from('pedidos')
    .update({ estado, updated_at: new Date().toISOString() })
    .eq('id', id)

  if (error) {
    errorMsg.value = (error as any)?.message ?? JSON.stringify(error)
    throw error
  }

  // update local cache without refetching to avoid losing UI state (pagination/scroll)
  try {
    const idx = pedidos.value.findIndex(p => p.id === id)
    if (idx !== -1) {
      const currentPedido = pedidos.value[idx]
      if (!currentPedido) return

      // mutate the object to keep reactivity
      pedidos.value[idx] = {
        ...currentPedido,
        estado,
        updated_at: new Date().toISOString()
      }
    }
  } catch (e) {
    // ignore local update errors
    console.warn('Failed to update local pedido state', e)
  }

  // If the pedido was marked as TERMINADO, fetch full data and print ticket
  try {
    if (estado === 'TERMINADO') {
      const full = await fetchPedidoById(id)
      // best-effort printing; do not block caller if printing fails
      try {
        await printTicket(full)
      } catch (printErr) {
        console.warn('Impresión de ticket falló', printErr)
      }
    }
  } catch (e) {
    // ignore fetch errors for printing
    console.warn('No se pudo obtener pedido para imprimir', e)
  }
}

function formatCurrencyNumber(n: number) {
  return new Intl.NumberFormat(undefined, { style: 'currency', currency: 'MXN', maximumFractionDigits: 2 }).format(n)
}

function formatAmount(n: number) {
  return new Intl.NumberFormat('es-MX', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(n)
}

function formatQty(n: number) {
  if (!Number.isFinite(n)) return '0'
  if (Number.isInteger(n)) return String(n)
  return new Intl.NumberFormat('es-MX', { minimumFractionDigits: 0, maximumFractionDigits: 2 }).format(n)
}

function escapeHtml(text: string) {
  return text
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/\"/g, '&quot;')
    .replace(/'/g, '&#39;')
}

/**
 * Convert logo URL to embedded base64 and downscale to a thermal-safe width.
 * Oversized images are a common source of garbled bytes on 58mm printers.
 */
function imageToBase64(url: string, maxWidthPx = THERMAL_LOGO_MAX_WIDTH_PX): Promise<string> {
  return new Promise((resolve) => {
    const img = new Image()
    img.crossOrigin = 'anonymous'
    img.onload = () => {
      try {
        const srcWidth = Math.max(1, img.naturalWidth || img.width || 1)
        const srcHeight = Math.max(1, img.naturalHeight || img.height || 1)
        const targetWidth = Math.min(srcWidth, maxWidthPx)
        const scale = targetWidth / srcWidth
        const targetHeight = Math.max(1, Math.round(srcHeight * scale))

        const canvas = document.createElement('canvas')
        canvas.width = targetWidth
        canvas.height = targetHeight
        const ctx = canvas.getContext('2d')
        if (ctx) {
          ctx.fillStyle = '#fff'
          ctx.fillRect(0, 0, targetWidth, targetHeight)
          ctx.imageSmoothingEnabled = true
          ctx.imageSmoothingQuality = 'high'
          ctx.drawImage(img, 0, 0, targetWidth, targetHeight)
          resolve(canvas.toDataURL('image/png'))
        } else {
          resolve('') // fallback: skip logo
        }
      } catch {
        resolve('') // CORS or tainted canvas — skip logo
      }
    }
    img.onerror = () => resolve('') // skip logo if it can't load
    img.src = url
  })
}

/**
 * Wait for print document and assets to be ready before invoking print().
 */
function waitForPrintReady(win: Window, timeoutMs = 2500): Promise<void> {
  return new Promise((resolve) => {
    let settled = false
    const finish = () => {
      if (!settled) {
        settled = true
        resolve()
      }
    }

    const waitForImages = () => {
      const images = Array.from(win.document.images || [])
      if (!images.length) {
        win.requestAnimationFrame(() => win.requestAnimationFrame(finish))
        return
      }

      let pending = images.length
      const markOneDone = () => {
        pending -= 1
        if (pending <= 0) {
          win.requestAnimationFrame(() => win.requestAnimationFrame(finish))
        }
      }

      for (const img of images) {
        if (img.complete) {
          markOneDone()
          continue
        }
        img.addEventListener('load', () => markOneDone(), { once: true })
        img.addEventListener('error', () => markOneDone(), { once: true })
      }
    }

    if (win.document.readyState === 'loading') {
      win.addEventListener('load', waitForImages, { once: true })
    } else {
      waitForImages()
    }

    setTimeout(finish, timeoutMs)
  })
}

async function printTicket(pedido: any) {
  try {
    const businessSocials = (import.meta.env.VITE_BUSINESS_SOCIALS as string) || 'FB: @miNegocio • IG: @miNegocio'
    const businessName = (import.meta.env.VITE_BUSINESS_NAME as string) || 'Mi Negocio'
    const businessAddress = (import.meta.env.VITE_BUSINESS_ADDRESS as string) || ''
    const businessPhone = (import.meta.env.VITE_BUSINESS_PHONE as string) || ''
    const businessLogo = (import.meta.env.VITE_BUSINESS_LOGO_URL as string) || '/logo.png'

    // Embed and resize logo to a thermal-friendly bitmap size.
    const logoDataUrl = businessLogo ? await imageToBase64(businessLogo, THERMAL_LOGO_MAX_WIDTH_PX) : ''

    const now = new Date()
    const printedAt = now.toLocaleString()
    const createdAtDate = pedido.created_at ? new Date(pedido.created_at) : null
    const orderDate = createdAtDate && !Number.isNaN(createdAtDate.getTime()) ? createdAtDate.toLocaleString() : printedAt

    const cliente = pedido.clientes?.nombre || 'Sin cliente'

    const items = pedido.pedido_items || []

    const rows = items.map((it: any) => {
      const desc = String(it.descripcion_personalizada || (it.productos && it.productos.nombre) || 'Producto sin descripcion')
        .replace(/\s+/g, ' ')
        .trim()
      const qty = Number(it.cantidad) || 0
      const unit = Number(it.precio_unitario) || 0
      const subtotal = Number(it.subtotal) || qty * unit
      return `
        <tr>
          <td class="col-qty">${formatQty(qty)}</td>
          <td class="col-desc">${escapeHtml(desc)}</td>
          <td class="col-unit">${formatAmount(unit)}</td>
          <td class="col-amount">${formatAmount(subtotal)}</td>
        </tr>
      `
    }).join('') || '<tr><td colspan="4" style="padding:4px 0">Sin productos en este pedido.</td></tr>'

    const pagos = pedido.pagos || []
    const anticipo = pagos.filter((p:any) => p.es_anticipo).reduce((s:number,p:any)=>s+Number(p.monto||0),0)
    const pagado = pagos.reduce((s:number,p:any)=>s+Number(p.monto||0),0)
    const total = Number(pedido.total) || 0
    const resta = Math.max(0, total - pagado)

    const paymentMethods = pagos.length
      ? (pagos
          .filter((p:any) => p.metodo)
          .map((p:any) => `${p.es_anticipo ? 'Anticipo' : 'Pago'}: ${String(p.metodo)}`)
          .join(' | ') || 'N/A')
      : 'N/A'

    const html = `
      <!doctype html>
      <html>
        <head>
          <meta charset="utf-8" />
          <title>Ticket</title>
          <style>
            @page { size: 58mm auto; margin: 2mm; }
            body {
              font-family: Consolas, 'Lucida Console', 'Courier New', monospace;
              font-size: 12px;
              font-weight: 600;
              line-height: 1.3;
              width: 58mm;
              margin: 0;
              padding: 2mm 3mm;
              color: #000;
              background: #fff;
              -webkit-print-color-adjust: exact;
              print-color-adjust: exact;
            }
            .center { text-align:center }
            .small { font-size: 11px; font-weight: 600; }
            .business-name { font-size: 16px; font-weight: 800; letter-spacing: 0.4px; margin-bottom: 2px; }
            .divider { border-top:1px dashed #000; margin:5px 0 }
            .meta { margin: 1px 0; word-break: break-word; font-size: 12px; font-weight: 700; }
            .ticket-table { width:100%; border-collapse:collapse; table-layout: fixed; }
            .ticket-table th {
              border-bottom: 1px solid #000;
              font-size: 11px;
              font-weight: 800;
              padding: 2px 0;
            }
            .ticket-table td {
              padding: 2px 0;
              border-bottom: 1px dotted #000;
              vertical-align: top;
              font-size: 12px;
              font-weight: 700;
            }
            .ticket-table tr:last-child td { border-bottom: none; }
            .col-qty { width: 12%; text-align: left; padding-right: 1mm; }
            .col-desc { width: 43%; text-align: left; padding-right: 1mm; word-break: break-word; }
            .col-unit { width: 22%; text-align: right; white-space: nowrap; }
            .col-amount { width: 23%; text-align: right; white-space: nowrap; }
            .summary-row {
              display: flex;
              justify-content: space-between;
              gap: 8px;
              margin: 1px 0;
              font-size: 12px;
              font-weight: 700;
            }
            .summary-row > span:last-child { min-width: 18mm; text-align: right; }
            .summary-row.total {
              border-top: 1px solid #000;
              padding-top: 2px;
              margin-top: 2px;
              font-size: 16px;
              font-weight: 800;
            }
            .footer-note { margin-top: 5px; word-break: break-word; font-size: 12px; font-weight: 700; }
            .thanks { margin-top: 6px; text-align: center; font-size: 13px; font-weight: 800; letter-spacing: 0.5px; }
          </style>
        </head>
        <body>
          ${logoDataUrl ? `<div class="center"><img src="${logoDataUrl}" alt="${escapeHtml(businessName)}" style="max-width:48mm;height:auto;margin:0 auto 4px" /></div>` : ''}
          <div class="center business-name">${escapeHtml(businessName)}</div>
          <div class="center meta">${escapeHtml(businessAddress)}</div>
          <div class="center meta">${escapeHtml(businessPhone)}</div>
          <div class="center small" style="margin-top:4px">${escapeHtml(businessSocials)}</div>
          <div class="divider"></div>
          <div class="meta">Fecha pedido: ${escapeHtml(orderDate)}</div>
          <div class="meta">Impreso: ${escapeHtml(printedAt)}</div>
          <div class="meta">Cliente: ${escapeHtml(String(cliente))}</div>
          <div class="divider"></div>
          <table class="ticket-table">
            <thead>
              <tr>
                <th class="col-qty">CANT</th>
                <th class="col-desc">DESCRIPCION</th>
                <th class="col-unit">P. UNIT</th>
                <th class="col-amount">IMPORTE</th>
              </tr>
            </thead>
            <tbody>
              ${rows}
            </tbody>
          </table>
          <div class="divider"></div>
          <div class="summary-row"><span>Anticipo:</span><span>${formatCurrencyNumber(anticipo)}</span></div>
          <div class="summary-row"><span>Pagado:</span><span>${formatCurrencyNumber(pagado)}</span></div>
          <div class="summary-row"><span>Resta:</span><span>${formatCurrencyNumber(resta)}</span></div>
          <div class="summary-row total"><span>Total Neto $</span><span>${formatAmount(total)}</span></div>
          <div class="footer-note">Forma de pago: ${escapeHtml(paymentMethods)}</div>
          <div class="divider"></div>
          <div class="thanks">GRACIAS POR SU COMPRA</div>
          <div style="height:30mm"></div>
        </body>
      </html>
    `

    const win = window.open('', '_blank', 'width=320,height=640')
    if (!win) throw new Error('No se pudo abrir ventana de impresión')
    win.document.open()
    win.document.write(html)
    win.document.close()
    win.focus()

    await waitForPrintReady(win)
    try { win.print() } catch (e) { console.warn('print() falló', e) }
  } catch (err) {
    console.warn('Error preparando ticket', err)
  }
}

async function registrarPago(pedidoId: string, monto: number, metodo: string) {
  const { error } = await supabase
    .from('pagos')
    .insert({
      pedido_id: pedidoId,
      monto,
      metodo,
      es_anticipo: false
    })

  if (error) {
    errorMsg.value = (error as any)?.message ?? JSON.stringify(error)
    throw error
  }
}

async function eliminarPedido(id: string) {
  const { error } = await supabase
    .from('pedidos')
    .delete()
    .eq('id', id)

  if (error) {
    errorMsg.value = (error as any)?.message ?? JSON.stringify(error)
    throw error
  }

  pedidos.value = pedidos.value.filter(p => p.id !== id)
}

async function actualizarPedidoCompleto(id: string, input: { notas?: string | null; items: PedidoItemInput[] }) {
  errorMsg.value = null

  // 1) actualizar campos del pedido
  const { error: errorUpdate } = await supabase
    .from('pedidos')
    .update({ notas: input.notas ?? null, updated_at: new Date().toISOString() })
    .eq('id', id)

  if (errorUpdate) {
    errorMsg.value = (errorUpdate as any)?.message ?? JSON.stringify(errorUpdate)
    throw errorUpdate
  }

  // 2) eliminar items existentes
  const { error: errorDelete } = await supabase.from('pedido_items').delete().eq('pedido_id', id)
  if (errorDelete) {
    errorMsg.value = (errorDelete as any)?.message ?? JSON.stringify(errorDelete)
    throw errorDelete
  }

  // 3) insertar nuevos items
  const itemsToInsert = input.items.map(it => ({
    pedido_id: id,
    producto_id: it.producto_id,
    descripcion_personalizada: it.descripcion_personalizada ?? null,
    cantidad: it.cantidad,
    precio_unitario: it.precio_unitario
  }))

  const { error: errorItems } = await supabase.from('pedido_items').insert(itemsToInsert)
  if (errorItems) {
    errorMsg.value = (errorItems as any)?.message ?? JSON.stringify(errorItems)
    throw errorItems
  }

  await fetchPedidos()
}

export function usePedidos() {
  return {
    pedidos,
    loading,
    errorMsg,
    fetchPedidos,
    fetchPedidoById,
    crearPedido,
    actualizarPedidoCompleto,
    actualizarEstadoPedido,
    registrarPago,
    printTicket,
    eliminarPedido
  }
}
