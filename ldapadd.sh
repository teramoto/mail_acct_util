#!/bin/bash

HOST="ldap.ray.co.jp" 
DARG="cn=Manager,dc=ray,dc=co,dc=jp" 
BARG="dc=ray,dc=co,dc=jp" 
PS="ray00" 
usage_exit() {
        echo "Usage: $0  [-h host ] ldif_file" 1>&2
        exit 1
}

while getopts h:D:p:b:a OPT
do 
  case $OPT in 
 h) HOST="$OPTARG"
    DARG="cn=admin,dc=ray,dc=jp"
    BARG="dc=ray,dc=jp"
    PS="ji96JBCgD77" 
    ;;
 
 p) PS=$OPTARG
    DARG="cn=Manager,dc=ray,dc=jp"
    BARG="dc=ray,dc=jp"
    ;;
 b) BARG=$OPTARG
    ;;

 D) DARG=$OPTARG
    ;;

 \?) usage_exit 
    ;;
  esac
done 
shift `expr $OPTIND - 1`

  echo "ldapadd -D $DARG  -h $HOST -w $PS -b $BARG $1"
  ldapadd -x -D $DARG -h $HOST -w $PS -f $1
