export function getCostsForProduct(nombre: string | undefined | null) {
  const name = (nombre || '').toLowerCase()
  // Default zero costs
  let compra = 0
  let consumo = 0

  // Example mapping: tabloide couche
  if (name.includes('tabloide') && name.includes('couche')) {
    compra = 2 // cost when adding stock
    consumo = 5 // cost when consumed in an order
  }

  // Add other product-specific rules here

  return { compra, consumo }
}

/**
 * Material consumption rules.
 * When selling a product, it may consume raw materials from inventory.
 *
 * - materialPattern: substring to match the raw material product name (case-insensitive)
 * - unitsPerMaterial: how many units of the sold product fit in 1 unit of the material
 *   consumption = ceil(qty / unitsPerMaterial)
 */
export interface MaterialRule {
  materialPattern: string
  unitsPerMaterial: number
}

export function getMaterialRules(productName: string): MaterialRule[] {
  const name = (productName || '').toLowerCase()

  // Sobreplato: 1-2 sobreplatos consumen 1 Tabloide Couche grueso
  if (name.includes('sobreplato')) {
    return [{ materialPattern: 'tabloide couche grueso', unitsPerMaterial: 2 }]
  }

  // Cartera de Stickers: 1-4 stickers consumen 1 Tabloide de etiqueta
  if (name.includes('sticker') || (name.includes('cartera') && name.includes('sticker'))) {
    return [{ materialPattern: 'tabloide etiqueta', unitsPerMaterial: 4 }]
  }

  // Tarjetas de presentación: 100 tarjetas consumen 4 Tabloides Couche grueso
  // → 1 tabloide = 25 tarjetas
  if (name.includes('tarjeta') && name.includes('presentaci')) {
    return [{ materialPattern: 'tabloide couche grueso', unitsPerMaterial: 25 }]
  }

  return []
}
