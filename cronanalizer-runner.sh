#!/bin/sh -x

# ATTENZIONE ! questo script e' uguale su tutte le macchine per cui va modificato solo
# su mx1-dev-2 e poi copiato sulle altre macchine mediante lo script
# allinea_uno_script.sh

. /sis/SIS-AUX-Envsetting.Sybase.sh

PID_CRON_ANALIZER=`ps -ef | grep cronanalizer.pl | grep -v grep | awk '{ print $2; }'`

if [ a$PID_CRON_ANALIZER != a ] ; then
   #echo loganalizer-runner.sh
   #echo loganalizer.pl da killare PID $PID_LOG_ANALIZER
   kill $PID_CRON_ANALIZER
fi 

nohup perl $UTILITY_DIR/cronanalizer.pl >/dev/null 2>&1 &
ERRORE=$?
if [ $ERRORE -gt 0 ] ; then
   echo "questo e' lo script $0 a cura del gruppo DBA"
   echo "nohup fallito con errore $ERRORE"
   exit 1
fi 

sleep 60

PID_CRON_ANALIZER=`ps -ef | grep cronanalizer.pl | grep -v grep | awk '{ print $2; }'`

if [ a$PID_CRON_ANALIZER = a ] ; then 
   echo "questo e' lo script $0 a cura del gruppo DBA"
   echo ATTENZIONE non riesco ad avviare cronanalizer.pl
   echo cronanalizer-runner.sh
   echo mx errore
   exit 1
fi

echo $(/usr/bin/date +%Y%m%d-%H:%M) $PID_CRON_ANALIZER | awk '{ printf "%-14s cronanalizer.pl avviato con pid %d\n",$1,$2; }' >> $UTILITY_DIR/out/log_avvii_cronanalizer

#echo Eseguito restart cronanalizer.pl
#echo =================================================
#tail -10 $UTILITY_DIR/out/log_avvii_cronanalizer

exit

