#!/bin/sh

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

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 1
fi

WORK_DIR=$UTILITY_DIR

cd ${WORK_DIR}/out

PRESENTI_OPERAZIONI_FALLITE_ULTIME_24ORE=`find . -name log_centralizzato_operazioni_fallite -mtime -1 2>/dev/null | wc -l`

if [ $PRESENTI_OPERAZIONI_FALLITE_ULTIME_24ORE -gt 0 ] ; then
   echo "Subject: [REPORT-FALLITE] Operazioni fallite ultime 24 ore su "`hostname` >  /tmp/report-fallite.mail
   echo "To: dba@kyneste.com"  >> /tmp/report-fallite.mail
   #echo "======= dalla piu' recente ========================" >> /tmp/report-fallite.mail
   tail -r -5 log_centralizzato_operazioni_fallite  >> /tmp/report-fallite.mail
   #echo "===================================================" >> /tmp/report-fallite.mail
   echo "(Made by $UTILITY_DIR/report-operazioni-fallite.sh)"  >> /tmp/report-fallite.mail

   #/usr/sbin/sendmail -f repofallite@kyneste.com esantanche@tim.it < /tmp/report-fallite.mail
   /usr/sbin/sendmail -f repofallite@kyneste.com dba@kyneste.com < /tmp/report-fallite.mail
fi

exit


