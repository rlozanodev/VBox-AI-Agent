---
name: kali-bridge
description: >-
  Establece el puente de comunicación autónomo entre el host Windows, la
  máquina virtual Kali-Linux-CLI y el servidor objetivo ubuntuServer
  (192.168.1.101). Úsese siempre para ejecutar comandos en Kali (como kali o
  root), saltar por SSH al target ubuntuServer, sincronizar el repositorio en
  /home/kali/repo o transferir archivos y evidencias.
---

# Skill: Kali Bridge (`kali-bridge`)

Esta skill gestiona el puente bidireccional entre el host Windows (`D:\Orchestrator\VBox-AI-Agent`), la VM atacante `Kali-Linux-CLI` y la VM objetivo `ubuntuServer` (`192.168.1.101`) mediante [`scripts/kali-bridge.ps1`](../../../scripts/kali-bridge.ps1).

## Ventajas Técnicas del Puente

1. **Detección Dinámica de IP**: Obtiene en vivo la IP de `Kali-Linux-CLI` desde VirtualBox Guest Additions (`/VirtualBox/GuestInfo/Net/0/V4/IP`), sin importar qué IP le asigne el DHCP de `cetipracticas`.
2. **Envoltura Base64 UTF-8**: Todo comando pasado en `-Command` se normaliza a `LF` y se codifica en Base64 antes de enviarse a `/bin/bash`. Esto elimina por completo errores de comillas, `$variables`, tuberías (`|`) o redirecciones (`>`) entre PowerShell y Bash.
3. **Doble Transporte (`guestcontrol` + `ssh`)**:
   - Canal primario: `VBoxManage guestcontrol` (funciona incluso sin red).
   - Canal secundario: `SSH` por Port-Forwarding NAT (`127.0.0.1:2222 -> <KALI_IP>:22`) con llave Ed25519 sin contraseña (`workspace/.ssh/kali_agent_ed25519`).
4. **Carpeta Compartida en Vivo (`/home/kali/repo`)**:
   - El repositorio `D:\Orchestrator\VBox-AI-Agent` está montado en `/mnt/vbox_repo` y enlazado en `/home/kali/repo`. Todo script creado en `scripts/practicas/` está disponible al instante en la terminal de Kali.

## Comandos Principales

### 1. Verificar Estado del Puente (`status`)
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action status
```

### 2. Inicializar o Reparar el Puente (`bootstrap`)
Configura `sudo NOPASSWD`, activa `ssh` en Kali, inyecta llaves SSH, actualiza el Port-Forwarding y monta `/home/kali/repo`:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action bootstrap
```

### 3. Ejecutar Comandos en Kali (`exec`)
```powershell
# Como usuario kali
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action exec -Command "id && hostname -I"

# Como root (sudo -n sin contraseña)
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action exec -AsRoot -Command "cat /etc/hosts"

# Usando explícitamente el transporte SSH (127.0.0.1:2222)
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action exec -Transport ssh -Command "uname -a"
```

### 4. Ejecutar Comandos Directamente en `ubuntuServer` (`exec-target`)
```powershell
# Con llave SSH por defecto (/home/kali/developer.key -> developer@192.168.1.101)
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action exec-target -Command "id && hostname && ss -tln"

# Con otro usuario y contraseña (vía sshpass desde Kali)
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action exec-target -TargetUser "ftpuser" -TargetPassword "<PASSWORD>" -Command "id && pwd"
```

### 5. Transferir Archivos (`push` / `pull`)
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action push -LocalPath ".\scripts\kali-lab-state.sh" -RemotePath "/home/kali/kali-lab-state.sh"
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action pull -RemotePath "/home/kali/hash_practica6.txt" -LocalPath ".\workspace\"
```
