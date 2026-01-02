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
