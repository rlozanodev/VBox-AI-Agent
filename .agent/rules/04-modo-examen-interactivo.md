# Regla 04: Protocolo de Copiloto Interactivo para Examen Práctico (Black-Box)

> **Propósito**: Establecer el estándar operativo para la ejecución interactiva del Examen Práctico de Ciberseguridad. Dado que la máquina objetivo es desconocida (dirección IP, puertos, servicios, estructura web y credenciales no determinadas a priori), el agente opera estrictamente como **Copiloto Analítico en Tiempo Real** junto al usuario.

---

## 1. Separación de Contextos: Histórico vs. Examen Actual

1. **Caso de Estudio de Referencia (Parcial 2)**:
   - La máquina `192.168.1.101` (`cetilab.local`) y los vectores de ataque previos (NoSQLi en puerto 5000, llave NFS `developer.key`, hash MD5 `Ceti2245`, GTFOBins en `admin-backup`) son **únicamente referencias metodológicas históricas**.
   - Ilustran el estilo de evaluación del docente (flujo progresivo: red -> DNS -> web -> almacenamiento compartido -> privilegios locales), pero **ningún valor debe darse por sentado** en el examen.

2. **Entorno de Examen Práctico Actual**:
   - Todas las variables operativas arrancan en estado **`DESCONOCIDO`**:
     - `TARGET_IP`: Desconocida (descubrimiento vía barrido de red).
     - `DNS_DOMAINS / VHOSTS`: Desconocidos (descubrimiento vía AXFR / encabezados / fuzzing).
     - `OPEN_PORTS`: Desconocidos (descubrimiento vía Nmap TCP/UDP).
     - `WEB_SURFACE`: Desconocida (descubrimiento vía inspección HTTP y fuzzing de directorios).
     - `CREDENTIALS / USERS`: Desconocidos (descubrimiento durante la auditoría).
   - **Prohibido asumir valores fijos o generar scripts monolíticos a ciegas.**

---

## 2. Ciclo de Trabajo Interactivo (Human-in-the-Loop)

Para garantizar efectividad y control total, el agente y el auditor operan en un ciclo corto de 4 pasos continuos:

```
[ Paso A: Propuesta Unitaria ] 
            ↓
[ Paso B: Lectura y Razonamiento Analítico ]
            ↓
[ Paso C: Actualización Inmediata de Bitácora ]
            ↓
[ Paso D: Captura de Evidencia y Redacción ]
```

### Paso A — Propuesta de Verificación Unitaria (Un solo paso a la vez)
- El agente propone **exactamente un comando o verificación a la vez**.
- La propuesta debe incluir:
  - **Comando exacto** listo para ejecutar en Kali Linux.
  - **Objetivo analítico**: Qué se busca identificar y qué patrones o respuestas se esperan observar en la salida.

### Paso B — Lectura y Razonamiento Analítico de Salida
- El usuario ejecuta la instrucción en la terminal de Kali (o a través de `kali-bridge.ps1`) y suministra la salida.
- El agente analiza exhaustivamente el output:
  - Versiones precisas de software y tecnologías detectadas.
  - Códigos de respuesta HTTP, redirecciones y cabeceras de servidor.
  - Nombres de usuarios, rutas de archivos o comentarios en respuestas.
  - Errores de sintaxis o permisos denegados para reformular la hipótesis.

### Paso C — Actualización Automática de Bitácora Viva
- Inmediatamente tras validar un hallazgo, el agente actualiza:
  - Archivo: `docs/examen_practico/notas_hallazgos.md`.
  - Registra el nuevo activo en la tabla de direccionamiento, matriz de servicios, VHOSTs o credenciales.
  - Formula la siguiente hipótesis técnica fundamentada.

### Paso D — Captura de Evidencia y Documentación en Paralelo
- Cuando un paso genere evidencia crítica para la calificación (descubrimiento del target, escaneo Nmap, confirmación de vulnerabilidad, shell inicial o bandera root):
  - Se ejecuta o solicita la captura de pantalla mediante:
    ```powershell
    powershell -ExecutionPolicy Bypass -File .\scripts\vm-snap.ps1 -VmName "Kali-Linux-CLI" -OutputPath "docs/examen_practico/assets/XX_nombre.png"
    ```
  - Se redacta inmediatamente la sección correspondiente en `docs/examen_practico/REPORTE_EXAMEN_LOZANO.md`.

---

## 3. Regla Estricta de Sanitización Permanente
- Auditor y autor exclusivo: **Roberto Lozano** (`lozano` / `lozan`).
- Cualquier rastro o referencia a alias o nombres vetados está terminantemente prohibido en reportes, bitácoras y configuraciones.

---

## 4. Matriz de Evidencias Cronológicas Estandarizada

Las capturas deben seguir el orden cronológico estandarizado dentro de `docs/examen_practico/assets/`:
1. `01_red.png`: Descubrimiento de red y detección de la IP objetivo.
2. `02_servicios.png`: Escaneo exhaustivo Nmap y versiones de puertos abiertos.
3. `03_web_enum.png`: Auditoría web, encabezados, VHOSTs o fuzzing de rutas.
4. `04_recursos.png`: Enumeración de recursos de archivos (SMB, NFS, FTP o shares).
5. `05_acceso_inicial.png`: Explotación exitosa y obtención de shell interactiva.
6. `06_root_escalada.png`: Escalada de privilegios a `root` y captura de flag/PoC final.
