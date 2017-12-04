#!/bin/sh -x

# ATTENZIONE ! questo script e' uguale su tutte le macchine per cui va modificato solo
# su mx1-dev-2 e poi copiato sulle altre macchine mediante lo script
# allinea_uno_script.sh

# Se un file di log per es. dell'ASE o del backup server diventa troppo grande, lo rinomina
# costringendo quindi l'ASE o il backup server a crearne uno nuovo

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME
# HOME_OF_SYBASE
# PATH_ERRORLOG_ASESERVER

#. $HOME_OF_SYBASE/.profile

if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then
        exit 0;
fi

# Se l'ASE e' attivo non posso troncare il log

DATASERVERATTIVO=`ps -ef | grep dataserver | grep -v grep | wc -l`
BKPSRVATTIVO=`ps -ef | grep backupserver | grep -v grep | wc -l`

if [ $DATASERVERATTIVO -gt 0 -o $BKPSRVATTIVO -gt 0 ] ; then
   echo "Subject: Impossibile troncare il log, l'ASE e' attivo -" `hostname` > /tmp/logtruncator.mail
   echo "E' stato trovato l'ASE attivo quando si e' provato a troncare il log" >> /tmp/logtruncator.mail
   echo Hostname `hostname` >> /tmp/logtruncator.mail
   cp /tmp/logtruncator.mail /inbacheca/logtruncator-ko-$(/usr/bin/date +%Y.%m.%d-%H:%M)
   sendmail -f logtruncatorerr@kyneste.com dba@kyneste.com < /tmp/logtruncator.mail
   exit 1
fi

# per murex DATA=$(/usr/bin/date +%Y%m%d)
DATA=$(date +%Y%m%d)
# Massima size del log in KB
MAXSIZE=3000

SIZEKB_LOGASE=`du -k $PATH_ERRORLOG_ASESERVER | awk '{ print $1; }'`

CODRIT=0

# Come si tronca un log ?
# Un log si tronca avendo fermato l'applicazione che lo produce (l'ASE in questo caso)
# poi si fa un rename del file di log
# poi si fa un touch del file (serve al loganalyzer per rimettersi in "ascolto" del log)
# poi si zippa (opzionale) il log rinominato
# poi si attende un po' per essere sicuri che il loganalyzer abbia potuto riagganciarsi
#     al nuovo log

if [ $SIZEKB_LOGASE -gt $MAXSIZE ] ; then
   mv $PATH_ERRORLOG_ASESERVER $PATH_ERRORLOG_ASESERVER.$DATA
   CODRIT1=$?
   touch $PATH_ERRORLOG_ASESERVER
   CODRIT2=$?
   if [ $CODRIT1 -eq 0 -a $CODRIT2 -eq 0 ] ; then
      gzip -9 $PATH_ERRORLOG_ASESERVER.$DATA
      sleep 60
      # Mando la mail
      #PID_LOG_ANALIZER=`ps -ef | grep loganalizer.pl | grep -v grep | awk '{ print $2; }'`
      #if [ a$PID_LOG_ANALIZER != a ] ; then
      #   kill $PID_LOG_ANALIZER
      #   nohup perl $UTILITY_DIR/loganalizer.pl $PATH_ERRORLOG_ASESERVER >/dev/null 2>&1 &
      #   sleep 30
      #fi
      echo Subject: Log troncato correttamente su `hostname` > /tmp/logtruncator.mail
      echo Log ASE troncato a $MAXSIZE KB >> /tmp/logtruncator.mail
      echo Hostname `hostname` >> /tmp/logtruncator.mail
      echo Path del log $PATH_ERRORLOG_ASESERVER >> /tmp/logtruncator.mail
      #cp /tmp/logtruncator.mail /inbacheca/logtruncator-ok-$(/usr/bin/date +%Y.%m.%d-%H:%M)
      #sendmail -f logtruncatorok@kyneste.com dba@kyneste.com < /tmp/logtruncator.mail 
   else
      echo Subject: ERRORE Troncamento log fallito su `hostname` > /tmp/logtruncator.mail
      echo Errore nel troncare il log ASE >> /tmp/logtruncator.mail
      echo Hostname `hostname` >> /tmp/logtruncator.mail
      echo Path del log $PATH_ERRORLOG_ASESERVER >> /tmp/logtruncator.mail
      cp /tmp/logtruncator.mail /inbacheca/logtruncator-ko-$(/usr/bin/date +%Y.%m.%d-%H:%M)      
      sendmail -f logtruncatorerr@kyneste.com dba@kyneste.com < /tmp/logtruncator.mail             
      echo "Errore in logtruncator.sh, non riesco a troncare il log dell'ASE" 
      echo "Hostname: " `hostname`
      exit $CODRIT
   fi
fi

SIZEKB_LOGBKPSRV=`du -k $PATH_ERRORLOG_BACKUPSERVER | awk '{ print $1; }'`

CODRIT=0

if [ $SIZEKB_LOGBKPSRV -gt $MAXSIZE ] ; then
   mv $PATH_ERRORLOG_BACKUPSERVER $PATH_ERRORLOG_BACKUPSERVER.$DATA
   CODRIT1=$?
   touch $PATH_ERRORLOG_BACKUPSERVER
   CODRIT2=$?
   if [ $CODRIT1 -eq 0 -a $CODRIT2 -eq 0 ] ; then
      gzip -9 $PATH_ERRORLOG_BACKUPSERVER.$DATA
      sleep 60
      # Mando la mail
      echo Subject: Log troncato correttamente su `hostname` > /tmp/logtruncator.mail
      echo Log Backup server troncato a $MAXSIZE KB >> /tmp/logtruncator.mail
      echo Hostname `hostname` >> /tmp/logtruncator.mail
      echo Path del log $PATH_ERRORLOG_BACKUPSERVER >> /tmp/logtruncator.mail
      cp /tmp/logtruncator.mail /inbacheca/logtruncator-ok-$(/usr/bin/date +%Y.%m.%d-%H:%M)
      #sendmail -f logtruncatorok@kyneste.com dba@kyneste.com < /tmp/logtruncator.mail
   else
      echo Subject: ERRORE Troncamento log fallito su `hostname` > /tmp/logtruncator.mail
      echo Errore nel troncare il log del Backup server >> /tmp/logtruncator.mail
      echo Hostname `hostname` >> /tmp/logtruncator.mail
      echo Path del log $PATH_ERRORLOG_BACKUPSERVER >> /tmp/logtruncator.mail
      cp /tmp/logtruncator.mail /inbacheca/logtruncator-ko-$(/usr/bin/date +%Y.%m.%d-%H:%M)
      sendmail -f logtruncatorerr@kyneste.com dba@kyneste.com < /tmp/logtruncator.mail
      echo "Errore in logtruncator.sh, non riesco a troncare il log del Backup server"
      echo "Hostname: " `hostname`
   fi
fi

exit $CODRIT

