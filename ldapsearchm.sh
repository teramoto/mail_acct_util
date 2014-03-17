#!/bin/bash
echo $1 
ldapsearch -x -D cn=Manager,dc=ray,dc=co,dc=jp -h ldap.ray.co.jp -w ray00 -b ou=Mail,dc=ray,dc=co,dc=jp $1 
