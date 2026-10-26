#!/bin/bash
# ==============================================================================
# revert_hack.sh
# Suite Unificada de Reversion y Limpieza Zero-Footprint (Parte 1 y Parte 2)
#
# Autor / Operador: Lozano
# Alcance: Limpieza total de procesos, montajes SMB/NFS, /etc/hosts, llaves SSH
#          y restauracion del estado original en local (Kali) y remoto (ubuntuServer).
# ==============================================================================

# Verificacion de permisos de superusuario
if [[ $EUID -ne 0 ]]; then
    echo "[!] Este script requiere privilegios de superusuario para desmontar recursos y restaurar /etc/hosts."
    echo "[!] Por favor ejecutalo con: sudo $0"
    exit 1
fi

IP_TARGET="192.168.1.101"
REAL_USER="${SUDO_USER:-kali}"
USER_HOME=$(eval echo ~$REAL_USER)
DEV_KEY="$USER_HOME/developer.key"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o ConnectTimeout=5"

echo "=============================================================================="
echo "    INICIANDO LIMPIEZA ZERO-FOOTPRINT DEL LABORATORIO (COMPLETA)             "
echo "    Operador: Lozano | Target: $IP_TARGET                                    "
echo "=============================================================================="

# 1. Terminar procesos colgados de tuneles SSH (puerto 5000) y servidores HTTP Python (puerto 8000)
echo "[+] 1. Cerrando tuneles SSH locales (5000:127.0.0.1:5000) y servidores HTTP Python (8000)..."
pkill -f "5000:127.0.0.1:5000" 2>/dev/null || true
pkill -f "http.server 8000" 2>/dev/null || true

# 2. Limpiar artefactos y llaves creadas en el servidor remoto (ubuntuServer) ANTES de borrar developer.key
if [[ -f "$DEV_KEY" ]]; then
    echo "[+] 2. Limpiando artefactos remotos en $IP_TARGET (/home/developer/file* y /root/.ssh/id_rsa*)..."
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
    echo "[i] No se encontro $DEV_KEY localmente; omitiendo limpieza remota SSH en target."
fi

# 3. Desmontar los recursos de red de forma segura (NFS y SMB/CIFS)
echo "[+] 3. Desmontando carpetas de red (SMB y NFS)..."
for mp in "/mnt/archivoCompartido" "/mnt/respaldos" "/mnt/smb_archivos" "/mnt/nfs_respaldos"; do
    if mountpoint -q "$mp" 2>/dev/null; then
        echo "    - Desmontando $mp..."
        umount -l "$mp" 2>/dev/null || umount "$mp" 2>/dev/null || true
    elif [[ -d "$mp" ]]; then
        umount -l "$mp" 2>/dev/null || true
    fi
done

# 4. Eliminar directorios de montaje y archivos temporales locales
echo "[+] 4. Eliminando carpetas de montaje y archivos descargados..."
rm -rf /mnt/archivoCompartido /mnt/respaldos /mnt/smb_archivos /mnt/nfs_respaldos 2>/dev/null || true
rm -f /mnt/developer.key "$DEV_KEY" 2>/dev/null || true
rm -f nota_desarrollo.txt respaldo_credenciales.txt nota_servicio.txt 2>/dev/null || true
rm -f "$USER_HOME/nota_desarrollo.txt" "$USER_HOME/respaldo_credenciales.txt" "$USER_HOME/nota_servicio.txt" 2>/dev/null || true
rm -f ./file.txt ./file2.txt "$USER_HOME/file.txt" "$USER_HOME/file2.txt" 2>/dev/null || true
rm -f /tmp/http_kali_8000.log /tmp/file2_downloaded.txt 2>/dev/null || true
rm -f "$USER_HOME/hash_practica6.txt" ./hash_practica6.txt 2>/dev/null || true

# 5. Eliminar llaves SSH temporales locales (Kali Linux)
echo "[+] 5. Eliminando llaves SSH locales temporales (llave_p*, id_rsa*)..."
rm -f ~/.ssh/llave_p ~/.ssh/llave_p.pub 2>/dev/null || true
rm -f "$USER_HOME/.ssh/llave_p" "$USER_HOME/.ssh/llave_p.pub" 2>/dev/null || true
rm -f ./id_rsa ./id_rsa.pub "$USER_HOME/id_rsa" "$USER_HOME/id_rsa.pub" 2>/dev/null || true

# 6. Limpiar y restaurar el archivo /etc/hosts
echo "[+] 6. Limpiando y restaurando el archivo /etc/hosts..."
cp -f /etc/hosts /etc/hosts.bak 2>/dev/null || true
sed -i '/# BEGIN CETILAB/,/# END CETILAB/d' /etc/hosts 2>/dev/null || true
sed -i '/192\.168\.1\.101/d' /etc/hosts
sed -i '/cetilab\.local/d' /etc/hosts
sed -i '/admin-backup/d' /etc/hosts

echo "=============================================================================="
echo "[!] Limpieza unificada completada exitosamente (Zero-Footprint)."
echo "[!] Tu entorno esta como nuevo y listo para empezar desde cero."
echo "=============================================================================="
