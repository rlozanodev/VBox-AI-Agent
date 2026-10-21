<#
.SYNOPSIS
    Puente de comunicación y transferencia entre el Host Windows y Kali-Linux-CLI.
.DESCRIPTION
    Configura Port-Forwarding SSH en la red NAT 'cetipracticas' (127.0.0.1:2222 -> 192.168.1.4:22),
    administra carpetas compartidas y ejecuta comandos o transfiere archivos vía SSH/SCP o GuestControl.
#>
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("setup", "test", "exec", "push", "pull")]
    [string]$Action = "test",

    [Parameter(Mandatory = $false)]
    [string]$Command = "hostname -I && uname -a",

    [Parameter(Mandatory = $false)]
    [string]$LocalPath = "",

    [Parameter(Mandatory = $false)]
    [string]$RemotePath = "",

    [Parameter(Mandatory = $false)]
    [string]$KaliUser = "kali",

    [Parameter(Mandatory = $false)]
    [string]$KaliIP = "192.168.1.4",

    [Parameter(Mandatory = $false)]
    [int]$HostSSHPort = 2222
)

$ErrorActionPreference = "Stop"
$VBoxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$NatNetName = "cetipracticas"
$KaliVMName = "Kali-Linux-CLI"
$WorkspaceDir = Join-Path (Split-Path -Parent $PSScriptRoot) "workspace"

$SSHOpts = @(
    "-o", "StrictHostKeyChecking=no",
    "-o", "UserKnownHostsFile=/dev/null",
    "-o", "ConnectTimeout=5",
    "-p", "$HostSSHPort"
)

switch ($Action) {
    "setup" {
        Write-Host "[+] Asegurando directorio local compartido: $WorkspaceDir" -ForegroundColor Cyan
        if (-not (Test-Path $WorkspaceDir)) {
            New-Item -ItemType Directory -Path $WorkspaceDir | Out-Null
        }

        Write-Host "[+] Configurando regla Port-Forwarding TCP 'kali-ssh' en red NAT '$NatNetName' (127.0.0.1:$HostSSHPort -> ${KaliIP}:22)..." -ForegroundColor Cyan
        # Eliminar regla previa si existe para mantener idempotencia
        & $VBoxManage natnetwork modify --netname $NatNetName --port-forward-4 delete "kali-ssh" 2>$null
        & $VBoxManage natnetwork modify --netname $NatNetName --port-forward-4 "kali-ssh:tcp:[127.0.0.1]:${HostSSHPort}:[${KaliIP}]:22"

        Write-Host "[+] Configurando carpeta compartida 'vbox_workspace' en '$KaliVMName'..." -ForegroundColor Cyan
        $state = (& $VBoxManage showvminfo $KaliVMName --machinereadable | Select-String '^VMState="(.+)"$').Matches[0].Groups[1].Value
        if ($state -eq "running") {
            & $VBoxManage sharedfolder remove $KaliVMName --name "vbox_workspace" --transient 2>$null
            & $VBoxManage sharedfolder add $KaliVMName --name "vbox_workspace" --hostpath $WorkspaceDir --automount --transient
        } elseif ($state -eq "poweroff") {
            & $VBoxManage sharedfolder remove $KaliVMName --name "vbox_workspace" 2>$null
            & $VBoxManage sharedfolder add $KaliVMName --name "vbox_workspace" --hostpath $WorkspaceDir --automount
        } else {
            Write-Host "[!] La VM '$KaliVMName' está en estado '$state'. La carpeta compartida permanente se registrará cuando esté en 'poweroff' o 'running'." -ForegroundColor Yellow
        }

        Write-Host "[OK] Configuración del puente completada." -ForegroundColor Green
    }

    "test" {
        Write-Host "[*] Verificando estado de '$KaliVMName'..." -ForegroundColor Cyan
        $info = & $VBoxManage showvminfo $KaliVMName --machinereadable
        $state = ($info | Select-String '^VMState="(.+)"$').Matches[0].Groups[1].Value
        Write-Host "    Estado VM: $state"

        Write-Host "[*] Probando socket local SSH 127.0.0.1:$HostSSHPort..." -ForegroundColor Cyan
        $tcp = Test-NetConnection -ComputerName 127.0.0.1 -Port $HostSSHPort -WarningAction SilentlyContinue
        if ($tcp.TcpTestSucceeded) {
            Write-Host "[OK] Puerto 127.0.0.1:$HostSSHPort abierto y alcanzable." -ForegroundColor Green
        } else {
            Write-Host "[!] El puerto 127.0.0.1:$HostSSHPort no responde aún. Verifica que '$KaliVMName' esté encendida (running), que la regla 'setup' esté aplicada y que el servicio SSH esté activo en Kali." -ForegroundColor Yellow
        }
    }

    "exec" {
        Write-Host "[+] Ejecutando en Kali ($KaliUser@127.0.0.1:$HostSSHPort): $Command" -ForegroundColor Cyan
        & ssh @SSHOpts "${KaliUser}@127.0.0.1" $Command
    }

    "push" {
        if ([string]::IsNullOrWhiteSpace($LocalPath) -or [string]::IsNullOrWhiteSpace($RemotePath)) {
            throw "Debes especificar -LocalPath y -RemotePath para la acción 'push'."
        }
        Write-Host "[+] Enviando '$LocalPath' -> ${KaliUser}@127.0.0.1:${RemotePath}..." -ForegroundColor Cyan
        $SCPOpts = @("-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", "-P", "$HostSSHPort")
        & scp @SCPOpts $LocalPath "${KaliUser}@127.0.0.1:${RemotePath}"
    }

    "pull" {
        if ([string]::IsNullOrWhiteSpace($RemotePath) -or [string]::IsNullOrWhiteSpace($LocalPath)) {
            throw "Debes especificar -RemotePath y -LocalPath para la acción 'pull'."
        }
        if (-not (Test-Path $LocalPath)) {
            New-Item -ItemType Directory -Path $LocalPath -Force | Out-Null
        }
        Write-Host "[+] Descargando ${KaliUser}@127.0.0.1:${RemotePath} -> '$LocalPath'..." -ForegroundColor Cyan
        $SCPOpts = @("-r", "-o", "StrictHostKeyChecking=no", "-o", "UserKnownHostsFile=/dev/null", "-P", "$HostSSHPort")
        & scp @SCPOpts "${KaliUser}@127.0.0.1:${RemotePath}" $LocalPath
    }
}
