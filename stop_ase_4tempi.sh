#!/bin/sh
#

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

function visualizza_ultima_riga {
   if [ $TERM != dumb ] ; then
      tail -1 $LOGSTOP
   fi
}

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME

# Un controllo che esistano i volume group sybase. Non fa mai male
if [ $(lsvg -o | grep $SYBASE_VG_NAME | wc -l) -eq 0 ]
then 
        exit 0;
fi

#LOGSTOP=$UTILITY_DIR/logs/log-stop-ase.log
LOGSTOP=/tmp/.oggi/log-stop-ase-$$

echo =========================================== > $LOGSTOP
echo `date` - Shutdown Sybase $ASE_NAME >> $LOGSTOP

#$PATH_INSTALLDIR/showserver

# Deve fare: 
# kill tutte le sessioni
# shutdown normale
# shutdown forzato
# kill -15
# kill -9

# kill tutte le sessioni

echo Kill di tutte le sessioni >> $LOGSTOP

$UTILITY_DIR/kill_all_sessions.sh >> $LOGSTOP

echo Eseguo il checkpoint su tutti i db >> $LOGSTOP

$UTILITY_DIR/checkpointalldb.sh >> $LOGSTOP

echo Eseguo lo shutdown semplice >> $LOGSTOP

visualizza_ultima_riga

nohup isql -U$SAUSER -P$SAPWD -S$ASE_NAME -e << EOF >> $LOGSTOP  &
SHUTDOWN SYB_BACKUP 
go
SHUTDOWN 
go
quit
EOF

echo `date` Lanciato shutdown non forzato in background >> $LOGSTOP
visualizza_ultima_riga

sleep 30

sybase_ancora_attivo=`$PATH_INSTALLDIR/showserver | grep dataserver | wc -l`

if [ $sybase_ancora_attivo -gt 0 ] ; then
   echo Sybase ancora attivo nonostante il tentativo di shutdown >> $LOGSTOP
fi

if [ $sybase_ancora_attivo -gt 0 ] ; then

   echo Eseguo il checkpoint su tutti i db >> $LOGSTOP
   $UTILITY_DIR/checkpointalldb.sh >> $LOGSTOP
   echo `date` Eseguo lo shutdown forzato >> $LOGSTOP
   visualizza_ultima_riga

nohup isql -U$SAUSER -P$SAPWD -S$ASE_NAME -e << EOF >> $LOGSTOP  &
SHUTDOWN SYB_BACKUP with nowait
go
SHUTDOWN with nowait
go
quit
EOF

   echo `date` Lanciato shutdown forzato in background >> $LOGSTOP

   sleep 30

   sybase_ancora_attivo=`$PATH_INSTALLDIR/showserver | grep dataserver | wc -l`

   if [ $sybase_ancora_attivo -gt 0 ] ; then
      echo Sybase ancora attivo anche dopo il tentativo di shutdown forzato >> $LOGSTOP
      visualizza_ultima_riga
      echo "Eseguo kill -15 di dataserver backupserver sybmultbuf" >> $LOGSTOP
      $UTILITY_DIR/kill_all_pid.sh 15 dataserver
      $UTILITY_DIR/kill_all_pid.sh 15 backupserver
      $UTILITY_DIR/kill_all_pid.sh 15 sybmultbuf 
   fi

   sleep 30

   sybase_ancora_attivo=`$PATH_INSTALLDIR/showserver | grep dataserver | wc -l`

   if [ $sybase_ancora_attivo -gt 0 ] ; then
      echo "Sybase ancora attivo anche dopo il kill -15" >> $LOGSTOP
      visualizza_ultima_riga
      echo "Eseguo kill -9 di dataserver backupserver sybmultbuf" >> $LOGSTOP
      $UTILITY_DIR/kill_all_pid.sh 9 dataserver
      $UTILITY_DIR/kill_all_pid.sh 9 backupserver
      $UTILITY_DIR/kill_all_pid.sh 9 sybmultbuf
   fi

fi

if [ $TERM != dumb ] ; then
   echo " "
   echo Verificare se sia il dataserver che il backupserver sono chiusi
   echo esaminando il seguente output del comando showserver
   echo " "
   $PATH_INSTALLDIR/showserver
fi

$PATH_INSTALLDIR/showserver >> $LOGSTOP

sybase_ancora_attivo=`$PATH_INSTALLDIR/showserver | grep dataserver | wc -l`

if [ $sybase_ancora_attivo -gt 0 ] ; then
   echo Sybase ancora attivo nonostante tutti i tentativi di chiuderlo >> $LOGSTOP
   visualizza_ultima_riga
   #echo Sybase ancora attivo nonostante tutti i tentativi di chiuderlo
   CODICE_RITORNO=1
else
   CODICE_RITORNO=0
fi

if [ $TERM != dumb ] ; then 
   echo Output completo
   cat $LOGSTOP
   MODALITA=Da_linea_comando
else
   MODALITA=Da_crontab
fi

sh $UTILITY_DIR/centro_unificato_messaggi.sh STOPASE $MODALITA $CODICE_RITORNO 0 0 $LOGSTOP

exit
