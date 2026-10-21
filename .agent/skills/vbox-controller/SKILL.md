---
name: vbox-controller
description: >-
  Controla y administra las máquinas virtuales de Oracle VirtualBox desde el
  host Windows. Úsese cuando el usuario o el agente necesiten verificar el
  estado de las VMs (Kali-Linux-CLI y ubuntuServer), auditar la red NAT
  cetipracticas, iniciar o apagar máquinas virtuales (GUI para Kali, Headless
  para Ubuntu Server) o gestionar snapshots de seguridad antes y después de las
  prácticas.
---

# Skill: VirtualBox Controller (`vbox-controller`)

Esta skill proporciona los procedimientos estandarizados y el script de automatización en PowerShell ([`vbox-controller.ps1`](../../../scripts/vbox-controller.ps1)) para orquestar el hipervisor Oracle VirtualBox en el host Windows conforme a la [Regla 01](../../rules/01-vbox-host-windows.md).

## Activos Controlados

| Rol | Nombre VM | UUID | Modo de Inicio | Red NAT |
| :--- | :--- | :--- | :--- | :--- |
| **Atacante / Orquestador** | `Kali-Linux-CLI` | `930ba4aa-afd4-4414-a2a9-b03b76bdc62c` | `gui` | `cetipracticas` (`192.168.1.0/24`) |
| **Objetivo (Target)** | `ubuntuServer` | `9f4e173c-8db8-4fe4-b215-72cb0988112a` | `headless` | `cetipracticas` (`192.168.1.0/24`) |

## Uso del Script de Orquestación

Ejecuta [`scripts/vbox-controller.ps1`](../../../scripts/vbox-controller.ps1) desde PowerShell en la raíz del proyecto:

### 1. Diagnóstico General del Laboratorio (`status`)
Verifica versión de VirtualBox, estado de cada VM (`running`, `saved`, `poweroff`), configuración de NICs, red NAT `cetipracticas` y lista de snapshots:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\vbox-controller.ps1 -Action status
```

### 2. Iniciar el Laboratorio (`start`)
Inicia `ubuntuServer` en modo `headless` y `Kali-Linux-CLI` en modo `gui` (o una VM específica con `-VM`):
```powershell
# Iniciar todo el laboratorio
powershell -ExecutionPolicy Bypass -File .\scripts\vbox-controller.ps1 -Action start -VM all

# Iniciar únicamente Ubuntu Server en modo headless
powershell -ExecutionPolicy Bypass -File .\scripts\vbox-controller.ps1 -Action start -VM ubuntuServer
```

### 3. Apagar o Suspender VMs (`stop` / `savestate`)
```powershell
# Guardar estado de las VMs activas
powershell -ExecutionPolicy Bypass -File .\scripts\vbox-controller.ps1 -Action savestate -VM all

# Apagado ACPI ordenado
powershell -ExecutionPolicy Bypass -File .\scripts\vbox-controller.ps1 -Action stop -VM all
```

### 4. Gestión de Snapshots de Seguridad (`snapshot-take` / `snapshot-restore` / `snapshot-list`)
Antes de ejecutar cambios destructivos o explotaciones que modifiquen el servidor objetivo:
```powershell
# Crear snapshot previo a una práctica
powershell -ExecutionPolicy Bypass -File .\scripts\vbox-controller.ps1 -Action snapshot-take -VM ubuntuServer -SnapshotName "pre-practica-01"

# Listar snapshots existentes
powershell -ExecutionPolicy Bypass -File .\scripts\vbox-controller.ps1 -Action snapshot-list -VM all

# Restaurar snapshot (apaga la VM de forma segura si está encendida y restaura)
powershell -ExecutionPolicy Bypass -File .\scripts\vbox-controller.ps1 -Action snapshot-restore -VM ubuntuServer -SnapshotName "pre-practica-01"
```

## Pasos de Validación
1. Ejecutar `-Action status` tras cualquier operación de encendido, apagado o snapshot.
2. Confirmar que `nat-network1="cetipracticas"` y `DHCP Server: Yes` permanecen activos en `192.168.1.0/24`.
