# AGENTS.md — Arquitectura y Contexto Maestro del Laboratorio (VBox-AI-Agent)

> **Propósito**: Fuente única de verdad (Single Source of Truth) para cualquier agente de IA de terminal (Antigravity CLI, Claude Code, etc., incluyendo modelos rápidos como **Gemini 3.8 Flash**) que opere sobre este repositorio de automatización de infraestructura y orquestación de laboratorios de ciberseguridad.

---

## 1. Arquitectura del Repositorio

```text
D:\Orchestrator\VBox-AI-Agent\
├── AGENTS.md                        # Contexto maestro, topología de red, activos y reglas operativas
├── CLAUDE.md                        # Puente de compatibilidad y comandos rápidos para Claude Code
├── README.md                        # Descripción general del repositorio
├── .agent/
│   ├── rules/                       # Reglas operativas modulares (cargadas automáticamente)
│   │   ├── 01-vbox-host-windows.md  # Gestión de VBoxManage.exe en Windows, estados, modos y snapshots
│   │   ├── 02-idempotencia-y-limpieza.md # Idempotencia (/etc/hosts, /mnt, SSH) y limpieza Zero-Footprint
│   │   ├── 03-evidencia-y-reportes.md    # Pausas interactivas (read -p) y formato de evidencias
│   │   └── 04-guia-operativa-modelos-rapidos.md # Playbook determinista para Gemini 3.8 Flash y modelos rápidos
│   └── skills/                      # Skills modulares del agente (Progressive Disclosure)
│       ├── vbox-controller/SKILL.md # Control de hipervisor VirtualBox, red NAT y snapshots
│       ├── kali-bridge/SKILL.md     # Puente autónomo Windows <-> Kali <-> ubuntuServer
│       ├── lab-state-manager/SKILL.md # Preparación y reversión idempotente dentro de Kali Linux
│       └── report-generator/SKILL.md  # Estandarización de reportes Markdown en docs/practicas/
├── scripts/
│   ├── vbox-controller.ps1          # CLI PowerShell para gestionar VMs, red NAT y snapshots
│   ├── kali-bridge.ps1              # CLI PowerShell para ejecución remota en Kali y salto a ubuntuServer
│   ├── kali-lab-state.sh            # Script Bash idempotente para /etc/hosts, /mnt, llaves y túneles
│   ├── vm-snap.ps1                  # Captura directa de framebuffer VirtualBox en Windows
│   ├── vm-snap.sh                   # Wrapper Bash para capturas directas de framebuffer
│   ├── build-report.ps1             # Compilador Pandoc a DOCX y subida/conversión a Google Docs
│   ├── build-report.sh              # Wrapper Bash para compilar reporte con Pandoc
│   ├── new-practice-report.ps1      # Generador de reportes Markdown y scripts interactivos de prácticas
│   └── practicas/                   # Scripts Bash específicos por práctica académica (montados en /home/kali/repo)
│       ├── parcial1_practicas_01_a_06.sh # Flujo idempotente de Prácticas 1 a 6 y su reversión
│       ├── auto_hack_parte2.sh           # Suite interactiva de Post-Explotación (Prácticas 1 a 4 - Parte 2)
│       └── revert_hack_parte2.sh         # Limpieza Zero-Footprint de Post-Explotación (Parte 2)
├── auto_hack_parte2.sh              # Script principal de Post-Explotación en raíz
├── revert_hack_parte2.sh            # Script de reversión de Post-Explotación en raíz
├── Analisis_Practicas_PostExplotacion_Lozano.md # Análisis técnico Cyber Kill Chain y matriz CLI vs GUI
└── docs/
    ├── assets/                      # Evidencias fotográficas / screenshots organizados por práctica
    │   ├── practica1_nosqli/        # Capturas de Port Forwarding y NoSQLi
    │   ├── practica2_privesc_files/ # Capturas de escalada de privilegios y transferencia de archivos
    │   ├── practica3_ssh_keys/      # Capturas de gestión de identidades y llaves SSH
    │   └── practica4_gtfobins_ctf/  # Capturas de GTFOBins y Meow CTF resuelto por Lozano
    ├── reportes/                    # Reportes ejecutivos consolidados en Markdown y DOCX
    │   ├── REPORTE_PRACTICAS_LOZANO.md # Reporte maestro estructurado con evidencias
    │   ├── Analisis_Practicas_PostExplotacion_Lozano.md # Copia en reportes del análisis Cyber Kill Chain
    │   └── Reporte_Final_Lozano.docx   # Documento DOCX generado listo para Google Docs
    └── practicas/
        ├── _template.md             # Plantilla base estandarizada para reportes
        ├── parcial-01-practicas-01-a-06.md # Reporte consolidado de las Prácticas 1 a 6 con salidas reales
        └── evidencias/              # Capturas de pantalla y salidas recolectadas por práctica
```

---

## 2. Topología e Inventario Técnico del Laboratorio

### 2.1 Host Anfitrión (Hypervisor Host)
- **Sistema Operativo**: Windows
- **Hipervisor**: Oracle VirtualBox `7.2.16r174877`
- **Binario Principal**: `C:\Program Files\Oracle\VirtualBox\VBoxManage.exe`
- **Directorio Raíz de Trabajo**: `D:\Orchestrator\VBox-AI-Agent` (montado en vivo dentro de Kali en `/mnt/vbox_repo` y `/home/kali/repo`).

### 2.2 Red Virtual de Laboratorio (`cetipracticas`)
Detectada mediante `VBoxManage list natnets` y escaneo `nmap -sn 192.168.1.0/24`:
- **Nombre de Red NAT**: `cetipracticas`
- **Segmento IPv4**: `192.168.1.0/24`
- **Gateway VirtualBox**: `192.168.1.1` (MAC: `52:54:00:12:35:00`)
- **Servidor DHCP VirtualBox**: `192.168.1.2` (MAC: `08:00:27:02:40:0B` — Activo)
- **Regla Port-Forwarding Activa**: `kali-ssh` (`TCP 127.0.0.1:2222 -> 192.168.1.5:22`)
- **IPv6**: `No`

### 2.3 Máquinas Virtuales Registradas en el Host

| Rol en Laboratorio | Nombre Exacto VM (`VBoxManage`) | UUID | Recursos | MAC (`nic1`) | Modo de Inicio | IP en `cetipracticas` | Snapshot Activo |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Atacante / Orquestadora Interna** | `Kali-Linux-CLI` | `930ba4aa-afd4-4414-a2a9-b03b76bdc62c` | 4096 MB RAM, 2 vCPUs | `0800273D6562` | `gui` | `192.168.1.5` (detectada vía Guest Additions) / `192.168.1.4` | `snapshot-base-puente-activo` |
| **Objetivo (Target)** | `ubuntuServer` | `9f4e173c-8db8-4fe4-b215-72cb0988112a` | 2048 MB RAM, 1 vCPU | `080027BE9A22` | `headless` | `192.168.1.101` (fija) + `192.168.1.3` (DHCP en `enp0s3`) | `snapshot-base-puente-activo` |

---

## 3. Detalle de Activos y Hallazgos del Laboratorio

### 3.1 Máquina Atacante / Orquestadora Interna (`Kali-Linux-CLI`)
- **Sistema**: Kali Linux (`6.19.14+kali-amd64`, con interfaz gráfica GUI habilitada y VirtualBox Guest Additions `7.2.8_Debian`).
- **Puente con Host Windows**:
  - Usuario: `kali` / Contraseña: `kali` (`sudo NOPASSWD` habilitado en `/etc/sudoers.d/kali-agent`).
  - Servicio `ssh` activo (`systemctl is-active ssh` = `active`) con llave Ed25519 autorizada desde Windows (`workspace/.ssh/kali_agent_ed25519`).
  - Carpeta compartida del repositorio montada en `/mnt/vbox_repo` y enlazada en `/home/kali/repo`.
- **Arsenal y Herramientas Clave Utilizadas**:
  - **Reconocimiento y Escaneo**: `nmap` (`7.99`), `dig` (`9.20.23`), `gobuster` (`3.8.2`), `snmpwalk`.
  - **Auditoría Web y Proxy**: `Burp Suite` + navegador con extensión `FoxyProxy`.
  - **Enumeración y Acceso a Recursos**: `smbmap` (`1.10.7`), clientes `ftp`, `nfs-common` (`showmount`, `mount.nfs`), `cifs-utils` (`mount.cifs`), `openssh-client` (`ssh`, `scp`).
  - **Cracking y Post-Explotación**: `John the Ripper` (`john`, `ssh2john`, `zip2john`), `python3` (`python3 -m http.server`).

### 3.2 Máquina Objetivo (`ubuntuServer`)
- **Sistema**: Ubuntu Server 22.04.5 LTS (`cetipracticas` — Kernel `5.15.0-187-generic x86_64`)
- **IPs en `enp0s3`**: `192.168.1.101` (Fija principal) y `192.168.1.3` (Secundaria DHCP)
- **Dominios Principales**:
  - `cetilab.local` (SOA Serial `2026081801`, contacto `root.cetilab.local`)
  - `admin-backup`
- **Subdominios Identificados vía Transferencia de Zona DNS AXFR (11 subdominios)**:
  1. `app.cetilab.local` (VHOST HTTP activo — Status 200, Size 1233)
  2. `db-mongo.cetilab.local`
  3. `db-mysql.cetilab.local`
  4. `files.cetilab.local`
  5. `ftp.cetilab.local`
  6. `mail.cetilab.local`
  7. `nfs.cetilab.local`
  8. `ns1.cetilab.local`
  9. `snmp.cetilab.local`
  10. `ssh.cetilab.local`
  11. `www.cetilab.local`

#### Superficie de Servicios Expuestos y Locales en `ubuntuServer` (`192.168.1.101`)

| Puerto / Protocolo | Interfaz Escucha | Servicio | Versión / Detalle Técnico |
| :--- | :--- | :--- | :--- |
| **21 / TCP** | `*` (`0.0.0.0`) | FTP | `vsftpd 3.0.5` (Activo para cargas de archivos según `nota_desarrollo.txt`) |
| **22 / TCP** | `0.0.0.0` | SSH | `OpenSSH 8.9p1 Ubuntu 3ubuntu0.16` |
| **25 / TCP** | `0.0.0.0` | SMTP | `Postfix smtpd` (`CN=cetipracticas`) |
| **53 / TCP & UDP** | `192.168.1.101` | DNS | `ISC BIND 9.18.39-0ubuntu0.22.04.4` (Vulnerable a `AXFR` en `cetilab.local`) |
| **80 / TCP** | `*` (`0.0.0.0`) | HTTP | `Apache httpd 2.4.52 ((Ubuntu))` — *"Portal Interno CETI"* + VHOST `app.cetilab.local` |
| **111 / TCP & 2049 / TCP** | `0.0.0.0` | RPCBind / NFS | Exportación NFS `/srv/nfs/respaldos_ti` (Contiene llave SSH `developer.key`) |
| **139 / TCP & 445 / TCP** | `0.0.0.0` | Samba SMB | `Samba smbd 4` (`CETIPRACTICAS`) — Recurso `archivos_ti` (`READ ONLY` vía *Null Session*) |
| **161 / UDP** | `0.0.0.0` | SNMP | `SNMP v2c` (`public` expone en `sysLocation`: `NFS_EXPORT: /srv/nfs/respaldos_ti \| TARGET_USER: developer`) |
| **8080 / TCP** | `0.0.0.0` | HTTP | `nginx 1.18.0 (Ubuntu)` — *"Portal Interno CETI"* |
| **3306 / 33060 / TCP** | `127.0.0.1` (Local) | MySQL | Base de datos MySQL escuchando solo en loopback |
| **5000 / TCP** | `127.0.0.1` (Local) | HTTP Interno | Panel interno de administración MongoDB (accesible vía SSH Local Port Forwarding `-L 5000:127.0.0.1:5000`) |
| **27017 / TCP** | `127.0.0.1` (Local) | MongoDB | Instancia local de MongoDB |

#### Artefactos, Credenciales y Usuarios Identificados
- **Usuarios del Sistema Objetivo**:
  - `root` (`UID 0`)
  - `lozano` (`UID 1000`)
  - `ftpuser` (`UID 1001`)
  - `developer` (`UID 1002`) — Acceso SSH directo sin passphrase mediante `/home/kali/developer.key`.
- **Contenido de `/mnt/archivoCompartido` (`//app.cetilab.local/archivos_ti`)**:
  - `nota_desarrollo.txt`:
    > *"Recuerden limpiar las carpetas públicas antes de producción. El servicio FTP sigue activo para cargas de archivos grandes."*
  - `respaldo_credenciales.txt`:
    > *"Servicio FTP de respaldo activado. Usuario asignado: `ftpuser` | Hash de contraseña (MD5): `a280e5e01b339097e189dbe574f8ff16` | Nota: La clave sigue el estándar interno de contraseñas de prueba."*
- **Hashes MD5 Identificados / Crackeados (John the Ripper - máscara `Ceti?d?d?d?d`)**:
  - Hash Práctica 6 (`fcd065c1541dc1f64cce023e9f9e4900`) $\rightarrow$ **`Ceti2245`**
  - Hash de `ftpuser` en `respaldo_credenciales.txt`: `a280e5e01b339097e189dbe574f8ff16`

---

## 4. Regla Estricta de Sanitización de Identidad (Obligatoria)

- **Sanitización Global**: En toda configuración, metadatos, reportes, scripts, capturas o transcripciones, cualquier nombre o alias similar a `eduardo`, `lalo`, `nuño`, `Eduma15` o `jorge` debe reemplazarse estrictamente por **`lozan`** o **`lozano`**.
- Ningún reporte generado ni evidencia registrada debe contener los nombres o alias vetados.

---

## 5. Sistema de Capturas Directas de Framebuffer (`vm-snap`)

Para garantizar capturas limpias del laboratorio sin interferencia de ventanas del host anfitrión:
- Script PowerShell: `.\scripts\vm-snap.ps1 -VmName "Kali-Linux-CLI" -OutputPath "docs/assets/<carpeta>/<archivo>.png"`
- Script Bash: `./scripts/vm-snap.sh "Kali-Linux-CLI" "docs/assets/<carpeta>/<archivo>.png"`
- Directorios organizados de evidencias:
  - `docs/assets/practica1_nosqli/`
  - `docs/assets/practica2_privesc_files/`
  - `docs/assets/practica3_ssh_keys/`
  - `docs/assets/practica4_gtfobins_ctf/`

---

## 6. Pipeline de Compilación y Reportes hacia Google Docs (`build-report` & MCP)

- Script PowerShell: `.\scripts\build-report.ps1` (admite `-SkipUpload` para generar solo el archivo local DOCX).
- Script Bash: `./scripts/build-report.sh [input] [output] [--skip-upload]`.
- Flujo de procesamiento:
  1. Toma `docs/reportes/REPORTE_PRACTICAS_LOZANO.md`.
  2. Compila con Pandoc a `docs/reportes/Reporte_Final_Lozano.docx` resolviendo assets en `./docs/assets/`.
  3. Si `@googleworkspace/cli` (`gws`) está autenticado (`gws auth login` o `gws auth setup`), sube el archivo a Google Drive con `mimeType: application/vnd.google-apps.document`, transformándolo en un documento editable en Google Docs con imágenes, tablas y bloques formateados.
- Servidor MCP: Configurado en `~/.gemini/config/mcp_config.json` y `~/.claude.json` mediante `gws mcp -s docs,drive`.

---

## 7. Reglas Operativas Obligatorias

Todo agente debe cumplir estrictamente las 4 reglas modulares definidas en `.agent/rules/`:

1. **[`.agent/rules/01-vbox-host-windows.md`](./.agent/rules/01-vbox-host-windows.md)**: Operación de VirtualBox en Windows (`vbox-controller.ps1`).
2. **[`.agent/rules/02-idempotencia-y-limpieza.md`](./.agent/rules/02-idempotencia-y-limpieza.md)**: Idempotencia (`/etc/hosts`, `/mnt`, llaves SSH) y limpieza Zero-Footprint.
3. **[`.agent/rules/03-evidencia-y-reportes.md`](./.agent/rules/03-evidencia-y-reportes.md)**: Sanitización, capturas `vm-snap`, pipeline `build-report` y pausas `read -p`.
4. **[`.agent/rules/04-guia-operativa-modelos-rapidos.md`](./.agent/rules/04-guia-operativa-modelos-rapidos.md)**: Playbook determinista de comandos `kali-bridge.ps1` para modelos rápidos (como Gemini 3.8 Flash).
