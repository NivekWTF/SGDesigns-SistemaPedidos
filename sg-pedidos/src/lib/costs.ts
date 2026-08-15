/**
 * Material cost and consumption rules.
 *
 * These functions define how product sales map to raw material consumption.
 * For multi-tenant use, consider moving these rules to a `material_rules`
 * database table so each business can configure them from the admin panel.
 */

// --------------- Product cost mapping ---------------

export interface ProductCostEntry {
  /** substring pattern to match the product name (case-insensitive) */
  pattern: string
  /** cost when adding stock */
  compra: number
  /** cost when consumed in an order */
  consumo: number
}

/**
 * Default cost mapping.
 * In a multi-tenant setup, this should come from a `product_costs` DB table.
 */
const COST_ENTRIES: ProductCostEntry[] = [
  { pattern: 'tabloide couche', compra: 2, consumo: 5 },
  // Add more entries as needed per business
]

export function getCostsForProduct(nombre: string | undefined | null) {
  const name = (nombre || '').toLowerCase()
  let compra = 0
  let consumo = 0

  for (const entry of COST_ENTRIES) {
    const parts = entry.pattern.toLowerCase().split(/\s+/)
    if (parts.every(p => name.includes(p))) {
      compra = entry.compra
      consumo = entry.consumo
      break
    }
  }

  return { compra, consumo }
}

// --------------- Material consumption rules ---------------

/**
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

export interface MaterialRuleEntry {
  /** substring pattern to match the sold product name (case-insensitive) */
  productPattern: string
  rules: MaterialRule[]
}

/**
 * Default material consumption rules.
 * In a multi-tenant setup, this should come from a `material_rules` DB table.
 *
 * Example: selling "Sobreplato" consumes "Tabloide Couche Grueso" at a rate of 2:1.
 */
const MATERIAL_RULE_ENTRIES: MaterialRuleEntry[] = [
  {
    productPattern: 'sobreplato',
    rules: [{ materialPattern: 'tabloide couche grueso', unitsPerMaterial: 2 }],
  },
  {
    productPattern: 'sticker',
    rules: [{ materialPattern: 'tabloide etiqueta', unitsPerMaterial: 4 }],
  },
  {
    productPattern: 'tarjeta presentaci',
    rules: [{ materialPattern: 'tabloide couche grueso', unitsPerMaterial: 25 }],
  },
  {
    productPattern: 'esquela',
    rules: [{ materialPattern: 'tabloide etiqueta', unitsPerMaterial: 9 }],
  },
  // Add more entries as needed per business
]

export function getMaterialRules(productName: string): MaterialRule[] {
  const name = (productName || '').toLowerCase()

  for (const entry of MATERIAL_RULE_ENTRIES) {
    const parts = entry.productPattern.toLowerCase().split(/\s+/)
    if (parts.every(p => name.includes(p))) {
      return entry.rules
    }
  }

  return []
}
