---
name: save-context
description: >
  Guarda un snapshot completo del contexto del proyecto cuando se acaban los tokens
  o al final de una sesión larga. Genera un archivo PROJECT_CONTEXT.md con la arquitectura,
  estado actual, tareas pendientes, y decisiones tomadas para que la siguiente conversación
  pueda retomar sin perder el hilo. Actívalo diciendo "guarda el contexto" o "save context".
---

# Skill: Guardar Contexto del Proyecto

## Cuándo Activar

Esta skill se activa cuando:
- El usuario dice "guarda el contexto", "save context", "guarda el estado", "snapshot"
- Se detecta que la conversación ha sido larga y podría perder contexto
- El usuario quiere terminar una sesión y continuar después

## Qué Debe Hacer

Genera un archivo `PROJECT_CONTEXT.md` en la raíz del workspace con un snapshot completo del proyecto. Este archivo sirve como "memoria persistente" entre conversaciones.

### Pasos

1. **Analizar el proyecto actual**: Lee la estructura del proyecto, archivos clave, y configuración
2. **Documentar la arquitectura**: Stack tecnológico, estructura de directorios, dependencias principales
3. **Capturar el estado actual**: Qué funciona, qué está en progreso, qué está pendiente
4. **Registrar decisiones tomadas**: Decisiones de diseño, tradeoffs, y razones detrás de ellas
5. **Listar tareas pendientes**: Lo que falta por hacer, ordenado por prioridad
6. **Notas de implementación**: Detalles técnicos que serían difíciles de redescubrir

### Formato del Archivo

```markdown
# 🧠 Contexto del Proyecto — [Nombre del Proyecto]

> Última actualización: [fecha y hora]
> Conversación: [breve descripción de lo que se hizo]

## Stack Tecnológico
[Tecnologías usadas, versiones relevantes]

## Arquitectura
[Estructura del proyecto, módulos principales, flujo de datos]

## Estado Actual
### ✅ Completado
[Lista de lo que ya funciona]

### 🔄 En Progreso
[Lo que se estaba trabajando]

### 📋 Pendiente
[Lista priorizada de tareas futuras]

## Decisiones de Diseño
[Decisiones importantes y sus razones]

## Archivos Clave
[Tabla con los archivos más importantes y qué hace cada uno]

## Variables de Entorno
[Todas las variables configurables y sus propósitos]

## Notas Técnicas
[Gotchas, workarounds, y cosas que hay que recordar]

## Cómo Continuar
[Instrucciones claras para la siguiente sesión]
```

### Reglas

- **Siempre sobrescribe** el archivo existente con la versión más actualizada
- **Sé específico**: Incluye nombres de archivos, líneas de código, y rutas exactas
- **No seas genérico**: Documenta lo específico de ESTE proyecto, no consejos generales
- **Incluye snippets**: Si hay patrones de código importantes, inclúyelos
- **Marca prioridades**: Usa 🔴 (urgente), 🟡 (importante), 🟢 (nice-to-have) para tareas
