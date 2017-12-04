#!/bin/sh -x
#

SOGLIA_CONNESSIONI=$1

. /home/sybase/.profile

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

# kill_per_troppe_connessioni.sh    

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 >/tmp/connections-report.nconn <<EOF
set nocount on
go
select \"NUMEROCONNESSIONI\",count(*) from sysprocesses where suid != 0       
go
quit
EOF

if [ `grep NUMEROCONNESSIONI /tmp/connections-report.nconn | wc -l` -eq 0 ] ; then
   echo kill_per_troppe_connessioni.sh
   echo Host `hostname`
   echo Collegamento al server non riuscito perobabilmente per troppe connessioni
   echo Provo comunque a eseguire il kill di tutte le connessioni
   NUMCONNESSIONI=999999
else 
   NUMCONNESSIONI=`grep NUMEROCONNESSIONI /tmp/connections-report.nconn | awk '{ print $2; }'`
fi

if [ $NUMCONNESSIONI -gt $SOGLIA_CONNESSIONI ] ; then

   sh $UTILITY_DIR/kill_all_sessions.sh
   echo Eseguito kill di tutte le connessioni su `hostname`
   echo NUMCONNESSIONI=$NUMCONNESSIONI
   echo SOGLIA_CONNESSIONI=$SOGLIA_CONNESSIONI

fi

exit

