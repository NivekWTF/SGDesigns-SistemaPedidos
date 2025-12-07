# 🖨️ Sistema de Gestión de Pedidos para SG Designs  
### Desarrollado con Vue 3 + Supabase

Este proyecto es una aplicación web diseñada para gestionar los pedidos de una imprenta de manera eficiente.  
Permite registrar clientes, crear pedidos, controlar la producción, almacenar archivos de diseño y generar reportes clave para el negocio.

---

# 🚀 Tecnologías utilizadas

### **Frontend**
- Vue 3 + TypeScript  
- Vite  
- Pinia (estado global)  
- Vue Router  
- TailwindCSS o MUI (opcional)

### **Backend / Servicios (Supabase)**
- PostgreSQL (base de datos)  
- Supabase Auth (autenticación con email/contraseña o proveedores)  
- Supabase Storage (subida de archivos)  
- Realtime (actualización en vivo de los pedidos)  
- SQL Editor para consultas y minería de datos  

---

# 📦 Estructura del proyecto

src/
components/
layouts/
pages/
auth/
pedidos/
clientes/
stores/
lib/
supabase.ts
utils/
public/
.env.local
README.md


🧩 Arquitectura del sistema
mermaid
Copiar código
flowchart LR
  A[Vue 3 App] -->|Auth / DB / Storage| B(Supabase)
  B --> C[PostgreSQL]
  B --> D[Storage - Diseños]
  B --> E[Auth - Usuarios]
  B --> F[Realtime - Cambios]
👨‍💻 Autor
Proyecto desarrollado por [Tu Nombre]
Imprenta • Diseño • Desarrollo Web

📄 Licencia
Proyecto privado. No distribuir sin autorización.