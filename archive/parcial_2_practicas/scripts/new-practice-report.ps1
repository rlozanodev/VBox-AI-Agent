<#
.SYNOPSIS
    Generador de reportes estandarizados de prácticas y scripts interactivos con pausas de evidencia.
#>
param(
    [Parameter(Mandatory = $true)]
    [string]$Number,

    [Parameter(Mandatory = $true)]
    [string]$Title,

    [Parameter(Mandatory = $false)]
    [string]$Services = "Por especificar",

    [Parameter(Mandatory = $false)]
    [string]$Tools = "Nmap, Dig, OpenSSH",

    [Parameter(Mandatory = $false)]
    [switch]$CreateScript
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$DocsDir = Join-Path $RepoRoot "docs\practicas"
$TemplatePath = Join-Path $DocsDir "_template.md"

# Normalizar slug
$Slug = $Title.ToLowerInvariant() -replace '[^a-z0-9]+', '-' -replace '^-|-$', ''
$PaddedNumber = $Number.PadLeft(2, '0')
$ReportFileName = "practica-$PaddedNumber-$Slug.md"
$ReportPath = Join-Path $DocsDir $ReportFileName
$EvidenceDir = Join-Path $DocsDir "evidencias\practica-$PaddedNumber"

if (-not (Test-Path $EvidenceDir)) {
    New-Item -ItemType Directory -Path $EvidenceDir -Force | Out-Null
}

$Content = Get-Content -Path $TemplatePath -Raw -Encoding UTF8
$Content = $Content.Replace("{{NUMBER}}", $PaddedNumber)
$Content = $Content.Replace("{{TITLE}}", $Title)
$Content = $Content.Replace("{{DATE}}", (Get-Date -Format "yyyy-MM-dd"))
$Content = $Content.Replace("{{SERVICES}}", $Services)
$Content = $Content.Replace("{{TOOLS}}", $Tools)

Set-Content -Path $ReportPath -Value $Content -Encoding UTF8
Write-Host "[OK] Reporte creado en: $ReportPath" -ForegroundColor Green
Write-Host "[OK] Directorio de evidencias creado en: $EvidenceDir" -ForegroundColor Green

if ($CreateScript) {
    $ScriptsPracticasDir = Join-Path $RepoRoot "scripts\practicas"
    if (-not (Test-Path $ScriptsPracticasDir)) {
        New-Item -ItemType Directory -Path $ScriptsPracticasDir -Force | Out-Null
    }
    $ScriptPath = Join-Path $ScriptsPracticasDir "practica-$PaddedNumber.sh"
    $BashTemplate = @"
#!/usr/bin/env bash
# ==============================================================================
# Práctica ${PaddedNumber}: ${Title}
# Cumple Regla 02 (Idempotencia/Limpieza) y Regla 03 (Pausas de Evidencia)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="`$(cd "`$(dirname "`${BASH_SOURCE[0]}")" && pwd)"
LAB_STATE="`${SCRIPT_DIR}/../kali-lab-state.sh"
TARGET_IP="192.168.1.101"

pause_evidence() {
    local step_num="`$1"
    local description="`$2"
    echo ""
    echo "=================================================================="
    echo " [EVIDENCIA #`${step_num}] `${description}"
    echo " -> Toma la captura de pantalla de la salida anterior."
    echo "=================================================================="
    read -r -p "Presiona [ENTER] para continuar con el siguiente paso..." _
    echo ""
}

cleanup() {
    echo ""
    echo "[*] Ejecutando limpieza final del entorno (Regla 02)..."
    sudo "`${LAB_STATE}" cleanup
}

if [[ "`${1:-}" == "--cleanup" ]]; then
    cleanup
    exit 0
fi

echo "[+] Iniciando Práctica ${PaddedNumber}: ${Title}"
echo "[+] Fecha: `$(date '+%Y-%m-%d %H:%M:%S') | Kali IP: `$(hostname -I)"
sudo "`${LAB_STATE}" init
"`${LAB_STATE}" status
pause_evidence "01" "Entorno inicializado y conectividad verificada hacia `${TARGET_IP}"

# --- Agregar pasos técnicos de la práctica aquí ---

echo "[+] Finalizando práctica. ¿Deseas ejecutar la limpieza del entorno ahora?"
pause_evidence "FINAL" "Confirmación previa a limpieza Zero-Footprint"
cleanup
"@
    Set-Content -Path $ScriptPath -Value ($BashTemplate -replace "`r`n", "`n") -NoNewline -Encoding UTF8
    Write-Host "[OK] Script interactivo creado en: $ScriptPath" -ForegroundColor Green
}
