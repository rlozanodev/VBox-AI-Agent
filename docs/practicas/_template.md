# Práctica {{NUMBER}}: {{TITLE}}

| Campo | Detalle |
| :--- | :--- |
| **Fecha** | {{DATE}} |
| **Máquina Origen (Atacante)** | `Kali-Linux-CLI` (`192.168.1.4`) |
| **Máquina Destino (Target)** | `ubuntuServer` (`192.168.1.101` / `cetilab.local`) |
| **Red Virtual** | NAT Network `cetipracticas` (`192.168.1.0/24`) |
| **Servicios Auditados** | {{SERVICES}} |
| **Herramientas Utilizadas** | {{TOOLS}} |

---

## 1. Objetivos de la Práctica

- **Objetivo General**: Documentar y ejecutar la auditoría técnica correspondiente a *{{TITLE}}* dentro del laboratorio controlado `cetipracticas`.
- **Objetivos Específicos**:
  1. Verificar el estado inicial e idempotencia del entorno (`Kali-Linux-CLI` y `ubuntuServer`).
  2. Ejecutar las pruebas de enumeración, análisis y explotación controlada con trazabilidad completa.
  3. Recolectar las evidencias visuales en cada punto de control (`read -p`).
  4. Restaurar el entorno a cero al finalizar la práctica.

---

## 2. Preparación del Entorno (Pre-Check)

### 2.1 Verificación en Host Windows (VirtualBox)
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\vbox-controller.ps1 -Action status
```

### 2.2 Inicialización Idempotente en Kali Linux
```bash
sudo ./scripts/kali-lab-state.sh init
./scripts/kali-lab-state.sh status
```

> 📸 **[Espacio para Captura de Pantalla #01: Verificación de IP en Kali (`192.168.1.4`), conectividad hacia `192.168.1.101` y bloque `CETILAB` en `/etc/hosts`]**
> ![Evidencia 01](./evidencias/practica-{{NUMBER}}/evidencia-01.png)

---

## 3. Desarrollo Técnico Paso a Paso

### Paso 1: Enumeración y Reconocimiento Inicial
**Descripción**:
Se verifica la disponibilidad de los servicios objetivo en `ubuntuServer` (`192.168.1.101`).

**Comando Ejecutado**:
```bash
# Reemplazar por el comando específico del Paso 1
nmap -sV -sC -p 21,22,25,53,80,111,139,445,2049,8080 192.168.1.101
```

**Resultado Esperado / Obtenido**:
```text
# Pegar aquí la salida relevante de la terminal
```

> 📸 **[Espacio para Captura de Pantalla #02: Salida de la enumeración inicial del servicio]**
> ![Evidencia 02](./evidencias/practica-{{NUMBER}}/evidencia-02.png)

---

### Paso 2: Interacción / Explotación del Servicio
**Descripción**:
Se analiza la configuración del servicio y se extrae la información o acceso requerido por la práctica.

**Comando Ejecutado**:
```bash
# Reemplazar por el comando específico del Paso 2
```

**Resultado Esperado / Obtenido**:
```text
# Pegar aquí la salida relevante de la terminal
```

> 📸 **[Espacio para Captura de Pantalla #03: Evidencia de acceso o hallazgo principal]**
> ![Evidencia 03](./evidencias/practica-{{NUMBER}}/evidencia-03.png)

---

## 4. Limpieza y Restauración del Entorno (Zero-Footprint)

Al concluir la recolección de evidencias, se ejecuta el procedimiento de reversión para desmontar unidades, cerrar túneles locales y limpiar `/etc/hosts`:

```bash
sudo ./scripts/kali-lab-state.sh cleanup
./scripts/kali-lab-state.sh status
```

> 📸 **[Espacio para Captura de Pantalla #04: Confirmación de limpieza del entorno (`status` limpio)]**
> ![Evidencia 04](./evidencias/practica-{{NUMBER}}/evidencia-04.png)

---

## 5. Conclusiones y Recomendaciones de Seguridad

| Hallazgo / Debilidad Identificada | Activo Afectado | Recomendación de Mitigación |
| :--- | :--- | :--- |
| *Pendiente de documentar* | `ubuntuServer` (`192.168.1.101`) | *Pendiente de documentar* |
