# Regla 04: Guía Operativa y Playbook para Modelos Rápidos (Gemini 3.8 Flash / Haiku / etc.)

Esta regla es **de cumplimiento obligatorio** para garantizar que cualquier modelo de IA (incluyendo modelos ligeros o de baja latencia como **Gemini 3.8 Flash**) opere el laboratorio sin errores de sintaxis, sin bloqueos por comandos interactivos y con la misma precisión que un modelo de razonamiento pesado.

---

## 1. Regla de Oro: NUNCA Ejecutes Comandos Interactivos Bloqueantes desde el Agente

Cuando el agente invoca herramientas de terminal (`run_command`), **NO hay un humano frente a ese `stdin`**. Por lo tanto:

- **PROHIBIDO ejecutar desde el agente**:
  - `read -p ...` (nunca corras los scripts interactivos `scripts/practicas/*.sh` directamente desde la herramienta del agente sin modo batch).
  - `sudo` sin `-n` o sin el flag `-AsRoot` de `kali-bridge.ps1`.
  - Sesiones interactivas abiertas (`ssh user@host` sin comando remoto, `ftp`, `mysql`, `mongosh` sin `--eval`, `nano`, `vim`, `top`, `less`).
- **OBLIGATORIO usar siempre `scripts/kali-bridge.ps1`**:
  - `kali-bridge.ps1` codifica automáticamente tu comando en **Base64 UTF-8** y lo envía a `/bin/bash` en Kali o en `ubuntuServer`. Así **nunca tendrás errores de comillas, escapes, tuberías (`|`) ni redirecciones (`>`)** entre PowerShell y Bash.

---

## 2. Recetario Exacto de Comandos (Copy-Paste One-Liners)

Usa **siempre** estos 5 comandos desde PowerShell en `D:\Orchestrator\VBox-AI-Agent` en lugar de construir llamadas manuales a `VBoxManage.exe`:

### A. Verificar estado del puente, de Kali y conexión al Target
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action status
```

### B. Ejecutar cualquier comando en `Kali-Linux-CLI` (como usuario `kali`)
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action exec -Command "hostname -I && ls -la /home/kali"
```

### C. Ejecutar comandos con privilegios `root` en `Kali-Linux-CLI` (`-AsRoot`)
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action exec -AsRoot -Command "cat /etc/hosts && mount | grep /mnt"
```

### D. Ejecutar comandos directamente dentro del Target `ubuntuServer` (`192.168.1.101`)
Salta automáticamente a través de Kali usando `/home/kali/developer.key` (o las credenciales que indiques):
```powershell
# Como usuario 'developer' (por defecto con llave SSH)
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action exec-target -Command "id && hostname && ss -tlnp"

# Como otro usuario del target con contraseña (vía sshpass en Kali)
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action exec-target -TargetUser "ftpuser" -TargetPassword "<PASS>" -Command "id && ls -la ~"
```

### E. Reparar/Reinicializar el puente si las VMs se reiniciaron
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\kali-bridge.ps1 -Action bootstrap
```

---

## 3. Flujo de Trabajo Asistido para Nuevas Prácticas (Metodología Dual Agente + Usuario)

Cada vez que el usuario te pida ayuda con una nueva práctica (ej. Práctica 7, 8, etc.), sigue **exactamente estos 4 pasos en orden**:

1. **Paso 1 — Reconocimiento y Prueba Silenciosa (Agente)**:
   - Usa `kali-bridge.ps1 -Action exec` o `-Action exec-target` para explorar el servicio, probar los comandos de la práctica en tiempo real y obtener la salida exacta sin interrumpir al usuario.
2. **Paso 2 — Creación del Script Interactivo en `/home/kali/repo/scripts/practicas/`**:
   - Crea o actualiza el script `scripts/practicas/practica-XX.sh` en el repositorio Windows.
   - Gracias a la carpeta compartida `/mnt/vbox_repo` (enlazada en `/home/kali/repo`), el archivo **aparece instantáneamente dentro de Kali Linux**.
   - Incluye la función `pause_for_screenshot` (`read -r -p`) después de cada comando clave y el modo `--cleanup` para revertir cambios (Reglas 02 y 03).
3. **Paso 3 — Documentación del Reporte con Salidas Reales (`docs/practicas/`)**:
   - Crea o actualiza `docs/practicas/practica-XX-*.md` pegando las salidas reales que obtuviste en el Paso 1 y dejando los marcadores `> 📸 **[Espacio para Captura de Pantalla #XX: ...]**`.
4. **Paso 4 — Instrucción Final Clara para el Usuario**:
   - Dile al usuario exactamente qué comando único debe correr en su ventana GUI de terminal en Kali para tomar sus capturas de pantalla:
     ```bash
     sudo /home/kali/repo/scripts/practicas/practica-XX.sh
     ```
