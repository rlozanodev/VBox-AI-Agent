# CLAUDE.md — Guía Puente para Claude Code y Agentes de Terminal

Este archivo conecta a **Claude Code**, **Antigravity CLI** y modelos ligeros (como **Gemini 3.8 Flash**) con la arquitectura de reglas agnósticas y las skills de este repositorio.

## 1. Importación de Contexto y Reglas Obligatorias

Lee y aplica siempre las directrices definidas en el archivo maestro y en las reglas modulares:

- **Contexto Maestro y Topología del Laboratorio**: @[AGENTS.md](./AGENTS.md)
- **Regla 01 (Host Windows y VirtualBox)**: @[.agent/rules/01-vbox-host-windows.md](./.agent/rules/01-vbox-host-windows.md)
- **Regla 02 (Idempotencia y Limpieza Zero-Footprint)**: @[.agent/rules/02-idempotencia-y-limpieza.md](./.agent/rules/02-idempotencia-y-limpieza.md)
- **Regla 03 (Pausas de Evidencia y Reportes)**: @[.agent/rules/03-evidencia-y-reportes.md](./.agent/rules/03-evidencia-y-reportes.md)
- **Regla 04 (Playbook para Modelos Rápidos - Gemini 3.8 Flash)**: @[.agent/rules/04-guia-operativa-modelos-rapidos.md](./.agent/rules/04-guia-operativa-modelos-rapidos.md)

## 2. Skills Disponibles en el Repositorio

1. **`vbox-controller`**: [`SKILL.md`](./.agent/skills/vbox-controller/SKILL.md) — Control de VMs (`Kali-Linux-CLI` y `ubuntuServer`), red NAT `cetipracticas` y snapshots.
2. **`kali-bridge`**: [`SKILL.md`](./.agent/skills/kali-bridge/SKILL.md) — Ejecución remota en Kali (`exec`), salto directo a `ubuntuServer` (`exec-target`), carpeta compartida `/home/kali/repo` y transferencia de archivos.
3. **`lab-state-manager`**: [`SKILL.md`](./.agent/skills/lab-state-manager/SKILL.md) — Gestión idempotente de `/etc/hosts`, montajes NFS/SMB en `/mnt/`, permisos `chmod 600` de llaves SSH y túneles locales (`127.0.0.1:5000`).
4. **`report-generator`**: [`SKILL.md`](./.agent/skills/report-generator/SKILL.md) — Generación de reportes estandarizados en `docs/practicas/` y scripts con pausas `read -p`.

## 3. Comandos Rápidos del Puente (Host Windows - PowerShell)

```powershell
# 1. Verificar estado de las VMs y del puente hacia Kali + ubuntuServer
powershell -ExecutionPolicy Bypass -File .\scripts\vbox-controller.ps1 -Action status
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action status

# 2. Ejecutar comando en Kali-Linux-CLI (como usuario kali o como root con -AsRoot)
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action exec -Command "hostname -I && ls -la /home/kali"
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action exec -AsRoot -Command "cat /etc/hosts"

# 3. Ejecutar comando directamente en el Target ubuntuServer (192.168.1.101) vía salto SSH
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action exec-target -Command "id && hostname && ss -tln"

# 4. Reparar/Inicializar el puente si se reiniciaron las VMs
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action bootstrap
```
