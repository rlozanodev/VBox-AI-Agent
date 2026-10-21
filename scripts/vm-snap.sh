#!/usr/bin/env bash
# Uso: ./scripts/vm-snap.sh "<vm_name>" "<output_path>"
VM_NAME="${1:-Kali-Linux-CLI}"
OUTPUT_PATH="${2:-./docs/assets/screenshot_$(date +%s).png}"
VBOX_CMD="/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"
if command -v VBoxManage >/dev/null 2>&1; then VBOX_CMD="VBoxManage"; fi

mkdir -p "$(dirname "$OUTPUT_PATH")"
"$VBOX_CMD" controlvm "$VM_NAME" screenshotpng "$OUTPUT_PATH"
echo "[+] Screenshot guardado exitosamente en: $OUTPUT_PATH"
