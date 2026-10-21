---
name: lab-state-manager
description: >-
  Gestiona de forma idempotente la preparación y limpieza del entorno dentro de
  Kali Linux para las prácticas contra ubuntuServer (192.168.1.101). Úsese
  cuando se necesite configurar o limpiar /etc/hosts (cetilab.local y sus
  subdominios), montar o desmontar unidades NFS (/srv/nfs/respaldos_ti) y SMB
  (archivos_ti) en /mnt/, ajustar permisos chmod 600 y chown en llaves SSH o
  administrar túneles SSH en segundo plano (puerto 5000).
---

# Skill: Lab State Manager (`lab-state-manager`)

Esta skill implementa la [Regla 02 (Idempotencia y Limpieza)](../../rules/02-idempotencia-y-limpieza.md) dentro de `Kali-Linux-CLI` a través del script maestro [`scripts/kali-lab-state.sh`](../../../scripts/kali-lab-state.sh).

## Capacidades del Gestor de Estado (`kali-lab-state.sh`)

1. **Gestión Idempotente de `/etc/hosts` (`hosts-up` / `hosts-down`)**:
   - Utiliza marcadores `# BEGIN CETILAB` y `# END CETILAB` para insertar o eliminar de forma atómica la resolución de `192.168.1.101`:
     - Dominios principales: `cetilab.local`, `admin-backup`
     - Subdominios DNS: `app.cetilab.local`, `db-mongo.cetilab.local`, `db-mysql.cetilab.local`, `files.cetilab.local`, `ftp.cetilab.local`, `mail.cetilab.local`, `nfs.cetilab.local`, `ns1.cetilab.local`, `snmp.cetilab.local`, `ssh.cetilab.local`, `www.cetilab.local`.
2. **Montaje y Desmontaje Seguro en `/mnt/` (`mount-nfs`, `mount-smb`, `umount-all`)**:
   - Crea puntos de montaje idempotentes (`/mnt/nfs_respaldos` para `192.168.1.101:/srv/nfs/respaldos_ti` y `/mnt/smb_archivos` para `//192.168.1.101/archivos_ti`).
   - Verifica `mountpoint -q` antes de montar o desmontar.
3. **Aseguramiento de Llaves SSH (`fix-ssh-key`)**:
   - Aplica `chmod 600` y `chown $(id -u):$(id -g)` sobre cualquier llave privada extraída (ej. para los usuarios `lozano`, `ftpuser`, `developer` o `root`).
4. **Control de Túneles Locales SSH en Segundo Plano (`tunnel-up` / `tunnel-down`)**:
   - Inicia el Local Port Forwarding `127.0.0.1:5000 -> 127.0.0.1:5000` (Panel interno MongoDB en `ubuntuServer`) usando `ssh -f -N -L 5000:127.0.0.1:5000`, verificando previamente que el puerto `5000` no esté ocupado y registrando el estado.
5. **Reversión Total (`cleanup`)**:
   - Cierra túneles SSH activos en el puerto 5000, detiene servidores HTTP temporales en Python, desmonta recursos en `/mnt/` y limpia el bloque `CETILAB` de `/etc/hosts`.

## Comandos de Uso en Kali Linux

```bash
# Dar permisos de ejecución al script
chmod +x ./scripts/kali-lab-state.sh

# 1. Preparación completa de entorno base (hosts + directorios de trabajo)
sudo ./scripts/kali-lab-state.sh init

# 2. Verificar estado actual en Kali (hosts, montajes, túneles, conectividad a 192.168.1.101)
./scripts/kali-lab-state.sh status

# 3. Montar recurso NFS /srv/nfs/respaldos_ti en /mnt/nfs_respaldos
sudo ./scripts/kali-lab-state.sh mount-nfs

# 4. Asegurar permisos de una llave SSH obtenida
./scripts/kali-lab-state.sh fix-ssh-key /tmp/id_rsa_lozano

# 5. Abrir túnel local al puerto 5000 (Panel MongoDB)
./scripts/kali-lab-state.sh tunnel-up lozano /tmp/id_rsa_lozano

# 6. Limpieza completa del entorno (Zero-Footprint)
sudo ./scripts/kali-lab-state.sh cleanup
```

## Pasos de Validación
1. Ejecutar `./scripts/kali-lab-state.sh status` antes y después de cada práctica.
2. Confirmar con `grep -c "BEGIN CETILAB" /etc/hosts` que el valor sea `1` (cuando está activo) o `0` (tras ejecutar `cleanup`).
