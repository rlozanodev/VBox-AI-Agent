<#
.SYNOPSIS
    Captura directa del framebuffer de una máquina virtual en VirtualBox.
.DESCRIPTION
    Ejecuta 'VBoxManage controlvm <VM_NAME> screenshotpng <OUTPUT_PATH>' sin depender
    de ventanas minimizadas, bordes del SO anfitrión o foco de pantalla.
.PARAMETER VmName
    Nombre o UUID de la máquina virtual (por defecto: 'Kali-Linux-CLI').
.PARAMETER OutputPath
    Ruta de destino del archivo PNG.
.EXAMPLE
    .\scripts\vm-snap.ps1 -VmName "Kali-Linux-CLI" -OutputPath "docs/assets/practica1_nosqli/01_burp_login.png"
#>
[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $false)]
    [string]$VmName = "Kali-Linux-CLI",

    [Parameter(Position = 1, Mandatory = $false)]
    [string]$OutputPath = ""
)

$ErrorActionPreference = "Stop"

if (-not $OutputPath) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $OutputPath = "docs/assets/screenshot_$timestamp.png"
}

$vboxDefault = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$vboxCmd = if (Get-Command VBoxManage -ErrorAction SilentlyContinue) {
    "VBoxManage"
} elseif (Test-Path $vboxDefault) {
    $vboxDefault
} else {
    throw "VBoxManage.exe no fue encontrado en el PATH ni en '$vboxDefault'."
}

$parentDir = Split-Path -Path $OutputPath -Parent
if ($parentDir -and -not (Test-Path $parentDir)) {
    New-Item -ItemType Directory -Force -Path $parentDir | Out-Null
}

$resolvedOutput = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputPath))

Write-Host "[*] Capturando framebuffer de '$VmName'..."
if ($VmName -eq "Kali-Linux-CLI") {
    $oldEAP = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & $vboxCmd guestcontrol $VmName run --exe "/bin/bash" --username "kali" --password "kali" -- -c "export DISPLAY=:0; xset dpms force on 2>/dev/null; xset s reset 2>/dev/null; xset s off 2>/dev/null" >$null 2>&1
    $ErrorActionPreference = $oldEAP
}
& $vboxCmd controlvm $VmName screenshotpng "$resolvedOutput"

if (Test-Path $resolvedOutput) {
    Write-Host "[+] Screenshot guardado exitosamente en: $resolvedOutput"
} else {
    Write-Error "[-] Error: No se pudo generar la captura en '$resolvedOutput'."
}
