<template>
  <div class="file-uploader">
    <div
      class="drop-zone"
      :class="{ 'drop-zone--active': isDragging, 'drop-zone--disabled': disabled }"
      @dragover.prevent="onDragOver"
      @dragleave.prevent="onDragLeave"
      @drop.prevent="onDrop"
      @click="openFilePicker"
    >
      <input
        ref="fileInput"
        type="file"
        :accept="accept"
        :multiple="maxFiles > 1"
        hidden
        @change="onFileSelected"
      />
      <div class="drop-zone__content" v-if="!uploading">
        <div class="drop-zone__icon">📎</div>
        <div class="drop-zone__text">
          Arrastra archivos aquí o <span class="drop-zone__link">haz clic para seleccionar</span>
        </div>
        <div class="drop-zone__hint">Máx. {{ maxFiles }} archivo(s) · {{ maxSizeMB }}MB por archivo</div>
      </div>
      <div class="drop-zone__content" v-else>
        <div class="drop-zone__spinner"></div>
        <div class="drop-zone__text">Subiendo archivo...</div>
      </div>
    </div>

    <!-- Error message -->
    <div v-if="error" class="upload-error">
      <span>⚠️</span> {{ error }}
    </div>

    <!-- Previews -->
    <div class="file-previews" v-if="allFiles.length">
      <div v-for="(f, idx) in allFiles" :key="f.url || idx" class="file-preview">
        <div class="file-preview__thumb" @click="openLightbox(f)">
          <img v-if="isImage(f.tipo || f.nombre_archivo)" :src="f.url" :alt="f.nombre_archivo" />
          <div v-else class="file-preview__icon">📄</div>
        </div>
        <div class="file-preview__info">
          <div class="file-preview__name" :title="f.nombre_archivo">{{ truncateName(f.nombre_archivo) }}</div>
          <div class="file-preview__size" v-if="f.tamanio_bytes">{{ formatSize(f.tamanio_bytes) }}</div>
        </div>
        <button
          v-if="!disabled"
          class="file-preview__delete"
          @click.stop="handleDelete(f, idx)"
          title="Eliminar archivo"
        >✕</button>
      </div>
    </div>

    <!-- Lightbox -->
    <Teleport to="body">
      <div v-if="lightboxUrl" class="lightbox-overlay" @click="lightboxUrl = null">
        <div class="lightbox-content" @click.stop>
          <img :src="lightboxUrl" alt="Preview" />
          <button class="lightbox-close" @click="lightboxUrl = null">✕</button>
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useStorage } from '../composables/useStorage'

interface FileItem {
  id?: string
  url: string
  nombre_archivo: string
  tipo?: string | null
  tamanio_bytes?: number | null
}

const props = withDefaults(defineProps<{
  bucket: string
  folder: string
  maxFiles?: number
  accept?: string
  existingFiles?: FileItem[]
  disabled?: boolean
}>(), {
  maxFiles: 10,
  accept: 'image/*,.pdf,.ai,.psd,.svg,.eps,.cdr',
  existingFiles: () => [],
  disabled: false
})

const emit = defineEmits<{
  uploaded: [file: FileItem]
  deleted: [file: FileItem, index: number]
}>()

const { uploadFile, deleteFile, extractPathFromUrl, uploading, errorMsg: storageError, MAX_FILE_SIZE } = useStorage()

const localFiles = ref<FileItem[]>([])
const isDragging = ref(false)
const error = ref<string | null>(null)
const lightboxUrl = ref<string | null>(null)
const fileInput = ref<HTMLInputElement | null>(null)

const maxSizeMB = Math.round(MAX_FILE_SIZE / 1024 / 1024)

const allFiles = computed(() => [...props.existingFiles, ...localFiles.value])

function openFilePicker() {
  if (props.disabled) return
  fileInput.value?.click()
}

function onDragOver() {
  if (props.disabled) return
  isDragging.value = true
}

function onDragLeave() {
  isDragging.value = false
}

async function onDrop(e: DragEvent) {
  isDragging.value = false
  if (props.disabled) return
  const files = Array.from(e.dataTransfer?.files || [])
  await processFiles(files)
}

async function onFileSelected(e: Event) {
  const input = e.target as HTMLInputElement
  const files = Array.from(input.files || [])
  await processFiles(files)
  // Reset input so re-selecting the same file works
  input.value = ''
}

async function processFiles(files: File[]) {
  error.value = null

  const remaining = props.maxFiles - allFiles.value.length
  if (remaining <= 0) {
    error.value = `Ya se alcanzó el máximo de ${props.maxFiles} archivos`
    return
  }

  const filesToUpload = files.slice(0, remaining)

  for (const file of filesToUpload) {
    if (file.size > MAX_FILE_SIZE) {
      error.value = `"${file.name}" excede el límite de ${maxSizeMB}MB`
      continue
    }

    const url = await uploadFile(props.bucket, props.folder, file)
    if (url) {
      const fileItem: FileItem = {
        url,
        nombre_archivo: file.name,
        tipo: file.type || null,
        tamanio_bytes: file.size
      }
      localFiles.value.push(fileItem)
      emit('uploaded', fileItem)
    } else if (storageError.value) {
      error.value = storageError.value
    }
  }
}

async function handleDelete(f: FileItem, idx: number) {
  error.value = null
  // Extract storage path from URL
  const path = extractPathFromUrl(f.url, props.bucket)
  const ok = await deleteFile(props.bucket, path)
  if (ok) {
    // Remove from local list if it's a locally-added file
    const localIdx = localFiles.value.findIndex(lf => lf.url === f.url)
    if (localIdx !== -1) {
      localFiles.value.splice(localIdx, 1)
    }
    emit('deleted', f, idx)
  } else if (storageError.value) {
    error.value = storageError.value
  }
}

function isImage(nameOrType: string): boolean {
  const lower = (nameOrType || '').toLowerCase()
  return /^image\//.test(lower) || /\.(jpg|jpeg|png|gif|webp|svg|bmp)$/i.test(lower)
}

function truncateName(name: string, max = 22): string {
  if (name.length <= max) return name
  const ext = name.lastIndexOf('.')
  if (ext > 0 && name.length - ext < 8) {
    const extStr = name.slice(ext)
    return name.slice(0, max - extStr.length - 2) + '…' + extStr
  }
  return name.slice(0, max - 1) + '…'
}

function formatSize(bytes: number): string {
  if (bytes < 1024) return bytes + ' B'
  if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB'
  return (bytes / (1024 * 1024)).toFixed(1) + ' MB'
}

function openLightbox(f: FileItem) {
  if (isImage(f.tipo || f.nombre_archivo)) {
    lightboxUrl.value = f.url
  } else {
    // Open non-image files in new tab
    window.open(f.url, '_blank')
  }
}
</script>

<style scoped>
.file-uploader {
  width: 100%;
}

.drop-zone {
  border: 2px dashed #cbd5e1;
  border-radius: 12px;
  padding: 24px 16px;
  text-align: center;
  cursor: pointer;
  transition: all 0.2s ease;
  background: linear-gradient(135deg, #f8fafc 0%, #f1f5f9 100%);
}
.drop-zone:hover {
  border-color: #0ea5a4;
  background: linear-gradient(135deg, #f0fdfa 0%, #e6fffa 100%);
}
.drop-zone--active {
  border-color: #0ea5a4;
  background: linear-gradient(135deg, #ccfbf1 0%, #e6fffa 100%);
  transform: scale(1.01);
}
.drop-zone--disabled {
  opacity: 0.5;
  cursor: not-allowed;
}

.drop-zone__content {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 6px;
}
.drop-zone__icon {
  font-size: 2rem;
  margin-bottom: 4px;
}
.drop-zone__text {
  color: #475569;
  font-size: 0.92rem;
}
.drop-zone__link {
  color: #0ea5a4;
  font-weight: 600;
  text-decoration: underline;
}
.drop-zone__hint {
  color: #94a3b8;
  font-size: 0.8rem;
}

/* Spinner */
.drop-zone__spinner {
  width: 28px;
  height: 28px;
  border: 3px solid #e2e8f0;
  border-top-color: #0ea5a4;
  border-radius: 50%;
  animation: spin 0.7s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }

/* Error */
.upload-error {
  margin-top: 8px;
  padding: 8px 12px;
  background: #fef2f2;
  border: 1px solid #fca5a5;
  border-radius: 8px;
  color: #b91c1c;
  font-size: 0.88rem;
}

/* File previews */
.file-previews {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(110px, 1fr));
  gap: 10px;
  margin-top: 12px;
}

.file-preview {
  position: relative;
  border: 1px solid #e2e8f0;
  border-radius: 10px;
  overflow: hidden;
  background: #fff;
  transition: box-shadow 0.15s ease;
}
.file-preview:hover {
  box-shadow: 0 4px 12px rgba(14, 165, 164, 0.12);
}

.file-preview__thumb {
  width: 100%;
  height: 80px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #f8fafc;
  cursor: pointer;
  overflow: hidden;
}
.file-preview__thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}
.file-preview__icon {
  font-size: 2rem;
}

.file-preview__info {
  padding: 6px 8px 4px;
}
.file-preview__name {
  font-size: 0.78rem;
  font-weight: 600;
  color: #334155;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.file-preview__size {
  font-size: 0.72rem;
  color: #94a3b8;
}

.file-preview__delete {
  position: absolute;
  top: 4px;
  right: 4px;
  width: 22px;
  height: 22px;
  border-radius: 50%;
  border: none;
  background: rgba(239, 68, 68, 0.85);
  color: white;
  font-size: 0.7rem;
  font-weight: 700;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  transition: opacity 0.15s;
}
.file-preview:hover .file-preview__delete {
  opacity: 1;
}

/* Lightbox */
.lightbox-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0, 0, 0, 0.8);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 100;
  padding: 24px;
  animation: fadeIn 0.2s ease;
}
@keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }

.lightbox-content {
  position: relative;
  max-width: 90vw;
  max-height: 90vh;
}
.lightbox-content img {
  max-width: 100%;
  max-height: 85vh;
  border-radius: 8px;
  box-shadow: 0 16px 48px rgba(0, 0, 0, 0.4);
}
.lightbox-close {
  position: absolute;
  top: -12px;
  right: -12px;
  width: 32px;
  height: 32px;
  border-radius: 50%;
  border: none;
  background: #fff;
  color: #111;
  font-size: 1rem;
  font-weight: 700;
  cursor: pointer;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.2);
}

/* Dark mode */
:is(.dark) .drop-zone {
  background: linear-gradient(135deg, #0f1729 0%, #111c2e 100%);
  border-color: #334155;
}
:is(.dark) .drop-zone:hover {
  border-color: #0ea5a4;
  background: linear-gradient(135deg, #0c2e2d 0%, #0f1729 100%);
}
:is(.dark) .drop-zone--active {
  border-color: #0ea5a4;
  background: linear-gradient(135deg, #0c3b3a 0%, #0f1729 100%);
}
:is(.dark) .drop-zone__text { color: #94a3b8; }
:is(.dark) .drop-zone__hint { color: #64748b; }
:is(.dark) .drop-zone__spinner { border-color: #334155; border-top-color: #0ea5a4; }

:is(.dark) .upload-error { background: #1a0505; border-color: #7f1d1d; color: #fca5a5; }

:is(.dark) .file-preview { background: #0f1729; border-color: #1e293b; }
:is(.dark) .file-preview:hover { box-shadow: 0 4px 12px rgba(14, 165, 164, 0.15); }
:is(.dark) .file-preview__thumb { background: #111c2e; }
:is(.dark) .file-preview__name { color: #e2e8f0; }
:is(.dark) .file-preview__size { color: #64748b; }

@media (max-width: 768px) {
  .file-previews {
    grid-template-columns: repeat(auto-fill, minmax(90px, 1fr));
    gap: 8px;
  }
  .file-preview__thumb { height: 65px; }
  .drop-zone { padding: 16px 12px; }
}
</style>
