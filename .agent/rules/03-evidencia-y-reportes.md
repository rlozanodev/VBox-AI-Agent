# Regla 03: Recolección de Evidencias y Generación de Reportes Académicos

Los flujos automatizados de este laboratorio tienen como propósito documentar y respaldar prácticas académicas y técnicas de ciberseguridad. La automatización nunca debe ocultar la salida crítica ni avanzar sin permitir la toma de evidencias.

## 1. Pausas Interactivas para Capturas de Pantalla (`read -p`)
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
- Si el script soporta un modo desatendido (`--non-interactive` o `--batch`), la función `pause_evidence` puede omitir el `read -p` pero **debe guardar automáticamente** la salida del comando en un archivo de bitácora dentro de `docs/practicas/evidencias/`.

## 2. Trazabilidad en Terminal
- Antes de ejecutar cada comando técnico en un script de práctica, imprimir en consola el comando exacto que se está ejecutando (por ejemplo: `echo -e "\n[+] Ejecutando: nmap -sV -sC -p- 192.168.1.101\n"`), de modo que la captura de pantalla muestre tanto el comando invocado como su resultado.
- Incluir marca de tiempo (`date '+%Y-%m-%d %H:%M:%S'`) y contexto de red (`hostname -I`) al inicio de la ejecución de cada práctica.

## 3. Estándar de Documentación en `docs/practicas/`
Cada práctica documentada en `docs/practicas/` debe seguir la estructura estandarizada del `report-generator`:
1. **Metadatos y Objetivo**: Nombre de la práctica, fecha, máquinas involucradas (`Kali-Linux-CLI` -> `ubuntuServer`) y objetivo técnico.
2. **Pre-requisitos y Preparación**: Estado de la red `cetipracticas`, configuración de `/etc/hosts` y verificación de conectividad.
3. **Desarrollo Paso a Paso**:
   - Explicación técnica de la fase.
   - Bloque de código con el comando exacto ejecutado.
   - Bloque con la salida real o esperada.
   - Marcador explícito para captura de pantalla: `> 📸 **[Espacio para Captura de Pantalla #XX: <Descripción de la evidencia>]**`.
4. **Limpieza y Restauración**: Confirmación de ejecución del procedimiento de limpieza (Regla 02).
5. **Conclusiones / Hallazgos de Seguridad**: Resumen de vulnerabilidades, malas configuraciones encontradas y recomendaciones de mitigación.
