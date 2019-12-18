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

* En el cas de que coincideixin 2 configuracions de host i user, aplica la que troba primer.

* Quan al `Match` s'especifica un `host` es refereix al **host client** que s'està connectant. Quan s'especifica un `user` es refereix al **user local** del servidor **destí**.

```bash
# sshd_config
Match Host 172.19.0.1
        banner /etc/banner

Match user local2
        banner /etc/banner2
```

* Reload del servei
  
  ```bash
  kill -1 <num-servicio>
  ```

### Restriccions

Existeixen múltiples mecanismes de resitrcció per l'accés ssh. Alguns d'ells són globals per als serveis de xarxa i altres específics de sshd.

* Configuració del servidor sshd.

* Configuració de regles de PAM.

* Utilitzar TCP Wrappers com els fitxers host.allow i host.deny de la configuració global del sistema.

* Creació de Firewalls amb iptables.

#### Servidor sshd

Utilitza les següents opcions al fitxer `sshd_config`:

* `AllowUsers`: Users vàlids.

* `AllowGroups`: Grups vàlids

* `DenyUsers`: Users invàlids.

* `DenyGroups`: Grups invàlids.

Aquestes opcions tenen un ordre d'aplicar-se, sent l'anterior més important.

* `DenyUsers - AllowUsers - DenyGroups - AllowGroups`

Totes aquestes opcions van seguides d'una llista d'usuaris/grups separats per un espai. Sol els noms estàn permesos, si el patró forma `user@host` farà match amb un usuari d'un host determinat.

```bash
AllowUsers pere marta
AllowUsers pere@pc01.edt.org marta jordi@m06.cat
```

#### PAM

##### Pam_access

Amb el mòdul de pam `pam_access.so` es pot restringir l'accés modificant el fitxer `access.conf`.

`/etc/pam.d/sshd`

```bash
#%PAM-1.0
auth       substack     password-auth
auth       include      postlogin
account    required     pam_sepermit.so
account    required     pam_nologin.so
account    required     pam_access.so accessfile=/etc/security/access.conf
account    include      password-auth
password   include      password-auth
# pam_selinux.so close should be the first session rule
session    required     pam_selinux.so close
session    required     pam_loginuid.so
# pam_selinux.so open should only be followed by sessions to be executed in the user context
session    required     pam_selinux.so open env_params
session    required     pam_namespace.so
session    optional     pam_keyinit.so force revoke
session    include      password-auth
session    include      postlogin 
```

`/etc/security/access.conf`

```bash
# All other users should be denied to get access from all sources.
#- : ALL : ALL
# denegar a local2 el aceso a todo
- : local2 : ALL
```

Alguns exemples d'`access.conf`

```bash
# permiso : usuario/s : servicio/s : host
+ : root : crond :0 tty1 tty2 tty3 tty4 tty5 tty6
+ : root : 192.168.200.1 192.168.200.4 192.168.200.9
+ : root : 127.0.0.1
#El usuario root debería tener acceso desde la red 192.168.201. donde el término se evaluará mediante la coincidencia de cadenas. Pero podría ser mejor usar network / netmask en su lugar. El mismo significado de 192.168.201. es 192.168.201.0/24 o 192.168.201.0/255.255.255.0.
+ : root : 192.168.201.
+ : root : foo1.bar.org foo2.bar.org
- : root : ALL
# Los usuarios y los miembros de los administradores de netgroup deben tener acceso a todas las fuentes. Esto solo funcionará si el servicio netgroup está disponible.
+ : @admins foo : ALL
# User john and foo should get access from IPv6 host address.
+ : john foo : 2001:db8:0:101::1
- : ALL : ALL 
```

##### Pam_listfile

Amb el mòdul `pam_listfile.so` es pot restringir o donar accés a diferents usuaris.

```bash
pam_listfile.so item=[tty|user|rhost|ruser|group|shell]
                       sense=[allow|deny] file=/path/filename
                       onerr=[succeed|fail] [apply=[user|@group]] [quiet]
```

Al fitxer `sshd` de pam especifiquem quin tipus de dades trobarà al fitxer que li especifiquem a la ruta.

* `item`: tipus de dada que trobarà

* `sense`: què farà

* `file`: path del fitxer

```bash
#%PAM-1.0
auth       substack     password-auth
auth       include      postlogin
account    required     pam_sepermit.so
account    required     pam_nologin.so
account    required     pam_listfile.so  item=user sense=allow file=/etc/security/users.conf
account    include      password-auth
password   include      password-auth
# pam_selinux.so close should be the first session rule
session    required     pam_selinux.so close
session    required     pam_loginuid.so
# pam_selinux.so open should only be followed by sessions to be executed in the user context
session    required     pam_selinux.so open env_params
session    required     pam_namespace.so
session    optional     pam_keyinit.so force revoke
session    include      password-auth
session    include      postlogin 
```

`/etc/security/users.conf`

```bash

```
