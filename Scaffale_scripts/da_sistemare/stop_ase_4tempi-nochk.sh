#!/bin/sh
#

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

# Un controllo che esistano i volume group sybase. Non fa mai male
if [ $(lsvg -o | grep $SYBASE_VG_NAME | wc -l) -eq 0 ]
then 
        exit 0;
fi

echo `date` - Shutdown Sybase $ASE_NAME

$PATH_INSTALLDIR/showserver

# Deve fare: 
# kill tutte le sessioni
# shutdown normale
# shutdown forzato
# kill -15
# kill -9

# kill tutte le sessioni

echo Kill di tutte le sessioni

$UTILITY_DIR/kill_all_sessions.sh

echo Eseguo il checkpoint su tutti i db

#$UTILITY_DIR/checkpointalldb.sh

echo Eseguo lo shutdown semplice

nohup isql -U$SAUSER -P$SAPWD -S$ASE_NAME -e << EOF &
SHUTDOWN SYB_BACKUP 
go
SHUTDOWN 
go
quit
EOF

echo Lanciato shutdown non forzato in background
echo `date`

sleep 30

sybase_ancora_attivo=`$PATH_INSTALLDIR/showserver | grep dataserver | wc -l`

if [ $sybase_ancora_attivo -gt 0 ] ; then
   echo Sybase ancora attivo nonostante il tentativo di shutdown
fi

if [ $sybase_ancora_attivo -gt 0 ] ; then

   echo Eseguo il checkpoint su tutti i db
   $UTILITY_DIR/checkpointalldb.sh
   echo Eseguo lo shutdown forzato

nohup isql -U$SAUSER -P$SAPWD -S$ASE_NAME -e << EOF &
SHUTDOWN SYB_BACKUP with nowait
go
SHUTDOWN with nowait
go
quit
EOF

   echo Lanciato shutdown forzato in background

   echo `date`

   sleep 30

   sybase_ancora_attivo=`$PATH_INSTALLDIR/showserver | grep dataserver | wc -l`

   if [ $sybase_ancora_attivo -gt 0 ] ; then
      echo Sybase ancora attivo anche dopo il tentativo di shutdown forzato
      echo "Eseguo kill -15 di dataserver backupserver sybmultbuf"
      $UTILITY_DIR/kill_all_pid.sh 15 dataserver
      $UTILITY_DIR/kill_all_pid.sh 15 backupserver
      $UTILITY_DIR/kill_all_pid.sh 15 sybmultbuf 
   fi

   sleep 30

   sybase_ancora_attivo=`$PATH_INSTALLDIR/showserver | grep dataserver | wc -l`

   if [ $sybase_ancora_attivo -gt 0 ] ; then
      echo "Sybase ancora attivo anche dopo il kill -15"
      echo "Eseguo kill -9 di dataserver backupserver sybmultbuf"
      $UTILITY_DIR/kill_all_pid.sh 9 dataserver
      $UTILITY_DIR/kill_all_pid.sh 9 backupserver
      $UTILITY_DIR/kill_all_pid.sh 9 sybmultbuf
   fi

fi

echo " "
echo Verificare se sia il dataserver che il backupserver sono chiusi
echo esaminando il seguente output del comando showserver
echo " "
$PATH_INSTALLDIR/showserver

