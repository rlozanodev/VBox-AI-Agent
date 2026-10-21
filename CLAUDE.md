# CLAUDE.md — Guía Puente para Claude Code y Agentes de Terminal

Este archivo conecta a **Claude Code** (y cualquier agente compatible con `CLAUDE.md`) con la arquitectura de reglas agnósticas y las skills de este repositorio.

## 1. Importación de Contexto y Reglas Obligatorias

Lee y aplica siempre las directrices definidas en el archivo maestro y en las reglas modulares:

- **Contexto Maestro y Topología del Laboratorio**: @[AGENTS.md](./AGENTS.md)
- **Regla 01 (Host Windows y VirtualBox)**: @[.agent/rules/01-vbox-host-windows.md](./.agent/rules/01-vbox-host-windows.md)
- **Regla 02 (Idempotencia y Limpieza Zero-Footprint)**: @[.agent/rules/02-idempotencia-y-limpieza.md](./.agent/rules/02-idempotencia-y-limpieza.md)
- **Regla 03 (Pausas de Evidencia y Reportes)**: @[.agent/rules/03-evidencia-y-reportes.md](./.agent/rules/03-evidencia-y-reportes.md)

## 2. Skills Disponibles en el Repositorio

Consulta la documentación detallada de cada skill según la tarea solicitada:

1. **`vbox-controller`**: [`SKILL.md`](./.agent/skills/vbox-controller/SKILL.md) — Control de VMs (`Kali-Linux-CLI` y `ubuntuServer`), red NAT `cetipracticas` y snapshots.
2. **`kali-bridge`**: [`SKILL.md`](./.agent/skills/kali-bridge/SKILL.md) — Ejecución remota y transferencia de scripts/evidencias entre Windows y Kali Linux.
3. **`lab-state-manager`**: [`SKILL.md`](./.agent/skills/lab-state-manager/SKILL.md) — Gestión idempotente de `/etc/hosts`, montajes NFS/SMB en `/mnt/`, permisos `chmod 600` de llaves SSH y túneles locales (`127.0.0.1:5000`).
4. **`report-generator`**: [`SKILL.md`](./.agent/skills/report-generator/SKILL.md) — Generación de reportes estandarizados en `docs/practicas/` y scripts con pausas `read -p`.

## 3. Referencia Rápida de Comandos (Host Windows - PowerShell)

```powershell
# Verificar estado de VMs (Kali-Linux-CLI, ubuntuServer) y red NAT cetipracticas
powershell -ExecutionPolicy Bypass -File .\scripts\vbox-controller.ps1 -Action status

# Iniciar laboratorio completo (ubuntuServer en headless, Kali-Linux-CLI en GUI)
powershell -ExecutionPolicy Bypass -File .\scripts\vbox-controller.ps1 -Action start -VM all

# Guardar estado (savestate) o detener (stop) VMs
powershell -ExecutionPolicy Bypass -File .\scripts\vbox-controller.ps1 -Action savestate -VM all

# Crear snapshot de seguridad antes de una práctica
powershell -ExecutionPolicy Bypass -File .\scripts\vbox-controller.ps1 -Action snapshot-take -VM ubuntuServer -SnapshotName "pre-practica"

# Configurar puente SSH (127.0.0.1:2222 -> 192.168.1.4:22) y carpeta compartida con Kali
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action setup

# Generar un nuevo reporte de práctica y su script interactivo .sh
powershell -ExecutionPolicy Bypass -File .\scripts\new-practice-report.ps1 -Number "01" -Title "Nombre de la Practica" -CreateScript
```

## 4. Referencia Rápida de Comandos (En Kali Linux - Bash)

```bash
# Inicializar /etc/hosts (cetilab.local y 11 subdominios) de forma idempotente
sudo ./scripts/kali-lab-state.sh init

# Revisar estado de conectividad, /etc/hosts, montajes /mnt y túneles
./scripts/kali-lab-state.sh status

# Limpiar todo el entorno (desmontar /mnt, cerrar túnel 5000, limpiar /etc/hosts)
sudo ./scripts/kali-lab-state.sh cleanup
```
