<#
.SYNOPSIS
    Pipeline automatizado para compilar el reporte Markdown a DOCX y subirlo a Google Docs/Drive.
.DESCRIPTION
    1. Compila 'docs/reportes/REPORTE_PRACTICAS_LOZANO.md' a 'docs/reportes/Reporte_Final_Lozano.docx' con Pandoc.
    2. Resuelve e incrusta las imágenes de 'docs/assets/'.
    3. Si gws está autenticado, sube el DOCX a Google Drive convirtiéndolo en un Google Doc nativo editable.
.PARAMETER InputPath
    Ruta del reporte Markdown de entrada (por defecto: docs/reportes/REPORTE_PRACTICAS_LOZANO.md).
.PARAMETER OutputPath
    Ruta del archivo DOCX resultante (por defecto: docs/reportes/Reporte_Final_Lozano.docx).
.PARAMETER SkipUpload
    Si se especifica, solo compila a DOCX sin subir a Google Drive.
.EXAMPLE
    .\scripts\build-report.ps1
    .\scripts\build-report.ps1 -SkipUpload
#>
[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [string]$InputPath = "docs/reportes/REPORTE_PRACTICAS_LOZANO.md",

    [Parameter(Position = 1)]
    [string]$OutputPath = "docs/reportes/Reporte_Final_Lozano.docx",

    [switch]$SkipUpload
)

$ErrorActionPreference = "Stop"

# Actualizar PATH en sesión si es necesario para detectar pandoc recién instalado
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

$repoRoot = Get-Location

# 1. Validar archivo de entrada
$resolvedInput = Join-Path $repoRoot $InputPath
if (-not (Test-Path $resolvedInput)) {
    throw "[-] Archivo de entrada no encontrado: $resolvedInput"
}

$resolvedOutput = Join-Path $repoRoot $OutputPath
$outputDir = Split-Path -Path $resolvedOutput -Parent
if ($outputDir -and -not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Force -Path $outputDir | Out-Null
}

# 2. Localizar Pandoc
$pandocCmd = if (Get-Command pandoc -ErrorAction SilentlyContinue) {
    "pandoc"
} elseif (Test-Path "C:\Program Files\Pandoc\pandoc.exe") {
    "C:\Program Files\Pandoc\pandoc.exe"
} elseif (Test-Path "$env:LOCALAPPDATA\Pandoc\pandoc.exe") {
    "$env:LOCALAPPDATA\Pandoc\pandoc.exe"
} else {
    throw "[-] Pandoc no encontrado. Instálalo con: winget install --id JohnMacFarlane.Pandoc -e"
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "   PIPELINE DE REPORTE TÉCNICO (PANDOC -> GOOGLE DOCS)   " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "[*] Archivo Markdown: $resolvedInput"
Write-Host "[*] Archivo de Salida: $resolvedOutput"
Write-Host "[*] Compilando reporte con Pandoc..."

# 3. Ejecutar Pandoc con resolución de rutas relativas de assets
$resourcePaths = ".:docs:docs/reportes:docs/assets:docs/assets/practica1_nosqli:docs/assets/practica2_privesc_files:docs/assets/practica3_ssh_keys:docs/assets/practica4_gtfobins_ctf"

& $pandocCmd "$resolvedInput" -o "$resolvedOutput" --resource-path="$resourcePaths"

if (-not (Test-Path $resolvedOutput)) {
    throw "[-] Error al compilar con Pandoc. El archivo DOCX no fue generado."
}

$fileInfo = Get-Item $resolvedOutput
Write-Host "[+] Documento DOCX generado con éxito! ($($fileInfo.Length) bytes)" -ForegroundColor Green

if ($SkipUpload) {
    Write-Host "[i] Subida a Google Drive omitida por bandera -SkipUpload." -ForegroundColor Yellow
    return
}

# 4. Verificación y subida a Google Drive / Google Docs vía gws
Write-Host "[*] Verificando estado de Google Workspace CLI (gws)..."
$gwsCmd = if (Get-Command gws -ErrorAction SilentlyContinue) {
    "gws"
} elseif (Test-Path "D:\Dev\.caches\npm-global\gws.cmd") {
    "D:\Dev\.caches\npm-global\gws.cmd"
} else {
    "gws"
}

try {
    $authStatusRaw = & cmd /c $gwsCmd auth status 2>$null
    $authStatus = $authStatusRaw | ConvertFrom-Json -ErrorAction SilentlyContinue
    $isAuthenticated = ($authStatus -and $authStatus.auth_method -ne "none")
} catch {
    $isAuthenticated = $false
}

if (-not $isAuthenticated) {
    Write-Host ""
    Write-Host "[!] ADVERTENCIA: gws no está autenticado aún con tu cuenta de Google." -ForegroundColor Yellow
    Write-Host "    Para subir automáticamente a Google Docs, ejecuta en tu terminal:" -ForegroundColor Yellow
    Write-Host "      gws auth login" -ForegroundColor White
    Write-Host "    O para configurar tu propio proyecto de GCP:" -ForegroundColor Yellow
    Write-Host "      gws auth setup" -ForegroundColor White
    Write-Host "[+] El archivo DOCX local ya está listo en: $resolvedOutput" -ForegroundColor Green
    return
}

Write-Host "[*] Subiendo '$resolvedOutput' a Google Drive y convirtiendo a Google Docs..." -ForegroundColor Cyan
$docTitle = [System.IO.Path]::GetFileNameWithoutExtension($resolvedOutput)
$jsonPayload = @{
    name = $docTitle
    mimeType = "application/vnd.google-apps.document"
} | ConvertTo-Json -Compress

$uploadResult = & cmd /c $gwsCmd drive files create --upload "$resolvedOutput" --upload-content-type "application/vnd.openxmlformats-officedocument.wordprocessingml.document" --json "$jsonPayload"

Write-Host "[+] Reporte subido y convertido a Google Docs exitosamente!" -ForegroundColor Green
Write-Host "$uploadResult"
