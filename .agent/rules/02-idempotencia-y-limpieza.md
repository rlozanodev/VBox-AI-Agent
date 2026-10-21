# Regla 02: Idempotencia y Limpieza del Entorno (Zero-Footprint)

Todo script de configuración, preparación de laboratorio, explotación o recolección ejecutado en Kali Linux o en el Host Windows debe ser **estrictamente idempotente** y contar con su **contraparte de reversión/limpieza**.

## 1. Principio de Idempotencia
Un script debe producir exactamente el mismo estado final sin importar si se ejecuta 1 o 10 veces consecutivas, sin duplicar entradas ni generar errores por recursos preexistentes:

- **Archivo `/etc/hosts` en Kali Linux**:
  - **PROHIBIDO** usar `echo "192.168.1.101 cetilab.local" >> /etc/hosts` sin verificación previa.
  - **OBLIGATORIO** gestionar las entradas mediante un bloque delimitado (`# BEGIN CETILAB` ... `# END CETILAB`) o verificar con `grep -q` / reemplazar con `sed` antes de insertar:
    ```bash
    # Eliminar bloque previo si existe y reinsertar limpio
    sudo sed -i '/# BEGIN CETILAB/,/# END CETILAB/d' /etc/hosts
    cat << 'EOF' | sudo tee -a /etc/hosts > /dev/null
    # BEGIN CETILAB
    192.168.1.101 cetilab.local admin-backup app.cetilab.local db-mongo.cetilab.local db-mysql.cetilab.local files.cetilab.local ftp.cetilab.local mail.cetilab.local nfs.cetilab.local ns1.cetilab.local snmp.cetilab.local ssh.cetilab.local www.cetilab.local
    # END CETILAB
    EOF
    ```

- **Puntos de Montaje (`/mnt/`)**:
  - Usar siempre `mkdir -p /mnt/<recurso>` para evitar fallos si el directorio ya existe.
  - Verificar con `mountpoint -q /mnt/<recurso>` antes de montar unidades NFS (`/srv/nfs/respaldos_ti`) o recursos SMB (`archivos_ti`).

- **Permisos y Llaves SSH**:
  - Asegurar de forma determinista que toda llave privada descargada o extraída reciba permisos restrictivos antes de utilizarse:
    ```bash
    chmod 600 "$SSH_KEY_PATH"
    chown "$(id -u):$(id -g)" "$SSH_KEY_PATH"
    ```

- **Túneles SSH y Procesos en Segundo Plano**:
  - Antes de abrir un túnel de Local Port Forwarding (ej. puerto `5000` hacia `127.0.0.1:5000`), verificar con `ss -tlnp | grep ':5000'` o `lsof -i :5000` si el puerto local ya está en uso.

## 2. Contraparte Obligatoria de Limpieza (`cleanup` / `rollback`)
Todo script o flujo de práctica debe incluir una función o modo `--cleanup` (o script par `cleanup_*.sh`) que restaure el entorno a cero:
1. **Cerrar túneles activos**: Terminar procesos SSH en segundo plano o servidores temporales (`python3 -m http.server`).
2. **Desmontar recursos remotos**: Ejecutar `sudo umount -l /mnt/<recurso>` si está montado y eliminar directorios temporales vacíos.
3. **Limpiar `/etc/hosts`**: Remover el bloque `# BEGIN CETILAB` ... `# END CETILAB` cuando se solicite restaurar el estado original.
4. **Restaurar artefactos temporales**: Limpiar archivos de trabajo sensibles en `/tmp/` conservando únicamente las evidencias exportadas en la carpeta de reportes del proyecto.
