#!/usr/bin/env bash
# Uso: ./scripts/build-report.sh [input_markdown] [output_docx] [--skip-upload]
set -euo pipefail

INPUT_PATH="${1:-docs/reportes/REPORTE_PRACTICAS_LOZANO.md}"
OUTPUT_PATH="${2:-docs/reportes/Reporte_Final_Lozano.docx}"
SKIP_UPLOAD="${3:-}"

echo "=========================================================="
echo "   PIPELINE DE REPORTE TÉCNICO (PANDOC -> GOOGLE DOCS)   "
echo "=========================================================="
echo "[*] Archivo Markdown: $INPUT_PATH"
echo "[*] Archivo de Salida: $OUTPUT_PATH"

if [[ ! -f "$INPUT_PATH" ]]; then
    echo "[-] Error: Archivo de entrada no encontrado: $INPUT_PATH" >&2
    exit 1
fi

mkdir -p "$(dirname "$OUTPUT_PATH")"

RESOURCE_PATHS=".:docs:docs/reportes:docs/assets:docs/assets/practica1_nosqli:docs/assets/practica2_privesc_files:docs/assets/practica3_ssh_keys:docs/assets/practica4_gtfobins_ctf"

echo "[*] Compilando reporte con Pandoc..."
pandoc "$INPUT_PATH" -o "$OUTPUT_PATH" --resource-path="$RESOURCE_PATHS"

echo "[+] Reporte DOCX compilado exitosamente: $OUTPUT_PATH"

if [[ "$SKIP_UPLOAD" == "--skip-upload" ]]; then
    echo "[i] Subida a Google Drive omitida."
    exit 0
fi

if command -v gws >/dev/null 2>&1; then
    echo "[*] Verificando autenticación de Google Workspace CLI..."
    AUTH_STATE=$(gws auth status 2>/dev/null || true)
    if echo "$AUTH_STATE" | grep -q '"auth_method": "none"'; then
        echo "[!] gws no está autenticado aún. Ejecuta 'gws auth login' o 'gws auth setup' para habilitar subida automática a Google Drive."
        echo "[+] El archivo DOCX local está listo en: $OUTPUT_PATH"
    else
        DOC_TITLE=$(basename "$OUTPUT_PATH" .docx)
        echo "[*] Subiendo '$OUTPUT_PATH' a Google Drive y convirtiendo a Google Docs..."
        gws drive files create --upload "$OUTPUT_PATH" \
            --upload-content-type "application/vnd.openxmlformats-officedocument.wordprocessingml.document" \
            --json "{\"name\":\"$DOC_TITLE\",\"mimeType\":\"application/vnd.google-apps.document\"}"
        echo "[+] Subida completada exitosamente!"
    fi
else
    echo "[!] Comando 'gws' no disponible en el entorno bash actual. Usa el script de PowerShell o instala @googleworkspace/cli."
fi
