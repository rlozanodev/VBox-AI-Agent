# Regla 03: Recolección de Evidencias, Sanitización y Pipeline de Reportes

Los flujos automatizados de este laboratorio tienen como propósito documentar y respaldar prácticas académicas y técnicas de ciberseguridad. La automatización nunca debe ocultar la salida crítica ni avanzar sin permitir la toma de evidencias.

---

## 1. Regla Estricta de Sanitización de Nombres (Obligatoria)
- En **toda** configuración, metadatos de documento, plantillas de reporte, scripts de ejecución, capturas o transcripción de evidencias, cualquier nombre, usuario o alias similar a:
  - `eduardo`
  - `lalo`
  - `nuño`
  - `Eduma15`
  - `jorge`
- Debe ser **reemplazado obligatoriamente** por **`lozan`** o **`lozano`**.
- Ningún reporte generado debe contener los nombres o alias vetados.

---

## 2. Captura Directa de Framebuffer en VirtualBox (`vm-snap`)
Para evitar fallos al capturar pantalla del host (ventanas minimizadas, pérdida de foco, bordes del SO anfitrión), se utilizan los scripts wrappers de captura directa de framebuffer:

- **PowerShell (Windows)**:
  ```powershell
  .\scripts\vm-snap.ps1 -VmName "Kali-Linux-CLI" -OutputPath "docs/assets/practica1_nosqli/01_burp_login.png"
  ```
- **Bash (WSL / Git Bash)**:
  ```bash
  ./scripts/vm-snap.sh "Kali-Linux-CLI" "docs/assets/practica1_nosqli/01_burp_login.png"
  ```
- El comando base invocado directamente contra el hipervisor es:
  ```text
  VBoxManage controlvm "<VM_NAME>" screenshotpng "<OUTPUT_PATH>"
  ```
- Rutas estandarizadas de almacenamiento de evidencias:
  - `docs/assets/practica1_nosqli/`
  - `docs/assets/practica2_privesc_files/`
  - `docs/assets/practica3_ssh_keys/`
  - `docs/assets/practica4_gtfobins_ctf/`

---

## 3. Pipeline Automatizado de Reportes (Markdown -> DOCX -> Google Docs)
Los reportes técnicos generados en Markdown (`docs/reportes/REPORTE_PRACTICAS_LOZANO.md`) se compilan a DOCX y se sincronizan a Google Docs:

- **PowerShell (Windows)**:
  ```powershell
  .\scripts\build-report.ps1
  # Modo local sin subida a Drive:
  .\scripts\build-report.ps1 -SkipUpload
  ```
- **Bash**:
  ```bash
  ./scripts/build-report.sh
  # Modo local sin subida a Drive:
  ./scripts/build-report.sh docs/reportes/REPORTE_PRACTICAS_LOZANO.md docs/reportes/Reporte_Final_Lozano.docx --skip-upload
  ```
- **Conversión Pandoc**:
  ```bash
  pandoc docs/reportes/REPORTE_PRACTICAS_LOZANO.md -o docs/reportes/Reporte_Final_Lozano.docx --resource-path=.:docs:docs/reportes:docs/assets
  ```
- **Subida y Conversión a Google Docs (gws CLI / MCP)**:
  El CLI `@googleworkspace/cli` (`gws`) sube el archivo con `mimeType: application/vnd.google-apps.document`, convirtiéndolo de forma nativa a documento de Google Docs editable manteniendo texto formateado, bloques de código, tablas e imágenes incrustadas.
  - Para autenticar la cuenta de Google: `gws auth login` o `gws auth setup`.
  - Integración MCP: Servidor configurado con `gws mcp -s docs,drive`.

---

## 4. Pausas Interactivas para Capturas de Pantalla (`read -p`)
- Todo script Bash interactivo diseñado para ejecutar pasos de una práctica en Kali Linux debe estructurarse en **fases numeradas** claras.
- Al finalizar cada comando clave cuya salida deba ser capturada en pantalla, el script debe mostrar un banner visual claro e invocar una pausa interactiva:
  ```bash
  pause_evidence() {
      local step_num="$1"
      local description="$2"
      echo ""
      echo "=================================================================="
      echo " [EVIDENCIA #${step_num}] ${description}"
      echo " -> Toma la captura de pantalla de la salida anterior."
      echo "=================================================================="
      read -r -p "Presiona [ENTER] para continuar con el siguiente paso..." _
      echo ""
  }
  ```

---

## 5. Trazabilidad en Terminal
- Antes de ejecutar cada comando técnico en un script de práctica, imprimir en consola el comando exacto que se está ejecutando (por ejemplo: `echo -e "\n[+] Ejecutando: nmap -sV -sC -p- 192.168.1.101\n"`), de modo que la captura de pantalla muestre tanto el comando invocado como su resultado.
- Incluir marca de tiempo (`date '+%Y-%m-%d %H:%M:%S'`) y contexto de red (`hostname -I`) al inicio de la ejecución de cada práctica.

---

## 6. Estándar de Documentación en `docs/reportes/`
Cada reporte debe estructurarse de forma consolidada con:
1. Resumen ejecutivo y contexto previo (Prácticas 1 a 6 iniciales).
2. Práctica 1: Port Forwarding e Inyección NoSQL.
3. Práctica 2: Escalada básica de privilegios y transferencia de archivos.
4. Práctica 3: Persistencia, gestión de identidades y criptografía SSH.
5. Práctica 4: Post-explotación avanzada con GTFOBins y CTF HTB Meow (resuelto por Lozano).
6. Anexo de scripts de automatización e idempotencia.
