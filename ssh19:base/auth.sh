#!/bin/bash
authconfig --enableshadow --enablelocauthorize \
	   --enableldap --enableldapauth \
	   --ldapserver='ldapserver' --ldapbase='dc=edt,dc=org' \
       --enablemkhomedir  --updateall