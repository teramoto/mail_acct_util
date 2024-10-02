#!/bin/bash

HOST="ldap.ray.co.jp" 
DARG="cn=Manager,dc=ray,dc=co,dc=jp" 
BARG="dc=ray,dc=co,dc=jp" 
PS="ray00" 
usage_exit() {
        echo "Usage: $0 [-w] [-m] [-H ldapURI ] [-p password ] filter " 1>&2
        exit 1
}

while getopts wmh:p:b:a OPT
do 
  case $OPT in 
 w) wifi="TRUE" 
    mail="FALSE" 
    ;;
 m) mail="TRUE"
    wifi="FALSE"
    ;;

 h) HOST="$OPTARG"
    PS="TaKa1na1d7e" 
    DARG="cn=readonly,dc=ray,dc=jp"
    BARG="dc=ray,dc=jp"
    ;;
 
 p) PS=$OPTARG 
    DARG="cn=Manager,dc=ray,dc=jp" 
    BARD="dc=ray,dc=jp" 
    ;; 
 b) BARG="$OPTARG" 
    ;;

 \?) usage_exit 
    ;;
  esac
done 
shift `expr $OPTIND - 1`

if [ "$wifi" = "TRUE" ]; then  
  echo "Processing wifi accounts...." 
  BARG="ou=Services,dc=ray,dc=co,dc=jp" 
  echo "ldapsearch -x -D $DARG  -h $HOST -w $PS -b $BARG $1"
  ldapsearch -x -D $DARG -h $HOST -w $PS -b $BARG $1
elif [ "$mail" = "TRUE" ]; then 
  echo "Processing mail accounts...." 
  BARG="ou=Mail,dc=ray,dc=co,dc=jp" 
  echo "ldapsearch -x -D $DARG  -H $HOST -w $PS -b $BARG $1"
  ldapsearch -x -D $DARG -H $HOST -w $PS -b $BARG $1
else 
  echo "ldapsearch -x -D $DARG -H $HOST -w $PS -b $BARG $1"
  ldapsearch -x -D $DARG -h $HOST -w $PS -b $BARG $1
fi  
