#!/usr/bin/env bash
# ==============================================================================
# kali-lab-state.sh - Gestor Idempotente de Estado del Laboratorio CETI en Kali
# Regla 02: Idempotencia y Limpieza (Zero-Footprint)
# Target: ubuntuServer (192.168.1.101 - cetilab.local)
# ==============================================================================

set -euo pipefail

TARGET_IP="192.168.1.101"
HOSTS_FILE="/etc/hosts"
MARKER_BEGIN="# BEGIN CETILAB"
MARKER_END="# END CETILAB"
NFS_REMOTE="${TARGET_IP}:/srv/nfs/respaldos_ti"
NFS_MOUNT="/mnt/nfs_respaldos"
SMB_REMOTE="//${TARGET_IP}/archivos_ti"
SMB_MOUNT="/mnt/smb_archivos"
LOCAL_TUNNEL_PORT="5000"
REMOTE_TUNNEL_PORT="5000"

CETILAB_DOMAINS=(
    "cetilab.local"
    "admin-backup"
    "app.cetilab.local"
    "db-mongo.cetilab.local"
    "db-mysql.cetilab.local"
    "files.cetilab.local"
    "ftp.cetilab.local"
    "mail.cetilab.local"
    "nfs.cetilab.local"
    "ns1.cetilab.local"
    "snmp.cetilab.local"
    "ssh.cetilab.local"
    "www.cetilab.local"
)

pause_evidence() {
    local step_num="$1"
    local description="$2"
    echo ""
    echo "=================================================================="
    echo " [EVIDENCIA #${step_num}] ${description}"
    echo " -> Toma la captura de pantalla de la salida anterior."
    echo "=================================================================="
    read -r -p "Presiona [ENTER] para continuar con el siguiente paso..." _
    echo ""
}

hosts_up() {
    echo "[+] Actualizando de forma idempotente ${HOSTS_FILE} para ${TARGET_IP}..."
    sudo sed -i "/${MARKER_BEGIN}/,/${MARKER_END}/d" "${HOSTS_FILE}"
    {
        echo "${MARKER_BEGIN}"
        echo "${TARGET_IP} ${CETILAB_DOMAINS[*]}"
        echo "${MARKER_END}"
    } | sudo tee -a "${HOSTS_FILE}" > /dev/null
    echo "[OK] Bloque CETILAB configurado sin duplicados en ${HOSTS_FILE}."
}

hosts_down() {
    echo "[+] Eliminando bloque CETILAB de ${HOSTS_FILE}..."
    sudo sed -i "/${MARKER_BEGIN}/,/${MARKER_END}/d" "${HOSTS_FILE}"
    echo "[OK] ${HOSTS_FILE} restaurado a su estado limpio."
}

mount_nfs() {
    echo "[+] Preparando punto de montaje NFS en ${NFS_MOUNT}..."
    sudo mkdir -p "${NFS_MOUNT}"
    if mountpoint -q "${NFS_MOUNT}"; then
        echo "[=] ${NFS_MOUNT} ya se encuentra montado."
    else
        sudo mount -t nfs -o nolock "${NFS_REMOTE}" "${NFS_MOUNT}"
        echo "[OK] Recurso NFS ${NFS_REMOTE} montado en ${NFS_MOUNT}."
    fi
}

mount_smb() {
    local smb_user="${1:-guest}"
    local smb_pass="${2:-}"
    echo "[+] Preparando punto de montaje SMB en ${SMB_MOUNT}..."
    sudo mkdir -p "${SMB_MOUNT}"
    if mountpoint -q "${SMB_MOUNT}"; then
        echo "[=] ${SMB_MOUNT} ya se encuentra montado."
    else
        if [[ -z "${smb_pass}" && "${smb_user}" == "guest" ]]; then
            sudo mount -t cifs "${SMB_REMOTE}" "${SMB_MOUNT}" -o guest,uid="$(id -u)",gid="$(id -g)"
        else
            sudo mount -t cifs "${SMB_REMOTE}" "${SMB_MOUNT}" -o "username=${smb_user},password=${smb_pass},uid=$(id -u),gid=$(id -g)"
        fi
        echo "[OK] Recurso SMB ${SMB_REMOTE} montado en ${SMB_MOUNT}."
    fi
}

umount_all() {
    for mp in "${NFS_MOUNT}" "${SMB_MOUNT}" "/mnt/archivoCompartido" "/mnt/respaldos"; do
        if [[ -d "${mp}" ]] && mountpoint -q "${mp}"; then
            echo "[+] Desmontando ${mp}..."
            sudo umount -l "${mp}"
        fi
        if [[ -d "${mp}" ]] && [[ -z "$(ls -A "${mp}" 2>/dev/null || true)" ]]; then
            sudo rmdir "${mp}" 2>/dev/null || true
        fi
    done
    echo "[OK] Puntos de montaje en /mnt/ liberados."
}

fix_ssh_key() {
    local key_path="$1"
    if [[ ! -f "${key_path}" ]]; then
        echo "[!] Error: No existe el archivo de llave SSH en '${key_path}'." >&2
        exit 1
    fi
    chown "$(id -u):$(id -g)" "${key_path}" 2>/dev/null || sudo chown "$(id -u):$(id -g)" "${key_path}"
    chmod 600 "${key_path}"
    echo "[OK] Permisos 600 y propietario ajustados en '${key_path}'."
    ls -l "${key_path}"
}

tunnel_up() {
    local ssh_user="${1:-lozano}"
    local ssh_key="${2:-}"

    if ss -tln | grep -q ":${LOCAL_TUNNEL_PORT} "; then
        echo "[=] El túnel local en el puerto 127.0.0.1:${LOCAL_TUNNEL_PORT} ya está activo."
        return 0
    fi

    echo "[+] Iniciando Local Port Forwarding 127.0.0.1:${LOCAL_TUNNEL_PORT} -> 127.0.0.1:${REMOTE_TUNNEL_PORT} (${ssh_user}@${TARGET_IP})..."
    if [[ -n "${ssh_key}" ]]; then
        fix_ssh_key "${ssh_key}"
        ssh -f -N -L "${LOCAL_TUNNEL_PORT}:127.0.0.1:${REMOTE_TUNNEL_PORT}" \
            -i "${ssh_key}" \
            -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            "${ssh_user}@${TARGET_IP}"
    else
        ssh -f -N -L "${LOCAL_TUNNEL_PORT}:127.0.0.1:${REMOTE_TUNNEL_PORT}" \
            -o StrictHostKeyChecking=no \
            -o UserKnownHostsFile=/dev/null \
            "${ssh_user}@${TARGET_IP}"
    fi
    echo "[OK] Túnel local en segundo plano establecido en http://127.0.0.1:${LOCAL_TUNNEL_PORT}"
}

tunnel_down() {
    echo "[+] Verificando túneles activos en puerto ${LOCAL_TUNNEL_PORT}..."
    local pids
    pids=$(pgrep -f "ssh.*-L ${LOCAL_TUNNEL_PORT}:127.0.0.1:${REMOTE_TUNNEL_PORT}" || true)
    if [[ -n "${pids}" ]]; then
        echo "[+] Terminando procesos de túnel SSH (PIDs: ${pids})..."
        kill ${pids} 2>/dev/null || sudo kill -9 ${pids} 2>/dev/null || true
    fi
    echo "[OK] Túneles SSH cerrados."
}

status_check() {
    echo "=================================================================="
    echo " Estado del Entorno en Kali Linux ($(date '+%Y-%m-%d %H:%M:%S'))"
    echo "=================================================================="
    echo "[1] IPs Locales (Kali): $(hostname -I)"
    echo "[2] Conectividad hacia Target (${TARGET_IP}):"
    if ping -c 1 -W 2 "${TARGET_IP}" > /dev/null 2>&1; then
        echo "    [OK] Target ${TARGET_IP} responde ICMP."
    else
        echo "    [!] Target ${TARGET_IP} no responde ICMP."
    fi
    echo "[3] Bloque CETILAB en ${HOSTS_FILE}:"
    if grep -q "${MARKER_BEGIN}" "${HOSTS_FILE}"; then
        sed -n "/${MARKER_BEGIN}/,/${MARKER_END}/p" "${HOSTS_FILE}"
    else
        echo "    [Limpio] No hay entradas de CETILAB en ${HOSTS_FILE}."
    fi
    echo "[4] Puntos de montaje activos (/mnt):"
    mount | grep -E "${NFS_MOUNT}|${SMB_MOUNT}" || echo "    [Limpio] Sin montajes NFS/SMB activos."
    echo "[5] Túneles locales en puerto ${LOCAL_TUNNEL_PORT}:"
    ss -tlnp 2>/dev/null | grep ":${LOCAL_TUNNEL_PORT} " || echo "    [Limpio] Puerto ${LOCAL_TUNNEL_PORT} libre."
    echo "=================================================================="
}

ACTION="${1:-status}"
shift || true

case "${ACTION}" in
    init|hosts-up)
        hosts_up
        ;;
    hosts-down)
        hosts_down
        ;;
    mount-nfs)
        mount_nfs
        ;;
    mount-smb)
        mount_smb "$@"
        ;;
    umount-all)
        umount_all
        ;;
    fix-ssh-key)
        fix_ssh_key "$@"
        ;;
    tunnel-up)
        tunnel_up "$@"
        ;;
    tunnel-down)
        tunnel_down
        ;;
    cleanup)
        tunnel_down
        umount_all
        hosts_down
        echo "[OK] Entorno de Kali Linux restaurado completamente a cero (Zero-Footprint)."
        ;;
    status|*)
        status_check
        ;;
esac
