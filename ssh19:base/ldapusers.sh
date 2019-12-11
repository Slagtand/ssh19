#!/bin/bash
# @slagtand ASIX M06 2019-2020
# creació homes usuaris ldap (hardcoded)
# -----------------------------------------------

llistaUsers="pere marta anna pau pere jordi"
for user in $llistaUsers
do
  #echo -e "$user\n$user" | smbpasswd -a $user
  line=$(getent passwd $user)
  uid=$(echo $line | cut -d: -f3)
  gid=$(echo $line | cut -d: -f4)
  homedir=$(echo $line | cut -d: -f6)
  echo "$user $uid $gid $homedir"
  if [ ! -d $homedir ]; then
    mkdir -p $homedir
    cp -ra /etc/skel/. $homedir
    chown -R $uid:$gid $homedir
  fi
done