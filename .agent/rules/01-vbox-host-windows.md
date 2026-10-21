# Regla 01: Operación de VirtualBox en Host Windows

Esta regla rige todas las interacciones del agente con el hipervisor Oracle VirtualBox desde el sistema operativo anfitrión Windows (PowerShell / CMD).

## 1. Resolución de Ruta de `VBoxManage.exe`
- En Windows, `VBoxManage.exe` no siempre está expuesto en la variable de entorno `PATH`.
- **Ruta estándar obligatoria**: `"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"`.
- Antes de invocar cualquier comando de VirtualBox en PowerShell, verifica o asigna la ruta en una variable:
  ```powershell
  $VBoxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
  if (-not (Test-Path $VBoxManage)) {
      $cmd = Get-Command VBoxManage.exe -ErrorAction SilentlyContinue
      if ($cmd) { $VBoxManage = $cmd.Source } else { throw "VBoxManage.exe no encontrado." }
  }
  ```
- Utiliza siempre el operador de invocación `& $VBoxManage` y encierra entre comillas dobles los nombres de máquinas virtuales, rutas de archivos y nombres de snapshots.

## 2. Identificadores Oficiales de Máquinas Virtuales
- **Máquina Atacante / Orquestadora**: `"Kali-Linux-CLI"` (UUID: `930ba4aa-afd4-4414-a2a9-b03b76bdc62c`)
- **Máquina Objetivo (Target)**: `"ubuntuServer"` (UUID: `9f4e173c-8db8-4fe4-b215-72cb0988112a`)

## 3. Verificación Previa de Estado y Red NAT
Antes de iniciar cualquier práctica o envío de comandos:
1. **Verificar estado de ejecución**:
   - Ejecutar `& $VBoxManage list runningvms` o inspeccionar `VMState` con `& $VBoxManage showvminfo "<VM>" --machinereadable`.
   - No intentar iniciar una VM que ya se encuentre en estado `running`.
   - Si una VM está en estado `saved` o `paused`, documentarlo y reanudarla apropiadamente.
2. **Verificar Red NAT `cetipracticas`**:
   - Comprobar que la red NAT `cetipracticas` (`192.168.1.0/24`) exista y tenga el servidor DHCP activo mediante `& $VBoxManage list natnets`.
   - Ambas VMs deben mantener su `nic1` conectado a `natnetwork` con `nat-network1="cetipracticas"`.

## 4. Políticas de Arranque y Apagado de VMs
- **Kali Linux (`Kali-Linux-CLI`)**: Debe iniciarse de forma predeterminada en modo gráfico (`--type gui`) para permitir el uso de herramientas interactivas (Burp Suite, navegador con FoxyProxy, capturas de evidencia visual).
- **Ubuntu Server (`ubuntuServer`)**: Debe iniciarse de forma predeterminada en segundo plano (`--type headless`) para optimizar el consumo de recursos en el host Windows.
- **Apagado seguro**: Preferir `controlvm "<VM>" acpipowerbutton` o `savestate` antes de recurrir a `poweroff` forzado, evitando corrupción de sistemas de archivos en las VMs.

## 5. Gestión Obligatoria de Snapshots
- **Antes de alteraciones críticas**: Antes de modificar configuraciones del servidor objetivo, explotar servicios que alteren estado persistente o actualizar paquetes del laboratorio, crear un snapshot con nomenclatura estandarizada:
  ```powershell
  & $VBoxManage snapshot "<VM>" take "pre-<nombre-practica>-$(Get-Date -Format 'yyyyMMdd-HHmm')" --description "Snapshot previo a la practica"
  ```
- **Restauración limpia**: Si una práctica corrompe el estado del servicio objetivo, apagar la VM y restaurar el snapshot previo (`snapshot "<VM>" restorecurrent` o `restore "<NombreSnapshot>"`).
