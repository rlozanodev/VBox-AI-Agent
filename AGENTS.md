# AGENTS.md — Arquitectura y Contexto Maestro del Laboratorio (VBox-AI-Agent)

> **Propósito**: Fuente única de verdad (Single Source of Truth) para cualquier agente de IA de terminal (Antigravity CLI, Claude Code, etc.) que opere sobre este repositorio de automatización de infraestructura y orquestación de laboratorios de ciberseguridad.

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
│   │   └── 03-evidencia-y-reportes.md    # Pausas interactivas (read -p) y formato de evidencias
│   └── skills/                      # Skills modulares del agente (Progressive Disclosure)
│       ├── vbox-controller/SKILL.md # Control de hipervisor VirtualBox, red NAT y snapshots
│       ├── kali-bridge/SKILL.md     # Puente Windows <-> Kali Linux (SSH Port-Forwarding / SharedFolder)
│       ├── lab-state-manager/SKILL.md # Preparación y reversión idempotente dentro de Kali Linux
│       └── report-generator/SKILL.md  # Estandarización de reportes Markdown en docs/practicas/
├── scripts/
│   ├── vbox-controller.ps1          # CLI PowerShell para gestionar VMs, red NAT y snapshots
│   ├── kali-bridge.ps1              # CLI PowerShell para comunicación y transferencia con Kali
│   ├── kali-lab-state.sh            # Script Bash idempotente para /etc/hosts, /mnt, llaves y túneles
│   ├── new-practice-report.ps1      # Generador de reportes Markdown y scripts interactivos de prácticas
│   └── practicas/                   # Scripts Bash específicos por práctica académica
│       └── parcial1_practicas_01_a_06.sh # Flujo idempotente de Prácticas 1 a 6 y su reversión
└── docs/
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
- **Directorio Raíz de Trabajo**: `D:\Orchestrator\VBox-AI-Agent`

### 2.2 Red Virtual de Laboratorio (`cetipracticas`)
Detectada mediante `VBoxManage list natnets` y escaneo `nmap -sn 192.168.1.0/24`:
- **Nombre de Red NAT**: `cetipracticas`
- **Segmento IPv4**: `192.168.1.0/24`
- **Gateway VirtualBox**: `192.168.1.1` (MAC: `52:54:00:12:35:00`)
- **Servidor DHCP VirtualBox**: `192.168.1.2` (MAC: `08:00:27:02:40:0B` — Activo)
- **IPv6**: `No`
- *(Nota: Existe también una red por defecto `NatNetwork` en `192.168.1.0/24`; todas las VMs del laboratorio operan exclusivamente sobre **`cetipracticas`**).*

### 2.3 Máquinas Virtuales Registradas en el Host

| Rol en Laboratorio | Nombre Exacto VM (`VBoxManage`) | UUID | Recursos | MAC (`nic1`) | Modo de Inicio | IP en `cetipracticas` | Snapshot Base |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Atacante / Orquestadora Interna** | `Kali-Linux-CLI` | `930ba4aa-afd4-4414-a2a9-b03b76bdc62c` | 4096 MB RAM, 2 vCPUs | `0800273D6562` | `gui` | `192.168.1.4` / `192.168.1.5` (DHCP) | `snapshot-base-inicial` (`aeca6787-9c6f-4fbc-ad55-9fe280c8cb18`) |
| **Objetivo (Target)** | `ubuntuServer` | `9f4e173c-8db8-4fe4-b215-72cb0988112a` | 2048 MB RAM, 1 vCPU | `080027BE9A22` | `headless` | `192.168.1.101` (fija) + `192.168.1.3` (DHCP en `enp0s3`) | `snapshot-base-inicial` (`d7a99a1b-66fe-46bb-b094-4118c52c893c`) |

---

## 3. Detalle de Activos y Hallazgos del Laboratorio

### 3.1 Máquina Atacante / Orquestadora Interna (`Kali-Linux-CLI`)
- **Sistema**: Kali Linux (con interfaz gráfica GUI habilitada, pese al sufijo `-CLI` en el nombre de registro de VirtualBox).
- **IP en el Segmento**: `192.168.1.4` / `192.168.1.5`
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

#### Superficie de Servicios Expuestos en `ubuntuServer` (`192.168.1.101`)

| Puerto / Protocolo | Servicio | Versión / Detalle Técnico |
| :--- | :--- | :--- |
| **21 / TCP** | FTP | `vsftpd 3.0.5` |
| **22 / TCP** | SSH | `OpenSSH 8.9p1 Ubuntu 3ubuntu0.16` (Banner de advertencia activo) |
| **25 / TCP** | SMTP | `Postfix smtpd` (`CN=cetipracticas`) |
| **53 / TCP & UDP** | DNS | `ISC BIND 9.18.39-0ubuntu0.22.04.4` (Vulnerable a transferencia de zona `AXFR` en `cetilab.local`) |
| **80 / TCP** | HTTP | `Apache httpd 2.4.52 ((Ubuntu))` — *"Portal Interno CETI"* + VHOST `app.cetilab.local` |
| **111 / TCP & 2049 / TCP** | RPCBind / NFSv3-v4 | Exportación NFS `/srv/nfs/respaldos_ti` (Contiene llave SSH `developer.key`) |
| **139 / TCP & 445 / TCP** | Samba SMB | `Samba smbd 4` (NetBIOS: `CETIPRACTICAS`) — Recurso `archivos_ti` (`READ ONLY` vía *Null Session* / `guest`) |
| **161 / UDP** | SNMP | `SNMP v2c` (Comunidad `public` expone en `sysLocation`: `NFS_EXPORT: /srv/nfs/respaldos_ti \| TARGET_USER: developer`) |
| **8080 / TCP** | HTTP | `nginx 1.18.0 (Ubuntu)` — *"Portal Interno CETI"* |
| **5000 / TCP (Localhost)** | HTTP Interno | Escucha en `127.0.0.1:5000` — Panel interno de administración MongoDB (accesible vía SSH Local Port Forwarding `-L 5000:127.0.0.1:5000`) |

#### Artefactos, Credenciales y Usuarios Identificados (Prácticas 1 a 6)
- **Usuarios del Sistema Objetivo**:
  - `root` (`UID 0`)
  - `jorge` (`UID 1000`)
  - `ftpuser` (`UID 1001`)
  - `developer` (`UID 1002`) — Acceso SSH verificado mediante llave privada `/home/kali/developer.key`.
- **Recurso SMB `//app.cetilab.local/archivos_ti`** (Montado en `/mnt/archivoCompartido` o `/mnt/smb_archivos`):
  - `nota_desarrollo.txt` (`298 bytes`)
  - `respaldo_credenciales.txt` (`368 bytes`)
- **Recurso NFS `cetilab.local:/srv/nfs/respaldos_ti`** (Montado en `/mnt/respaldos` o `/mnt/nfs_respaldos`):
  - `developer.key` (`1823 bytes` — llave privada SSH para el usuario `developer`).
- **Hash Cracked (Práctica 6 - John the Ripper)**:
  - Hash Raw-MD5: `fcd065c1541dc1f64cce023e9f9e4900`
  - Máscara utilizada: `Ceti?d?d?d?d`
  - Texto plano obtenido: **`Ceti2245`**

---

## 4. Reglas Operativas Obligatorias

Todo agente debe cumplir estrictamente las reglas modulares definidas en `.agent/rules/`:

1. **[`.agent/rules/01-vbox-host-windows.md`](./.agent/rules/01-vbox-host-windows.md) — Operación de VirtualBox en Windows**:
   - Invocar siempre `"C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"`.
   - Verificar estado de VMs y red `cetipracticas` antes de actuar.
   - Iniciar `Kali-Linux-CLI` en modo `gui` y `ubuntuServer` en modo `headless`.
   - Tomar snapshots de seguridad antes de cambios sensibles.
2. **[`.agent/rules/02-idempotencia-y-limpieza.md`](./.agent/rules/02-idempotencia-y-limpieza.md) — Idempotencia y Limpieza (Zero-Footprint)**:
   - Usar bloques delimitados `# BEGIN CETILAB` / `# END CETILAB` en `/etc/hosts` (prohibido duplicar líneas).
   - Verificar puntos de montaje en `/mnt/` antes de montar/desmontar.
   - Asegurar permisos `chmod 600` y `chown` en llaves SSH.
   - Proveer y ejecutar siempre el flujo de reversión/limpieza (`kali-lab-state.sh cleanup`).
3. **[`.agent/rules/03-evidencia-y-reportes.md`](./.agent/rules/03-evidencia-y-reportes.md) — Evidencia y Reportes Académicos**:
   - Incluir pausas interactivas (`read -p` vía `pause_evidence`) tras cada paso clave para permitir capturas de pantalla.
   - Documentar todas las prácticas bajo `docs/practicas/` siguiendo la plantilla estándar.

---

## 5. Flujo de Trabajo Estándar para Ejecutar una Práctica

1. **Verificación de Hipervisor (Host Windows)**:
   `powershell -ExecutionPolicy Bypass -File .\scripts\vbox-controller.ps1 -Action status`
2. **Encendido de Laboratorio**:
   `powershell -ExecutionPolicy Bypass -File .\scripts\vbox-controller.ps1 -Action start -VM all`
3. **Preparación Idempotente en Kali**:
   `sudo ./scripts/kali-lab-state.sh init`
4. **Ejecución Guiada con Pausas de Evidencia**:
   Ejecutar el script de la práctica en `scripts/practicas/practica-XX.sh`, tomando las capturas en cada `pause_evidence`.
5. **Documentación y Limpieza Zero-Footprint**:
   Registrar hallazgos en `docs/practicas/practica-XX-*.md` y ejecutar `sudo ./scripts/kali-lab-state.sh cleanup`.
