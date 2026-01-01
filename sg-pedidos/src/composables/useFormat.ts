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

  return { formatDate, formatDateOnly, formatTime }
}
