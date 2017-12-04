#!/bin/sh -x
#

. /home/sybase/.profile

DATA=$(/usr/bin/date +%Y%m%d)
ORA=$(/usr/bin/date +%H%M)

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

. /sis/SIS-AUX-Envsetting.Sybase.sh
# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 >/tmp/mon-numero-processi <<EOF
set nocount on
go
select \"NUMEROPROCESSI\",count(*) from sysprocesses where suid != 0            
go
quit
EOF

NUM_PROC_TROVATO=`grep NUMEROPROCESSI /tmp/mon-numero-processi | wc -l`

if [ $NUM_PROC_TROVATO -eq 1 ] ; then
   NUM_PROC=`grep NUMEROPROCESSI /tmp/mon-numero-processi | awk '{ print $2; }'`
   #echo $NUM_PROC
   echo $DATA-$ORA $NUM_PROC >>$UTILITY_DIR/out/log-numero-processi
fi

# Se non funzionasse non ha importanza tanto e' solo un reporting
#else
#   echo Errore non ho il numero processi
#fi

rm /tmp/mon-numero-processi
