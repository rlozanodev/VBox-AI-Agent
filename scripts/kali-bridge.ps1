<#
.SYNOPSIS
    Puente autónomo bidireccional Windows <-> Kali-Linux-CLI <-> ubuntuServer.
.DESCRIPTION
    Proporciona ejecución remota sin fricción en Kali Linux (vía VBoxManage guestcontrol o SSH)
    y salto directo hacia ubuntuServer (192.168.1.101), además de sincronización de carpetas
    y transferencia de archivos. Diseñado para ser 100% determinista para cualquier agente de IA.
#>
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("bootstrap", "setup", "test", "status", "exec", "exec-target", "push", "pull")]
    [string]$Action = "test",

    [Parameter(Mandatory = $false)]
    [string]$Command = "id && hostname -I",

    [Parameter(Mandatory = $false)]
    [switch]$AsRoot,

    [Parameter(Mandatory = $false)]
    [ValidateSet("auto", "guestcontrol", "ssh")]
    [string]$Transport = "guestcontrol",

    [Parameter(Mandatory = $false)]
    [string]$LocalPath = "",

    [Parameter(Mandatory = $false)]
    [string]$RemotePath = "",

    [Parameter(Mandatory = $false)]
    [string]$KaliUser = "kali",

    [Parameter(Mandatory = $false)]
    [string]$KaliPassword = "kali",

    [Parameter(Mandatory = $false)]
    [int]$HostSSHPort = 2222,

    [Parameter(Mandatory = $false)]
    [string]$TargetUser = "developer",

    [Parameter(Mandatory = $false)]
    [string]$TargetIP = "192.168.1.101",

    [Parameter(Mandatory = $false)]
    [string]$TargetKey = "/home/kali/developer.key",

    [Parameter(Mandatory = $false)]
    [string]$TargetPassword = ""
)

$ErrorActionPreference = "Stop"

# 1. Resolver VBoxManage.exe
$VBoxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
if (-not (Test-Path $VBoxManage)) {
    $cmd = Get-Command VBoxManage.exe -ErrorAction SilentlyContinue
    if ($cmd) { $VBoxManage = $cmd.Source } else { throw "VBoxManage.exe no encontrado." }
}

$NatNetName = "cetipracticas"
$KaliVMName = "Kali-Linux-CLI"
$RepoRoot   = Split-Path -Parent $PSScriptRoot
$SSHKeyDir  = Join-Path $RepoRoot "workspace\.ssh"
$SSHKeyPath = Join-Path $SSHKeyDir "kali_agent_ed25519"

function Get-KaliLiveIP {
    $prop = & $VBoxManage guestproperty get $KaliVMName "/VirtualBox/GuestInfo/Net/0/V4/IP" 2>$null
    if ($prop -match "Value:\s*(\d+\.\d+\.\d+\.\d+)") {
        return $Matches[1]
    }
    return "192.168.1.5"
}

function Invoke-KaliGuestControl([string]$bashCmd, [bool]$runAsRoot = $false) {
    # Normalizar saltos de línea a LF y codificar en Base64 UTF-8 para evitar errores de comillas/escape
    $cleanCmd = $bashCmd -replace "`r`n", "`n"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($cleanCmd)
    $b64   = [Convert]::ToBase64String($bytes)

    if ($runAsRoot) {
        $wrapped = "echo '$b64' | base64 -d | sudo -n /bin/bash"
    } else {
        $wrapped = "echo '$b64' | base64 -d | /bin/bash"
    }

    & $VBoxManage guestcontrol $KaliVMName run `
        --exe "/bin/bash" `
        --username $KaliUser `
        --password $KaliPassword `
        -- -c $wrapped
}

function Invoke-KaliSSH([string]$bashCmd, [bool]$runAsRoot = $false) {
    $cleanCmd = $bashCmd -replace "`r`n", "`n"
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($cleanCmd)
    $b64   = [Convert]::ToBase64String($bytes)
    $wrapped = if ($runAsRoot) { "echo '$b64' | base64 -d | sudo -n /bin/bash" } else { "echo '$b64' | base64 -d | /bin/bash" }

    $sshOpts = @(
        "-o", "StrictHostKeyChecking=no",
        "-o", "UserKnownHostsFile=/dev/null",
        "-o", "BatchMode=yes",
        "-o", "ConnectTimeout=5",
        "-p", "$HostSSHPort"
    )
    if (Test-Path $SSHKeyPath) {
        $sshOpts += @("-i", $SSHKeyPath)
    }
    & ssh @sshOpts "${KaliUser}@127.0.0.1" $wrapped
}

function Invoke-KaliCommand([string]$bashCmd, [bool]$runAsRoot = $false) {
    if ($Transport -eq "ssh") {
        Invoke-KaliSSH $bashCmd $runAsRoot
    } else {
        Invoke-KaliGuestControl $bashCmd $runAsRoot
    }
}

switch ($Action) {
    { $_ -in @("bootstrap", "setup") } {
        $liveIP = Get-KaliLiveIP
        Write-Host "==============================================================" -ForegroundColor Cyan
        Write-Host " Bootstrapping Kali Bridge (Kali Live IP: $liveIP)" -ForegroundColor Cyan
        Write-Host "==============================================================" -ForegroundColor Cyan

        # 1. Configurar sudo NOPASSWD en Kali
        Write-Host "[1/5] Configurando sudo NOPASSWD para '$KaliUser' en Kali..." -ForegroundColor Yellow
        $sudoSetupCmd = "echo '$KaliPassword' | sudo -S bash -c 'echo ""$KaliUser ALL=(ALL:ALL) NOPASSWD: ALL"" > /etc/sudoers.d/kali-agent && chmod 440 /etc/sudoers.d/kali-agent'"
        Invoke-KaliGuestControl $sudoSetupCmd $false

        # 2. Habilitar e iniciar servicio SSH en Kali
        Write-Host "[2/5] Habilitando e iniciando servicio OpenSSH en Kali..." -ForegroundColor Yellow
        Invoke-KaliGuestControl "systemctl enable --now ssh && systemctl is-active ssh" $true

        # 3. Generar llave SSH en Windows e inyectarla en Kali
        Write-Host "[3/5] Configurando par de llaves SSH sin contraseña Windows -> Kali..." -ForegroundColor Yellow
        if (-not (Test-Path $SSHKeyDir)) {
            New-Item -ItemType Directory -Path $SSHKeyDir -Force | Out-Null
        }
        if (-not (Test-Path $SSHKeyPath)) {
            & ssh-keygen -t ed25519 -f $SSHKeyPath -C "vbox-ai-agent@windows" -q -N '""'
        }
        $pubKey = (Get-Content "${SSHKeyPath}.pub" -Raw).Trim()
        $authKeyCmd = @"
mkdir -p /home/$KaliUser/.ssh
chmod 700 /home/$KaliUser/.ssh
touch /home/$KaliUser/.ssh/authorized_keys
grep -qF '$pubKey' /home/$KaliUser/.ssh/authorized_keys || echo '$pubKey' >> /home/$KaliUser/.ssh/authorized_keys
chmod 600 /home/$KaliUser/.ssh/authorized_keys
chown -R ${KaliUser}:${KaliUser} /home/$KaliUser/.ssh
"@
        Invoke-KaliGuestControl $authKeyCmd $false

        # 4. Configurar Port-Forwarding en la red NAT cetipracticas hacia la IP actual de Kali
        Write-Host "[4/5] Actualizando regla Port-Forwarding 'kali-ssh' (127.0.0.1:$HostSSHPort -> ${liveIP}:22)..." -ForegroundColor Yellow
        $oldEAP = $ErrorActionPreference
        $ErrorActionPreference = "Continue"
        & $VBoxManage natnetwork modify --netname $NatNetName --port-forward-4 delete "kali-ssh" >$null 2>&1
        & $VBoxManage natnetwork modify --netname $NatNetName --port-forward-4 "kali-ssh:tcp:[127.0.0.1]:${HostSSHPort}:[${liveIP}]:22"

        # 5. Configurar y montar Carpeta Compartida vbox_repo -> /mnt/vbox_repo y symlink /home/kali/repo
        Write-Host "[5/5] Montando repositorio local en '/mnt/vbox_repo' y creando enlace '/home/kali/repo'..." -ForegroundColor Yellow
        & $VBoxManage sharedfolder remove $KaliVMName --name "vbox_repo" --transient >$null 2>&1
        & $VBoxManage sharedfolder add $KaliVMName --name "vbox_repo" --hostpath $RepoRoot --automount --transient
        $ErrorActionPreference = $oldEAP
        $mountRepoCmd = @"
mkdir -p /mnt/vbox_repo
if ! mountpoint -q /mnt/vbox_repo; then
    mount -t vboxsf -o uid=1000,gid=1000 vbox_repo /mnt/vbox_repo
fi
ln -sfn /mnt/vbox_repo /home/$KaliUser/repo
chown -h ${KaliUser}:${KaliUser} /home/$KaliUser/repo
ls -la /home/$KaliUser/repo/scripts/
"@
        Invoke-KaliGuestControl $mountRepoCmd $true

        Write-Host "[OK] Puente Windows <-> Kali <-> Target configurado y verificado." -ForegroundColor Green
    }

    { $_ -in @("test", "status") } {
        $liveIP = Get-KaliLiveIP
        Write-Host "==============================================================" -ForegroundColor Cyan
        Write-Host " Estado del Puente Kali-Linux-CLI (IP detectada: $liveIP)" -ForegroundColor Cyan
        Write-Host "==============================================================" -ForegroundColor Cyan

        Write-Host "[1] Prueba de canal primario (VBoxManage guestcontrol + sudo NOPASSWD):" -ForegroundColor Yellow
        Invoke-KaliGuestControl "echo '  - Usuario Kali:' `$(id -un) && echo '  - Sudo Root:' `$(sudo -n id -un) && echo '  - Servicio SSH:' `$(systemctl is-active ssh)" $false

        Write-Host "`n[2] Prueba de Carpeta Compartida (/home/kali/repo):" -ForegroundColor Yellow
        Invoke-KaliGuestControl "if mountpoint -q /mnt/vbox_repo; then echo '  - /mnt/vbox_repo: MONTADO OK'; else echo '  - /mnt/vbox_repo: NO MONTADO'; fi" $false

        Write-Host "`n[3] Prueba de salto SSH hacia Target ubuntuServer ($TargetUser@$TargetIP):" -ForegroundColor Yellow
        $targetCheck = "ssh -i $TargetKey -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=5 $TargetUser@$TargetIP 'echo ""  - Conectado a Target como: `$(id) en `$(hostname)""' 2>/dev/null"
        Invoke-KaliGuestControl $targetCheck $false
    }

    "exec" {
        Invoke-KaliCommand $Command $AsRoot.IsPresent
    }

    "exec-target" {
        $cleanCmd = $Command -replace "`r`n", "`n"
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($cleanCmd)
        $b64   = [Convert]::ToBase64String($bytes)

        if (-not [string]::IsNullOrWhiteSpace($TargetPassword)) {
            $jumpCmd = "sshpass -p '$TargetPassword' ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 ${TargetUser}@${TargetIP} ""echo '$b64' | base64 -d | /bin/bash"""
        } else {
            $jumpCmd = "ssh -i '$TargetKey' -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 ${TargetUser}@${TargetIP} ""echo '$b64' | base64 -d | /bin/bash"""
        }
        Invoke-KaliCommand $jumpCmd $false
    }

    "push" {
        if ([string]::IsNullOrWhiteSpace($LocalPath) -or [string]::IsNullOrWhiteSpace($RemotePath)) {
            throw "Debes especificar -LocalPath y -RemotePath para la acción 'push'."
        }
        $resolvedLocal = (Resolve-Path $LocalPath).Path
        Write-Host "[+] Copiando '$resolvedLocal' -> Kali:'$RemotePath' vía guestcontrol..." -ForegroundColor Cyan
        & $VBoxManage guestcontrol $KaliVMName copyto --username $KaliUser --password $KaliPassword --target-directory $RemotePath $resolvedLocal
        Write-Host "[OK] Archivo enviado." -ForegroundColor Green
    }

    "pull" {
        if ([string]::IsNullOrWhiteSpace($RemotePath) -or [string]::IsNullOrWhiteSpace($LocalPath)) {
            throw "Debes especificar -RemotePath y -LocalPath para la acción 'pull'."
        }
        if (-not (Test-Path $LocalPath)) {
            New-Item -ItemType Directory -Path $LocalPath -Force | Out-Null
        }
        $resolvedLocal = (Resolve-Path $LocalPath).Path
        Write-Host "[+] Copiando Kali:'$RemotePath' -> '$resolvedLocal' vía guestcontrol..." -ForegroundColor Cyan
        & $VBoxManage guestcontrol $KaliVMName copyfrom --username $KaliUser --password $KaliPassword --target-directory $resolvedLocal $RemotePath
        Write-Host "[OK] Archivo recibido." -ForegroundColor Green
    }
}
