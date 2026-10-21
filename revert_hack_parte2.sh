#!/bin/bash
# ==============================================================================
# revert_hack_parte2.sh
# Script de Reversion y Limpieza Zero-Footprint para Practicas de Post-Explotacion
# Autor / Operador: Lozano
# ==============================================================================

IP_TARGET="192.168.1.101"
REAL_USER="${SUDO_USER:-kali}"
USER_HOME=$(eval echo ~$REAL_USER)
DEV_KEY="$USER_HOME/developer.key"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=5"

echo "[!] Iniciando limpieza del entorno de post-explotacion (Parte 2)..."

# 1. Terminar procesos colgados de tuneles SSH (puerto 5000) y servidores HTTP Python (puerto 8000)
echo "[+] 1. Cerrando tuneles SSH locales (5000:127.0.0.1:5000) y servidores HTTP Python (8000)..."
pkill -f "5000:127.0.0.1:5000" 2>/dev/null || true
pkill -f "http.server 8000" 2>/dev/null || true

# 2. Eliminar llaves SSH temporales y archivos de transferencia en Kali Linux
echo "[+] 2. Eliminando llaves locales (llave_p*, id_rsa*) y archivos temporales (file.txt, file2.txt)..."
rm -f ~/.ssh/llave_p ~/.ssh/llave_p.pub 2>/dev/null || true
rm -f "$USER_HOME/.ssh/llave_p" "$USER_HOME/.ssh/llave_p.pub" 2>/dev/null || true
rm -f ./id_rsa ./id_rsa.pub "$USER_HOME/id_rsa" "$USER_HOME/id_rsa.pub" 2>/dev/null || true
rm -f ./file.txt ./file2.txt "$USER_HOME/file.txt" "$USER_HOME/file2.txt" 2>/dev/null || true
rm -f /tmp/http_kali_8000.log /tmp/file2_downloaded.txt 2>/dev/null || true

# 3. Limpiar artefactos y llaves creadas en el servidor remoto (ubuntuServer)
if [[ -f "$DEV_KEY" ]]; then
    echo "[+] 3. Limpiando artefactos remotos en $IP_TARGET (/home/developer/file* y /root/.ssh/id_rsa*)..."
    chmod 600 "$DEV_KEY"
    ssh -i "$DEV_KEY" $SSH_OPTS "developer@$IP_TARGET" "
        pkill -f 'http.server 8000' 2>/dev/null || true
        rm -f ~/file.txt ~/file2.txt 2>/dev/null || true
        sudo env /bin/bash -c '
            rm -f /root/.ssh/id_rsa /root/.ssh/id_rsa.pub
            > /root/.ssh/authorized_keys
        ' 2>/dev/null || true
    " 2>/dev/null || true
    echo "[OK] Servidor remoto $IP_TARGET restaurado a su estado original."
else
    echo "[i] No se encontro $DEV_KEY; se omitio la limpieza remota."
fi

echo "[!] Limpieza de Parte 2 completada exitosamente (Zero-Footprint)."
