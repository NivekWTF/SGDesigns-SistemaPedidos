export function useFormat() {
  const formatDate = (
    s?: string | null,
    options: Intl.DateTimeFormatOptions = {}
  ) => {
    if (!s) return '-'
    return new Date(s).toLocaleString('es-MX', {
      dateStyle: 'medium',
      timeStyle: 'short',
      ...options
    })
  }

  const formatDateOnly = (
    s?: string | null,
    options: Intl.DateTimeFormatOptions = {}
  ) => {
    if (!s) return '-'
    return new Date(s).toLocaleDateString('es-MX', {
      dateStyle: 'medium',
      ...options
    })
  }

  const formatTime = (
    s?: string | null,
    options: Intl.DateTimeFormatOptions = {}
  ) => {
    if (!s) return '-'
    return new Date(s).toLocaleTimeString('es-MX', {
      timeStyle: 'short',
      ...options
    })
  }

  const formatCurrency = (n?: number | null) => {
    const v = Number(n || 0)
    return new Intl.NumberFormat('es-MX', { style: 'currency', currency: 'MXN', maximumFractionDigits: 2 }).format(v)
  }

  return { formatDate, formatDateOnly, formatTime, formatCurrency }
}
