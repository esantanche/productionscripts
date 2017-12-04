#!/bin/sh -x

# ATTENZIONE ! questo script e' uguale su tutte le macchine per cui va modificato solo
# su mx1-dev-2 e poi copiato sulle altre macchine mediante lo script
# allinea_uno_script.sh

. /sis/SIS-AUX-Envsetting.Sybase.sh

PID_LOG_ANALIZER=`ps -ef | grep "perl.*loganalizer.pl" | grep -v grep | awk '{ print $2; }'`

if [ a$PID_LOG_ANALIZER = a ] ; then

   # devo intervenire per il riavvio
   #echo loganalizer-runner.sh
   #echo loganalizer.pl da killare PID $PID_LOG_ANALIZER
   #kill $PID_LOG_ANALIZER

   if [ `echo $PATH | grep "/sybase/utility" | wc -l` = 0 ] ; then
      PATH=$PATH:/sybase/utility
   fi 

   nohup perl $UTILITY_DIR/loganalizer.pl $PATH_ERRORLOG_ASESERVER >/dev/null 2>&1 &

   sleep 60

   PID_LOG_ANALIZER=`ps -ef | grep loganalizer.pl | grep -v grep | awk '{ print $2; }'`

   if [ a$PID_LOG_ANALIZER = a ] ; then 
      echo ATTENZIONE non riesco ad avviare loganalizer.pl > /nagios_reps/Errore_riavvio_loganalizer
      echo loganalizer-runner.sh >> /nagios_reps/Errore_riavvio_loganalizer
      echo mx errore >> /nagios_reps/Errore_riavvio_loganalizer
      exit
   fi

   echo "Subject: ATTENZIONE! Riavviato loganalyzer su "`hostname` > /tmp/loganalyzer-runner.mail
   echo "(by $0)" >> /tmp/loganalyzer-runner.mail
   echo "E' stato trovato il loganalyzer (loganalizer.pl) non attivo" >> /tmp/loganalyzer-runner.mail
   echo "e si è proceduto positivamente al suo riavvio." >> /tmp/loganalyzer-runner.mail
   echo $(/usr/bin/date +%Y.%m.%d-%H:%M:%S) >> /tmp/loganalyzer-runner.mail
   
   /usr/sbin/sendmail -f loganlyzr@kyneste.com dba@kyneste.com < /tmp/loganalyzer-runner.mail 

fi

exit

