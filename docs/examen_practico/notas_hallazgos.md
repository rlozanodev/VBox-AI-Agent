# Bitácora Viva de Hallazgos — Examen Práctico de Ciberseguridad

**Auditor / Alumno**: Roberto Lozano  
**Fecha de Inicio**: 21 de Octubre de 2026  
**Objetivo**: Auditoría de Caja Negra / Examen Práctico de Hacking Ético  
**Estado Actual**: `INICIAL - RECONOCIMIENTO ACTIVO`

---

## 1. Direccionamiento y Segmento de Red

| Parámetro | Valor Identificado | Método de Detección | Notas / Estado |
| :--- | :--- | :--- | :--- |
| **IP Máquina Atacante (Kali)** | *Pendiente* (`ip a` / `hostname -I`) | Local | `DESCONOCIDO` |
| **Interfaz Activa Kali** | *Pendiente* (`eth0` / `enp0s3`) | Local | `DESCONOCIDO` |
| **Segmento de Red Local** | *Pendiente* (`/24`) | ARP / Interfaz | `DESCONOCIDO` |
| **Gateway / Enrutador** | *Pendiente* | `ip route` | `DESCONOCIDO` |
| **IP Objetivo (Target)** | *Pendiente* | `nmap -sn` / `arp-scan` | `DESCONOCIDO` |

---

## 2. Matriz de Puertos y Servicios Descubiertos (Target)

| Puerto | Protocolo | Servicio | Versión Detectada | Estado | Hipótesis / Siguiente Paso | Evidencia Asociada |
| :---: | :---: | :--- | :--- | :---: | :--- | :--- |
| *Por descubrir* | - | - | - | - | - | - |

---

## 3. Resolución de Nombres, Dominios y VHOSTs

| Hostname / Dominio | Tipo de Registro | IP Asociada | Fuente (DNS, AXFR, vhost) | Observaciones |
| :--- | :---: | :--- | :--- | :--- |
| *Por descubrir* | - | - | - | - |

---

## 4. Superficie Web y Rutas Descubiertas

- **Servidor Web Principal**: `DESCONOCIDO`
- **Cabeceras Relevantes**: `DESCONOCIDO`
- **Directorios / Archivos Clave**:
  - `Pendiente de fuzzing con gobuster/dirsearch/feroxbuster`
- **Formularios / Puntos de Entrada**: `DESCONOCIDO`

---

## 5. Recursos Compartidos y Almacenamiento (SMB / NFS / FTP / etc.)

| Servicio | Recurso / Share | Permisos | Contenido Relevante |
| :--- | :--- | :--- | :--- |
| *Por auditar* | - | - | - |

---

## 6. Identidades, Credenciales y Hashes

| Usuario | Tipo de Acceso | Secreto / Password / Hash | Crackeado / Verificado | Origen de la Credencial |
| :--- | :--- | :--- | :---: | :--- |
| *Por descubrir* | - | - | - | - |

---

## 7. Vectores de Post-Explotación y Escalada de Privilegios

- **Acceso Inicial**: `DESCONOCIDO`
- **Permisos Sudo (`sudo -l`)**: `DESCONOCIDO`
- **Binarios SUID / Capacidades (`getcap`)**: `DESCONOCIDO`
- **Tareas Cron / Procesos Internos**: `DESCONOCIDO`
- **Acceso Final (Root)**: `DESCONOCIDO`

---

## 8. Cronología de Ejecuciones y Acciones en Kali

| # | Hora (HH:MM) | Comando Ejecutado en Kali | Resultado Clave / Hallazgo | Captura Guardada |
| :-: | :---: | :--- | :--- | :--- |
| 1 | --:-- | *Esperando primera verificación de red* | - | - |
