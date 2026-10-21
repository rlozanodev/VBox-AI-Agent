---
name: report-generator
description: >-
  Estandariza y genera la documentación de las prácticas de ciberseguridad en
  archivos Markdown dentro de docs/practicas/, así como scripts de práctica con
  pausas interactivas (read -p) para toma de capturas de pantalla. Úsese cuando
  el usuario pida documentar una práctica, generar un reporte técnico o crear
  un nuevo flujo de evaluación paso a paso.
---

# Skill: Report Generator (`report-generator`)

Esta skill implementa la [Regla 03 (Evidencia y Reportes)](../../rules/03-evidencia-y-reportes.md), estandarizando la creación de reportes académicos y técnicos en `docs/practicas/` mediante la plantilla base [`docs/practicas/_template.md`](../../../docs/practicas/_template.md) y el generador [`scripts/new-practice-report.ps1`](../../../scripts/new-practice-report.ps1).

## Estructura Estándar de un Reporte en `docs/practicas/`

Todo documento generado dentro de `docs/practicas/practica-XX-<slug>.md` debe contener las siguientes secciones obligatorias:

1. **Ficha Técnica y Metadatos**:
   - ID y Título de la Práctica, Fecha, Autor.
   - Entorno Origen (`Kali-Linux-CLI` - `192.168.1.4`) y Entorno Destino (`ubuntuServer` - `192.168.1.101` / `cetilab.local`).
   - Servicios / Puertos Auditados y Herramientas empleadas.
2. **Objetivos**:
   - Objetivo general y objetivos específicos medibles.
3. **Preparación Idempotente del Entorno**:
   - Comandos de verificación de estado de VMs (`vbox-controller`) y preparación en Kali (`kali-lab-state.sh init`).
4. **Ejecución Técnica y Evidencias Paso a Paso**:
   - Por cada paso numerado (`Paso 1`, `Paso 2`, ...):
     - **Descripción técnica** de la acción.
     - **Comando ejecutado** (bloque `bash`).
     - **Resultado esperado / obtenido** (bloque `text` con los hallazgos clave).
     - **Espacio de Evidencia**:
       ```markdown
       > 📸 **[Espacio para Captura de Pantalla #01: Descripción exacta de lo que debe verse en la imagen]**
       > ![Evidencia 01](./evidencias/practica-XX/evidencia-01.png)
       ```
5. **Procedimiento de Limpieza y Reversión (Rollback)**:
   - Comandos ejecutados para desmontar recursos, cerrar túneles y limpiar `/etc/hosts` (`sudo ./scripts/kali-lab-state.sh cleanup`).
6. **Hallazgos y Recomendaciones de Remediación**:
   - Tabla resumen de vulnerabilidades/configuraciones débiles detectadas y cómo mitigarlas en `ubuntuServer`.

## Uso del Generador de Reportes (`scripts/new-practice-report.ps1`)

Para inicializar el documento Markdown de una nueva práctica y su carpeta de evidencias asociada (más un esqueleto opcional de script interactivo `.sh` con pausas `read -p`):

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\new-practice-report.ps1 `
  -Number "01" `
  -Title "Reconocimiento DNS y Enumeracion de Subdominios en cetilab.local" `
  -Services "DNS (53/TCP-UDP), HTTP (80/TCP, 8080/TCP)" `
  -Tools "Nmap, Dig, Gobuster" `
  -CreateScript
```

Esto creará automáticamente:
- `docs/practicas/practica-01-reconocimiento-dns-y-enumeracion-de-subdominios-en-cetilab-local.md`
- `docs/practicas/evidencias/practica-01/`
- `scripts/practicas/practica-01.sh` (con función `pause_evidence` integrada con `read -p` y hook de limpieza).
