<#
.SYNOPSIS
    Orquestador de Máquinas Virtuales de VirtualBox para el laboratorio CETI.
.DESCRIPTION
    Permite listar estado de VMs, auditar la red NAT 'cetipracticas', iniciar/detener
    las VMs (Kali-Linux-CLI en modo GUI y ubuntuServer en modo Headless) y gestionar snapshots.
#>
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("status", "start", "stop", "savestate", "snapshot-list", "snapshot-take", "snapshot-restore")]
    [string]$Action = "status",

    [Parameter(Mandatory = $false)]
    [ValidateSet("all", "Kali-Linux-CLI", "ubuntuServer")]
    [string]$VM = "all",

    [Parameter(Mandatory = $false)]
    [string]$SnapshotName = "",

    [Parameter(Mandatory = $false)]
    [string]$Description = "Snapshot automatico generado por vbox-controller"
)

$ErrorActionPreference = "Stop"

# 1. Resolver VBoxManage.exe
$VBoxManage = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
if (-not (Test-Path $VBoxManage)) {
    $cmd = Get-Command VBoxManage.exe -ErrorAction SilentlyContinue
    if ($cmd) {
        $VBoxManage = $cmd.Source
    } else {
        Write-Error "No se encontró VBoxManage.exe en 'C:\Program Files\Oracle\VirtualBox\VBoxManage.exe' ni en el PATH."
        exit 1
    }
}

$LabVMs = @(
    @{ Name = "ubuntuServer";   UUID = "9f4e173c-8db8-4fe4-b215-72cb0988112a"; Mode = "headless"; Role = "Target (192.168.1.101)" },
    @{ Name = "Kali-Linux-CLI"; UUID = "930ba4aa-afd4-4414-a2a9-b03b76bdc62c"; Mode = "gui";      Role = "Attacker (192.168.1.4)" }
)

function Get-TargetVMs {
    if ($VM -eq "all") { return $LabVMs }
    return $LabVMs | Where-Object { $_.Name -eq $VM }
}

function Get-VMState([string]$vmName) {
    $info = & $VBoxManage showvminfo $vmName --machinereadable 2>$null
    $stateLine = $info | Select-String -Pattern '^VMState="(.+)"$'
    if ($stateLine) {
        return $stateLine.Matches[0].Groups[1].Value
    }
    return "unknown"
}

switch ($Action) {
    "status" {
        $version = & $VBoxManage --version
        Write-Host "==============================================================" -ForegroundColor Cyan
        Write-Host " VirtualBox Lab Controller - Versión: $version" -ForegroundColor Cyan
        Write-Host "==============================================================" -ForegroundColor Cyan

        Write-Host "`n[1] Estado de Red NAT (cetipracticas):" -ForegroundColor Yellow
        $natNets = & $VBoxManage list natnets
        $natNets | Write-Host

        Write-Host "[2] Estado de Máquinas Virtuales del Laboratorio:" -ForegroundColor Yellow
        foreach ($item in $LabVMs) {
            $info = & $VBoxManage showvminfo $item.Name --machinereadable
            $state = ($info | Select-String '^VMState="(.+)"$').Matches[0].Groups[1].Value
            $nic1  = ($info | Select-String '^nic1="(.+)"$').Matches[0].Groups[1].Value
            $nat1  = ($info | Select-String '^nat-network1="(.+)"$').Matches[0].Groups[1].Value
            $mem   = ($info | Select-String '^memory=(\d+)$').Matches[0].Groups[1].Value
            $cpus  = ($info | Select-String '^cpus=(\d+)$').Matches[0].Groups[1].Value

            $color = if ($state -eq "running") { "Green" } elseif ($state -eq "saved") { "Yellow" } else { "Gray" }
            Write-Host ("  - {0,-16} | Rol: {1,-24} | Estado: {2,-10} | Modo default: {3,-8} | RAM: {4}MB | CPUs: {5} | Red: {6} ({7})" -f `
                $item.Name, $item.Role, $state, $item.Mode, $mem, $cpus, $nic1, $nat1) -ForegroundColor $color
        }
        Write-Host ""
    }

    "start" {
        foreach ($item in (Get-TargetVMs)) {
            $state = Get-VMState $item.Name
            if ($state -eq "running") {
                Write-Host "[=] '$($item.Name)' ya está en ejecución (running)." -ForegroundColor Green
            } else {
                Write-Host "[+] Iniciando '$($item.Name)' en modo '$($item.Mode)' (estado previo: $state)..." -ForegroundColor Cyan
                & $VBoxManage startvm $item.Name --type $item.Mode
            }
        }
    }

    "savestate" {
        foreach ($item in (Get-TargetVMs)) {
            $state = Get-VMState $item.Name
            if ($state -eq "running") {
                Write-Host "[+] Guardando estado (savestate) de '$($item.Name)'..." -ForegroundColor Yellow
                & $VBoxManage controlvm $item.Name savestate
            } else {
                Write-Host "[=] '$($item.Name)' no está en ejecución (estado actual: $state)." -ForegroundColor Gray
            }
        }
    }

    "stop" {
        foreach ($item in (Get-TargetVMs)) {
            $state = Get-VMState $item.Name
            if ($state -eq "running") {
                Write-Host "[+] Enviando señal ACPI Power Button a '$($item.Name)'..." -ForegroundColor Yellow
                & $VBoxManage controlvm $item.Name acpipowerbutton
            } else {
                Write-Host "[=] '$($item.Name)' no está en ejecución (estado actual: $state)." -ForegroundColor Gray
            }
        }
    }

    "snapshot-list" {
        foreach ($item in (Get-TargetVMs)) {
            Write-Host "`n[*] Snapshots de '$($item.Name)':" -ForegroundColor Cyan
            & $VBoxManage snapshot $item.Name list
        }
    }

    "snapshot-take" {
        if ([string]::IsNullOrWhiteSpace($SnapshotName)) {
            $SnapshotName = "snap-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        }
        foreach ($item in (Get-TargetVMs)) {
            Write-Host "[+] Creando snapshot '$SnapshotName' en '$($item.Name)'..." -ForegroundColor Cyan
            & $VBoxManage snapshot $item.Name take $SnapshotName --description $Description
        }
    }

    "snapshot-restore" {
        foreach ($item in (Get-TargetVMs)) {
            $state = Get-VMState $item.Name
            if ($state -eq "running") {
                Write-Host "[!] Deteniendo '$($item.Name)' antes de restaurar snapshot..." -ForegroundColor Yellow
                & $VBoxManage controlvm $item.Name poweroff
                Start-Sleep -Seconds 2
            }
            if ([string]::IsNullOrWhiteSpace($SnapshotName)) {
                Write-Host "[+] Restaurando snapshot actual (restorecurrent) en '$($item.Name)'..." -ForegroundColor Cyan
                & $VBoxManage snapshot $item.Name restorecurrent
            } else {
                Write-Host "[+] Restaurando snapshot '$SnapshotName' en '$($item.Name)'..." -ForegroundColor Cyan
                & $VBoxManage snapshot $item.Name restore $SnapshotName
            }
        }
    }
}
