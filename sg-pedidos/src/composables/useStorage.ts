// src/composables/useStorage.ts
import { ref } from 'vue'
import { supabase } from '../lib/supabase'

const MAX_FILE_SIZE = 15 * 1024 * 1024 // 15 MB

export function useStorage() {
  const uploading = ref(false)
  const errorMsg = ref<string | null>(null)

  /**
   * Upload a file to a Supabase Storage bucket.
   * Returns the public URL on success.
   */
  async function uploadFile(
    bucket: string,
    folder: string,
    file: File
  ): Promise<string | null> {
    errorMsg.value = null

    if (file.size > MAX_FILE_SIZE) {
      errorMsg.value = `El archivo "${file.name}" excede el límite de 15 MB`
      return null
    }

    // Build a unique path: folder/timestamp_filename
    const timestamp = Date.now()
    const safeName = file.name.replace(/[^a-zA-Z0-9._-]/g, '_')
    const filePath = `${folder}/${timestamp}_${safeName}`

    uploading.value = true
    try {
      const { error } = await supabase.storage
        .from(bucket)
        .upload(filePath, file, {
          cacheControl: '3600',
          upsert: false
        })

      if (error) {
        errorMsg.value = error.message
        return null
      }

      // Get public URL
      const { data: urlData } = supabase.storage
        .from(bucket)
        .getPublicUrl(filePath)

      return urlData.publicUrl
    } catch (err: any) {
      errorMsg.value = err?.message || String(err)
      return null
    } finally {
      uploading.value = false
    }
  }

  /**
   * Delete a file from a Supabase Storage bucket.
   * `filePath` should be the path within the bucket (not the full URL).
   */
  async function deleteFile(bucket: string, filePath: string): Promise<boolean> {
    errorMsg.value = null
    try {
      const { error } = await supabase.storage
        .from(bucket)
        .remove([filePath])

      if (error) {
        errorMsg.value = error.message
        return false
      }
      return true
    } catch (err: any) {
      errorMsg.value = err?.message || String(err)
      return false
    }
  }

  /**
   * Extract the storage path from a full public URL.
   * e.g. https://xxx.supabase.co/storage/v1/object/public/pedido-attachments/abc/file.png
   * → abc/file.png
   */
  function extractPathFromUrl(url: string, bucket: string): string {
    const marker = `/storage/v1/object/public/${bucket}/`
    const idx = url.indexOf(marker)
    if (idx === -1) return url
    return url.slice(idx + marker.length)
  }

  return {
    uploading,
    errorMsg,
    uploadFile,
    deleteFile,
    extractPathFromUrl,
    MAX_FILE_SIZE
  }
}
