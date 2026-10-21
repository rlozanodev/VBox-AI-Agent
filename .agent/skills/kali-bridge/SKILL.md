---
name: kali-bridge
description: >-
  Establece el puente de comunicación, ejecución remota y transferencia de
  archivos entre el host Windows y la máquina virtual Kali-Linux-CLI. Úsese
  cuando se requiera enviar scripts de prácticas, ejecutar comandos en Kali
  Linux desde Windows (vía SSH con Port-Forwarding NAT o VBoxManage
  guestcontrol/sharedfolder) y recolectar salidas de terminal o evidencias de
  vuelta al repositorio local.
---

# Skill: Kali Bridge (`kali-bridge`)

Esta skill gestiona el canal de comunicación bidireccional entre el host Windows (`D:\Orchestrator\VBox-AI-Agent`) y la máquina virtual atacante `Kali-Linux-CLI` (`192.168.1.4`) mediante el script [`scripts/kali-bridge.ps1`](../../../scripts/kali-bridge.ps1).

## Mecanismos de Transporte Soportados

Dado que `Kali-Linux-CLI` opera dentro de la red NAT `cetipracticas` (`192.168.1.0/24`), el puente soporta tres métodos complementarios para comunicarse desde el host Windows:

1. **SSH vía Port-Forwarding en Red NAT `cetipracticas` (Recomendado)**:
   - Configura una regla de reenvío de puertos en la red NAT `cetipracticas` desde `127.0.0.1:2222` (Host Windows) hacia `192.168.1.4:22` (Kali Linux).
   - Permite usar `ssh` y `scp` nativos de Windows (`OpenSSH Client`) con baja latencia y soporte completo de streams.
2. **Carpetas Compartidas de VirtualBox (`sharedfolder`)**:
   - Monta el directorio local `workspace/` del repositorio dentro de Kali Linux (`/mnt/vbox_workspace` o `/media/sf_vbox_workspace`) para sincronizar scripts (`scripts/kali-lab-state.sh`) y recolectar evidencias y logs automáticamente.
3. **`VBoxManage guestcontrol`**:
   - Permite ejecutar comandos directos dentro de `Kali-Linux-CLI` a través de VirtualBox Guest Additions sin depender del estado de la red:
     ```powershell
     & "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" guestcontrol "Kali-Linux-CLI" run --exe "/bin/bash" --username "kali" --password "<password>" -- -c "ip a"
     ```

## Uso de `scripts/kali-bridge.ps1`

### 1. Configurar Regla de Port-Forwarding SSH y Carpeta Compartida (`setup`)
Configura en `cetipracticas` la regla TCP `kali-ssh` (`127.0.0.1:2222 -> 192.168.1.4:22`) y registra la carpeta compartida `vbox_workspace`:
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action setup
```

### 2. Verificar Conectividad con Kali (`ping` / `test-ssh`)
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action test
```

### 3. Ejecutar un Comando Remoto en Kali (`exec`)
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action exec -Command "hostname -I && nmap --version"
```

### 4. Enviar un Script Local a Kali (`push`) y Recolectar Evidencias (`pull`)
```powershell
# Enviar el gestor de estado del laboratorio a Kali
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action push -LocalPath ".\scripts\kali-lab-state.sh" -RemotePath "/home/kali/kali-lab-state.sh"

# Traer logs o capturas desde Kali hacia docs/practicas/evidencias/
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action pull -RemotePath "/home/kali/evidencias/*" -LocalPath ".\docs\practicas\evidencias\"
```

## Pasos de Validación
1. Ejecutar `-Action test` para verificar si el puerto `127.0.0.1:2222` responde o si Guest Additions se encuentra activo.
2. Si el servicio `ssh` dentro de Kali está detenido, iniciarlo una vez desde la GUI de Kali con `sudo systemctl enable --now ssh`.
