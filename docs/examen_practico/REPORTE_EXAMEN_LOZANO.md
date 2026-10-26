---
title: "Reporte Técnico de Auditoría de Seguridad — Examen Práctico"
subtitle: "Evaluación Integral de Penetración y Pruebas de Intrusión"
author: "Roberto Lozano"
date: "21 de Octubre de 2026"
geometry: "margin=2.5cm"
output:
  pdf_document:
    toc: true
    number_sections: true
---

# Resumen Ejecutivo

El presente documento constituye el informe técnico de la auditoría de seguridad y prueba de intrusión realizada sobre el entorno de evaluación práctica. La prueba se ejecutó bajo la modalidad de **Caja Negra (Black-box)**, sin conocimiento previo de direccionamiento IP, topología, servicios expuestos ni credenciales de acceso.

El objetivo principal consistió en identificar la superficie de ataque, evaluar vulnerabilidades en los servicios de red y aplicaciones web, conseguir acceso inicial al sistema y determinar vectores de escalada de privilegios locales hasta alcanzar el control total del servidor (*root*).

---

# Alcance y Entorno de Evaluación

- **Auditor Responsable**: Roberto Lozano
- **Plataforma Atacante**: Kali Linux (`Kali-Linux-CLI`)
- **Red de Evaluación**: Red interna de laboratorio VirtualBox
- **Objetivo**: Máquina virtual de evaluación (Ubuntu Server)
- **Metodología Empleada**: Estándar de Ejecución de Pruebas de Penetración (PTES) y Cyber Kill Chain.

```
Reconocimiento -> Escaneo -> Enumeración -> Explotación -> Escalada de Privilegios -> Evidencia
```

---

# Fase 1: Reconocimiento de Red y Descubrimiento del Objetivo

## 1.1 Identificación de la Red Local
Se procedió a identificar la configuración de red de la estación de auditoría para determinar el segmento de trabajo activo y la puerta de enlace.

```bash
# Salida de identificación de interfaz y tabla de enrutamiento
```

## 1.2 Barrido de Host Activos
Se ejecutó un barrido de red para localizar la dirección IP asignada a la máquina objetivo.

```bash
# Salida de descubrimiento de hosts
```

> **Hallazgo**: Dirección IP del objetivo identificada en `[IP_TARGET]`.

![Descubrimiento de Red y Activos](assets/01_red.png)

---

# Fase 2: Escaneo de Puertos y Detección de Servicios

## 2.1 Escaneo Completo de Puertos TCP/UDP
Se realizó un escaneo exhaustivo para identificar puertos abiertos y versiones de servicios en ejecución.

```bash
# Salida de escaneo de puertos (Nmap)
```

## 2.2 Matriz de Servicios Expuestos

| Puerto | Protocolo | Servicio | Versión Identificada | Estado |
| :---: | :---: | :--- | :--- | :---: |
| *Por registrar* | - | - | - | - |

![Escaneo y Detección de Servicios](assets/02_servicios.png)

---

# Fase 3: Enumeración Detallada de la Superficie de Ataque

## 3.1 Resolución DNS y Descubrimiento de Virtual Hosts (VHOSTs)
Se evaluó el servicio de resolución de nombres en búsqueda de zonas transferibles (AXFR) o subdominios internos.

```bash
# Salida de enumeración DNS / Dig / Gobuster vhost
```

## 3.2 Auditoría de la Aplicación Web
Se analizó el comportamiento del servicio web en los puertos identificados, inspeccionando encabezados HTTP, tecnologías subyacentes y rutas ocultas.

```bash
# Salida de fuzzing web / inspección HTTP
```

![Enumeración Web y Rutas](assets/03_web_enum.png)

## 3.3 Enumeración de Servicios de Archivos / Compartidos
Se inspeccionaron servicios de intercambio de datos (SMB, NFS, FTP, etc.) en busca de sesiones nulas, archivos de configuración o llaves expuestas.

```bash
# Salida de enumeración de recursos compartidos
```

![Recursos Compartidos y Archivos](assets/04_recursos.png)

---

# Fase 4: Explotación y Acceso Inicial

## 4.1 Vector de Compromiso
Se documenta el vector de ataque que permitió la obtención de acceso al sistema objetivo.

```bash
# Comandos y respuestas de explotación
```

## 4.2 Establecimiento de Shell
Detalle del acceso interactivo obtenido en el sistema.

```bash
# Identificación de contexto inicial (id, whoami, uname -a)
```

![Acceso Inicial al Objetivo](assets/05_acceso_inicial.png)

---

# Fase 5: Post-Explotación y Escalada de Privilegios

## 5.1 Enumeración Interna del Sistema
Auditoría interna de configuraciones locales, permisos de sudo, binarios SUID y procesos en ejecución.

```bash
# Enumeración interna (sudo -l, suid, cron)
```

## 5.2 Vector de Escalada de Privilegios
Descripción del mecanismo implementado para elevar privilegios hasta la cuenta de superusuario (`root`).

```bash
# Ejecución del vector de escalada
```

## 5.3 Confirmación de Control Total (*Proof of Concept*)
Obtención de bandera final o evidencia del acceso como `root`.

```bash
# id, whoami, captura de flag
```

![Escalada a Root y Control Total](assets/06_root_escalada.png)

---

# Matriz Consolidada de Hallazgos y Remediaciones

| ID | Hallazgo / Vulnerabilidad | Severidad | Impacto | Recomendación de Mitigación |
| :-: | :--- | :---: | :--- | :--- |
| **H-01** | *Por documentar* | Crítica | Acceso inicial no autorizado | - |
| **H-02** | *Por documentar* | Alta | Escalada de privilegios local | - |

---

# Conclusión Técnica

La auditoría de seguridad permitió verificar las debilidades presentes en el entorno evaluado, transitando de manera metódica desde la fase de reconocimiento a ciegas hasta la obtención de privilegios máximos de administración. Las evidencias y trazas documentadas demuestran el vector de ataque explotado y sustentan las recomendaciones de remediación propuestas.

**Firma del Auditor**:  
Roberto Lozano  
*Analista de Auditoría de Sistemas y Seguridad Ofensiva*
