# CLAUDE.md — Guía Puente para Claude Code y Agentes de Terminal

Este archivo conecta a **Claude Code**, **Antigravity CLI** y modelos rápidos (como **Gemini 3.8 Flash**) con la arquitectura de reglas agnósticas, las skills y el **Modo Copiloto Interactivo para Examen Práctico**.

---

## 1. Importación de Contexto y Reglas Obligatorias

Lee y aplica siempre las directrices definidas en el archivo maestro y en las reglas modulares:

- **Contexto Maestro y Protocolo de Examen**: @[AGENTS.md](./AGENTS.md)
- **Regla 01 (Host Windows y VirtualBox)**: @[.agent/rules/01-vbox-host-windows.md](./.agent/rules/01-vbox-host-windows.md)
- **Regla 02 (Idempotencia y Limpieza Zero-Footprint)**: @[.agent/rules/02-idempotencia-y-limpieza.md](./.agent/rules/02-idempotencia-y-limpieza.md)
- **Regla 03 (Sanitización, Evidencias, vm-snap y build-report)**: @[.agent/rules/03-evidencia-y-reportes.md](./.agent/rules/03-evidencia-y-reportes.md)
- **Regla 04 (Protocolo Copiloto Interactivo - Examen a Ciegas)**: @[.agent/rules/04-modo-examen-interactivo.md](./.agent/rules/04-modo-examen-interactivo.md)
- **Regla 05 (Playbook kali-bridge para Modelos Rápidos)**: @[.agent/rules/05-guia-operativa-modelos-rapidos.md](./.agent/rules/05-guia-operativa-modelos-rapidos.md)

---

## 2. Regla Estricta de Sanitización de Identidad (Obligatoria)

- **Sanitización Global**: En toda configuración, reporte, script o evidencia, cualquier nombre o alias similar a `eduardo`, `lalo`, `nuño`, `Eduma15` o `jorge` debe reemplazarse obligatoriamente por **`lozan`** o **`lozano`**.
- Autor oficial: **Roberto Lozano**.

---

## 3. Modo Copiloto Interactivo de Examen (Ciclo Human-in-the-Loop)

Durante el examen práctico, no se asume ninguna IP ni configuración fija. Operamos en ciclos cortos:
1. **Paso A**: Propuesta unitaria de comando y objetivo analítico.
2. **Paso B**: Lectura minuciosa y razonamiento de la salida entregada por el usuario.
3. **Paso C**: Actualización inmediata de `docs/examen_practico/notas_hallazgos.md`.
4. **Paso D**: Captura con `vm-snap.ps1` en `docs/examen_practico/assets/` y redacción de `docs/examen_practico/REPORTE_EXAMEN_LOZANO.md`.

---

## 4. Skills Disponibles en el Repositorio

1. **`vbox-controller`**: [`SKILL.md`](./.agent/skills/vbox-controller/SKILL.md) — Control de VMs en VirtualBox y red NAT.
2. **`kali-bridge`**: [`SKILL.md`](./.agent/skills/kali-bridge/SKILL.md) — Ejecución remota en Kali (`exec`), carpeta compartida `/home/kali/repo` y puente hacia el target.
3. **`lab-state-manager`**: [`SKILL.md`](./.agent/skills/lab-state-manager/SKILL.md) — Gestión idempotente de resoluciones, montajes y túneles.
4. **`report-generator`**: [`SKILL.md`](./.agent/skills/report-generator/SKILL.md) — Estandarización de reportes y evidencias Markdown.

---

## 5. Comandos Rápidos del Laboratorio (PowerShell en Windows)

```powershell
# 1. Auditar VMs registradas en VirtualBox
powershell -ExecutionPolicy Bypass -File .\scripts\vbox-controller.ps1 -Action list
powershell -ExecutionPolicy Bypass -File .\scripts\vbox-controller.ps1 -Action status

# 2. Verificar estado del puente SSH hacia Kali
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action status

# 3. Ejecutar comando en Kali-Linux-CLI (como usuario kali o como root con -AsRoot)
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action exec -Command "hostname -I && ip route"
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action exec -AsRoot -Command "cat /etc/hosts"

# 4. Captura de Framebuffer VirtualBox (Guardar en docs/examen_practico/assets/)
powershell -ExecutionPolicy Bypass -File .\scripts\vm-snap.ps1 -VmName "Kali-Linux-CLI" -OutputPath "docs/examen_practico/assets/01_red.png"

# 5. Compilar reporte Markdown a DOCX local
powershell -ExecutionPolicy Bypass -File .\scripts\build-report.ps1 -InputFile "docs/examen_practico/REPORTE_EXAMEN_LOZANO.md" -OutputFile "docs/examen_practico/Reporte_Examen_Lozano.docx" -SkipUpload
```
