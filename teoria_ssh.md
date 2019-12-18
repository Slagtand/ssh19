# SSH

Ssh funciona amb parelles de claus pública/privada, per una connexió entre hosts.

Tipus de claus: `rsa, dsa, ...`

Al instal·lar-se els paquets de client (`openssh-client`) i de servidor (`openssh-server`) ja es creen les claus de host. De totes formes, es creen amb `ssh-keygen -A` (per exemple quan ho instal·lem a docker no es fa automàticament).

## Claus

Les claus privades tindràn uns permisos `0600`, mentres que les públiques `0644`.

```bash
-rw------- 1 debian debian 1,8K jun 17 10:11 id_rsa
-rw-r--r-- 1 debian debian  393 jun 17 10:11 id_rsa.pub
-rw------- 1 debian debian 5,2K dic 10 18:09 known_hosts
-rw------- 1 debian debian 5,2K dic 10 18:11 authorized_keys
```

## Host

Les claus de host es troben a `/etc/ssh/`, junt amb la configuració.

## Usuari

Les claus d'usuari es troben al home, en una carpeta oculta `~/.ssh/`.

* `known_host`: Aquí es guarden els hosts coneguts. El primer cop que ens connectem a un altre host ens pregunta si confiem en la info (fingerprint) que ens dona.

* `authorized_keys`: claus públiques d'usuaris.

## Autenticació

La autenticació es realitza en dos passes, primer identifica el **host** i després **l'usuari**.

### Host

**Host** és el primer en autenticar. Al establi la connexió el host remot envia el seu fingerprint al local i li pregunta si és amb qui vol connectar. Si es així, envia la seva clau pública al local.

Exemple de fingerprint:

```bash
ssh-keygen -l -f /etc/ssh/ssh_host_rsa_key.pub 
2048 SHA256:rY7+fOVHZ0PAab05HhBwGht0ZdFN60nCucU/xeXT2Mg no comment (RSA)
```

### Usuari

**Usuari** és el segón en autenticar-se, i té 2 formes d'autenticar-se:

* Ficant sempre la contrasenya en cada connexió.

* Automàticament, amb una clau pública de l'usuari que es guarda al host **remot** al fitxer `authorized_keys`.
  
  ```bash
  ssh-keygen # generem la clau si és necessari
  ssh-copy-id user@iphostremot # enviar-la al remot
  ```
  
  ```bash
  # També la podem copiar directament amb scp
  scp .ssh/id_rsa.pub user@iphostremo:.ssh/authorized_keys
  ```

## Transferència de fitxers

```bash
# Generem un fitxer local amb el resultat d'un ls remot
ssh local1@172.20.0.3 ls -la > file.txt
# Generem un fitxer remot amb el resultat d'un ls
ssh local1@172.20.0.3 "ls -la > file.txt"
# Comprimim localment i ho guardem en remot
tar cvf - /boot | ssh local1@172.20.0.3 "cat - > boot.tar"
# Copiem un fitxer local a un remot amb scp
scp file1.txt local1@172.20.0.3:./file1.txt
```

```bash
# Podem fer servir sshfs per a montar directoris remots
sshfs local1@172.20.0.3: /tmp/mnt
fusermount -u /tmp/mnt # amb fusermount podem desmontar sent l'usuari, no hem de ser root com l'umount

# També podem connectar-nos des de un explorador de fitxers
sftp://local1@172.20.0.3/home/local1
```

## Client

El client ssh té 3 nivells de configuració. Van per ordre descendent, tenint més importancia el nivell anterior. 

1. `command line`: La línia de comandes és la que té més importància. Se li passen les opcions amb `-o`.

2. `.ssh/config`: La configuració específica de l'usuari al seu home.

3. `/etc/ssh/ssh_config`: La configuració global.

Això vol dir que se li aplicarà la configuració global, però si té un altre nivell de configuració més alt prevaleix aquesta. El mateix per la configuració de l'user, té més importància si indiquem alguna per la línia de comandes.

* Exemple de configuració:
  
  ```bash
  # Especifiquem el host amb el seu nom
  Host localhost
      VisualHostKey no
  
  # Qualsevol host
  Host *
      VisualHostKey yes
  
  # Especifiquem el host amb la seva ip
  Host 192.168.80.252
      VisualHostKey no
      PasswordAuthentication no
  ```

* Si un host coincideix en diferents filtres, se li aplica el que més li assembli.

## Servidor

El servidor té la seva configuració a `/etc/ssh/sshd_conf`. 

També obre un pid per cada configuració oberta i es troba a `/var/run/sshd.pid`.

* Llista d'opcions a tindre en compte:
  
  ```bash
  port 2022 # El port per on escolta
  listenAdress <ip por donde entrar> # Indiquem la ip per on podem entrar
  MaxSessions # Sessions màximes 
  MaxAuthTries # número d'intents de ficar la password
  UsePam # Fer servir pam
  ```






