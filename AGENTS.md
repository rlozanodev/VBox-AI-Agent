# AGENTS.md — Arquitectura y Contexto Maestro del Laboratorio (VBox-AI-Agent)

> **Propósito**: Fuente única de verdad (Single Source of Truth) para cualquier agente de IA de terminal (Antigravity CLI, Claude Code, etc., incluyendo modelos rápidos como **Gemini 3.8 Flash**) que opere sobre este repositorio de automatización de infraestructura, orquestación de laboratorios y **copiloto interactivo para examen práctico de ciberseguridad**.

---

## 1. Arquitectura del Repositorio

```text
D:\Orchestrator\VBox-AI-Agent\
├── AGENTS.md                        # Contexto maestro, topología de red, reglas y protocolo de examen
├── CLAUDE.md                        # Puente de compatibilidad y comandos rápidos para Claude Code
├── README.md                        # Descripción general del repositorio
├── .agent/
│   ├── rules/                       # Reglas operativas modulares (cargadas automáticamente)
│   │   ├── 01-vbox-host-windows.md  # Gestión de VBoxManage.exe en Windows, estados y snapshots
│   │   ├── 02-idempotencia-y-limpieza.md # Idempotencia (/etc/hosts, /mnt, SSH) y limpieza Zero-Footprint
│   │   ├── 03-evidencia-y-reportes.md    # Sanitización, capturas vm-snap y compilación build-report
│   │   ├── 04-modo-examen-interactivo.md # Protocolo de Copiloto Interactivo (Examen a ciegas)
│   │   └── 05-guia-operativa-modelos-rapidos.md # Playbook determinista kali-bridge para modelos rápidos
│   └── skills/                      # Skills modulares del agente (Progressive Disclosure)
│       ├── vbox-controller/SKILL.md # Control de hipervisor VirtualBox, red NAT y snapshots
│       ├── kali-bridge/SKILL.md     # Puente autónomo Windows <-> Kali <-> target
│       ├── lab-state-manager/SKILL.md # Preparación y reversión idempotente dentro de Kali Linux
│       └── report-generator/SKILL.md  # Estandarización de reportes Markdown y evidencias
├── scripts/                         # Utilidades transversales y genéricas del laboratorio
│   ├── vbox-controller.ps1          # CLI PowerShell para gestionar VMs, red NAT y snapshots
│   ├── kali-bridge.ps1              # CLI PowerShell para ejecución remota en Kali y salto SSH
│   ├── vm-snap.ps1                  # Captura directa de framebuffer VirtualBox en Windows
│   ├── vm-snap.sh                   # Wrapper Bash para capturas directas de framebuffer
│   ├── build-report.ps1             # Compilador Pandoc a DOCX y subida/conversión a Google Docs
│   └── build-report.sh              # Wrapper Bash para compilar reporte con Pandoc
├── docs/                            # Espacio de trabajo del Examen Práctico Actual
│   └── examen_practico/
│       ├── assets/                  # Capturas cronológicas (01_red.png, 02_servicios.png, etc.)
│       ├── notas_hallazgos.md       # Bitácora viva de reconocimiento y superficie de ataque
│       └── REPORTE_EXAMEN_LOZANO.md # Reporte formal de auditoría en redacción continua
├── archive/                         # Archivo histórico organizado
│   └── parcial_2_practicas/
│       ├── scripts/                 # Scripts específicos de prácticas anteriores (auto_hack, etc.)
│       ├── evidencias_md/           # Bitácoras y notas históricas (Registro de Evidencias CTF, etc.)
│       ├── assets/                  # Capturas de pantalla históricas (practicas 1 a 4, etc.)
│       └── reportes/                # Reportes generados del Parcial 2 (REPORTE_PRACTICAS_LOZANO, etc.)
└── workspace/                       # Llaves e infraestructura del host
    └── .ssh/                        # Llaves Ed25519 de conexión a Kali Linux
```

---

## 2. Topología de Infraestructura Base

### 2.1 Host Anfitrión (Hypervisor Host)
- **Sistema Operativo**: Windows
- **Hipervisor**: Oracle VirtualBox `7.2.16r174877`
- **Binario Principal**: `C:\Program Files\Oracle\VirtualBox\VBoxManage.exe`
- **Directorio Raíz de Trabajo**: `D:\Orchestrator\VBox-AI-Agent` (montado dentro de Kali en `/mnt/vbox_repo` y `/home/kali/repo`).

### 2.2 Red Virtual de Laboratorio (`cetipracticas`)
- **Nombre de Red NAT**: `cetipracticas`
- **Segmento IPv4**: `192.168.1.0/24` (o segmento configurado en la red NAT de evaluación)
- **Gateway VirtualBox**: `192.168.1.1` (o gateway asignado)
- **Servidor DHCP VirtualBox**: `192.168.1.2` (activo)
- **Regla Port-Forwarding Activa**: `kali-ssh` (`TCP 127.0.0.1:2222 -> Kali:22`)

### 2.3 Máquina Atacante / Auditora (`Kali-Linux-CLI`)
- **Rol**: Orquestadora interna y plataforma de pruebas.
- **Usuario**: `kali` / `kali` (`sudo NOPASSWD` habilitado).
- **Conectividad**: SSH activo hacia puerto 22 (`127.0.0.1:2222` desde el host).
- **Montaje del Repositorio**: Disponible en tiempo real en `/home/kali/repo`.

---

## 3. Estado de Evaluación Actual: MODO EXAMEN PRÁCTICO (Black-Box)

> [!IMPORTANT]
> Para el **Examen Práctico Actual**, todas las variables inician en estado **`DESCONOCIDO`**. Prohibido codificar IPs, usuarios o contraseñas en scripts sin verificación previa.

### 3.1 Variables de la Máquina Objetivo (A descubrir dinámicamente)
- **Nombre de VM en VirtualBox**: A auditar mediante `VBoxManage list vms`.
- **IP Objetivo (`TARGET_IP`)**: `DESCONOCIDO` (descubrimiento con barrido ARP / Nmap).
- **Puertos Abiertos (`OPEN_PORTS`)**: `DESCONOCIDO` (descubrimiento con escaneo TCP/UDP).
- **Nombres de Dominio / VHOSTs**: `DESCONOCIDO` (descubrimiento con DNS AXFR / Fuzzing Host).
- **Superficie Web y Rutas**: `DESCONOCIDO` (inspección de encabezados, HTTP status, gobuster).
- **Almacenamiento Compartido**: `DESCONOCIDO` (auditoría SMB, NFS, FTP).
- **Usuarios y Credenciales**: `DESCONOCIDO` (auditoría e identidades).
- **Vectores de Escalada**: `DESCONOCIDO` (inspección sudo, suid, capabilities, cron).

---

## 4. Protocolo de Operación: Copiloto Interactivo (Human-in-the-Loop)

Dado que no se conocen los servicios de la máquina objetivo, el agente opera en un ciclo de interacción corto y determinista:

```
[ Paso A: Propuesta Unitaria ] 
            ↓
[ Paso B: Lectura y Razonamiento Analítico ]
            ↓
[ Paso C: Actualización Inmediata de Bitácora ]
            ↓
[ Paso D: Captura de Evidencia y Redacción ]
```

1. **Paso A — Propuesta de Verificación Unitaria**:
   - El agente propone **un solo comando o verificación lógica a la vez**.
   - Explica brevemente qué se espera observar en la salida.
2. **Paso B — Lectura y Razonamiento de Salida**:
   - El usuario corre el comando en Kali (o mediante `kali-bridge.ps1`) y suministra la salida.
   - El agente analiza exhaustivamente versiones, encabezados, códigos y anomalías.
3. **Paso C — Actualización de Bitácora Viva**:
   - El agente actualiza `docs/examen_practico/notas_hallazgos.md` con los nuevos activos y formula la siguiente hipótesis.
4. **Paso D — Captura de Evidencia y Documentación en Tiempo Real**:
   - Para hallazgos clave, se ejecuta `vm-snap.ps1` guardando en `docs/examen_practico/assets/0X_nombre.png`.
   - Se redacta la sección correspondiente en `docs/examen_practico/REPORTE_EXAMEN_LOZANO.md`.

---

## 5. Caso de Estudio de Referencia Histórica (Parcial 2 — `cetilab.local`)

> [!NOTE]
> Esta sección se preserva únicamente como **referencia metodológica del estilo de evaluación del docente** (flujo de evaluación: barrido de red -> transferencia de zona DNS -> auditoría web -> almacenamiento compartido -> escalada de privilegios). **No asumir que la máquina de examen tiene estos mismos servicios o credenciales.**

- **Sistema Anterior**: Ubuntu Server 22.04 (`192.168.1.101`).
- **Dominio Anterior**: `cetilab.local` (11 subdominios vía AXFR).
- **Servicios Anteriores**:
  - FTP (`21`), SSH (`22`), SMTP (`25`), DNS BIND (`53` con AXFR permitido).
  - HTTP Apache (`80`) con VHOST `app.cetilab.local`.
  - NFS (`111`/`2049`) en `/srv/nfs/respaldos_ti` (con llave `developer.key`).
  - SMB (`139`/`445`) en `archivos_ti` (Null Session permitida).
  - Web interno en loopback (`5000`) vulnerable a NoSQL Injection.
  - Binario local `admin-backup` con capabilities/SUID para escalada a root.
- **Hashes de Referencia Crackeados**:
  - `Ceti2245` (máscara `Ceti?d?d?d?d`).
  - Hash de `ftpuser`: `a280e5e01b339097e189dbe574f8ff16`.

---

## 6. Regla Estricta de Sanitización de Identidad (Obligatoria)

- **Sanitización Global**: En toda configuración, metadatos, reportes, scripts, capturas o transcripciones, cualquier nombre o alias similar a `eduardo`, `lalo`, `nuño`, `Eduma15` o `jorge` debe reemplazarse estrictamente por **`lozan`** o **`lozano`**.
- Autor oficial en todos los documentos: **Roberto Lozano**.

---

## 7. Sistema de Capturas Directas de Framebuffer (`vm-snap`)

- Script PowerShell: `powershell -ExecutionPolicy Bypass -File .\scripts\vm-snap.ps1 -VmName "Kali-Linux-CLI" -OutputPath "docs/examen_practico/assets/<archivo>.png"`
- Script Bash: `./scripts/vm-snap.sh "Kali-Linux-CLI" "docs/examen_practico/assets/<archivo>.png"`
- Nomenclatura estándar del examen:
  - `01_red.png`
  - `02_servicios.png`
  - `03_web_enum.png`
  - `04_recursos.png`
  - `05_acceso_inicial.png`
  - `06_root_escalada.png`

---

## 8. Pipeline de Compilación y Reportes (`build-report` & Google Docs)

- Compilar documento DOCX local:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\scripts\build-report.ps1 -InputFile "docs/examen_practico/REPORTE_EXAMEN_LOZANO.md" -OutputFile "docs/examen_practico/Reporte_Examen_Lozano.docx" -SkipUpload
  ```
- Compilar y subir/convertir automáticamente a Google Docs:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\scripts\build-report.ps1 -InputFile "docs/examen_practico/REPORTE_EXAMEN_LOZANO.md" -OutputFile "docs/examen_practico/Reporte_Examen_Lozano.docx"
  ```

---

## 9. Reglas Operativas Modulares Obligatorias

Todo agente debe cumplir estrictamente las 5 reglas modulares en `.agent/rules/`:
1. **[`.agent/rules/01-vbox-host-windows.md`](./.agent/rules/01-vbox-host-windows.md)**: Operación de VirtualBox en Windows (`vbox-controller.ps1`).
2. **[`.agent/rules/02-idempotencia-y-limpieza.md`](./.agent/rules/02-idempotencia-y-limpieza.md)**: Idempotencia y limpieza Zero-Footprint.
3. **[`.agent/rules/03-evidencia-y-reportes.md`](./.agent/rules/03-evidencia-y-reportes.md)**: Sanitización, capturas `vm-snap` y pipeline `build-report`.
4. **[`.agent/rules/04-modo-examen-interactivo.md`](./.agent/rules/04-modo-examen-interactivo.md)**: Protocolo de Copiloto Interactivo para Examen Práctico (Black-Box).
5. **[`.agent/rules/05-guia-operativa-modelos-rapidos.md`](./.agent/rules/05-guia-operativa-modelos-rapidos.md)**: Playbook determinista `kali-bridge.ps1` para modelos rápidos.
