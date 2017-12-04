#!/bin/sh 

# Questo script carica un db su di un altro ripristinando pero' la
# tabella sysusers del db destinazione

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME

# Un controllo che esistano i volume group sybase. Non fa mai male
if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then 
        exit 0;
fi

if [ $1a = a ] ; then
   echo "Usage: dare come parametro il nome del db destinazione"
   echo "il dump del db sorgente deve avere path /sybased1/dump/DB_TO_LOAD.dmp"
   echo "quindi gia' unzippato"
   exit 0
fi

DBESISTENTE=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF  | awk '/DBESISTENTE/ { print $2; }'
select "DBESISTENTE",count(*) from sysdatabases where name="$1"
go
exit
EOF`

echo $DBESISTENTE

if [ $DBESISTENTE -eq 0 ] ; then
   echo "Il db " $1 " non esiste."
   exit 0
fi
