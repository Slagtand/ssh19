#!/bin/bash
# @slagtand ASIX M06 2019-2020
# startup.sh
# -----------------------------------------------

/opt/docker/install.sh && echo "Install Ok"

# Configuració ldap
/sbin/nscd && echo "nscd Ok"
/sbin/nslcd  && echo "nslcd OK"

# -------------------------------------------------------------------
# Creació dels directoris dels usuaris ldap 
# ha de ser un cop activat ldap/ nslcd...
bash /opt/docker/ldapusers.sh
# ===================================================================

/usr/bin/ssh-keygen -A
/sbin/sshd -D