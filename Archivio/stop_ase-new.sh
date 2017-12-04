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
if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then 
        exit 0;
fi

echo `date` - Shutdown Sybase $ASE_NAME

if [ $1'xxx' = '-fxxx' ] ; then
   forzato=1
   echo "Richiesto shutdown forzato"
else
   forzato=0
   echo "Con il parametro -f si esegue uno stop forzato"
fi

echo Eseguo il checkpoint su tutti i db

$UTILITY_DIR/checkpointalldb.sh

echo Eseguo lo shutdown semplice

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -e << EOF
SHUTDOWN SYB_BACKUP 
go
SHUTDOWN 
go
EOF

echo Attendo 120 secondi prima di verificare che Sybase sia inattivo ...
sleep 30
echo Ancora 90 secondi ...
sleep 30
echo Ancora 60 secondi ...
sleep 30
echo Ancora 30 secondi ...
sleep 30

sybase_ancora_attivo=`showserver | grep dataserver | wc -l`

if [ $sybase_ancora_attivo -gt 0 ] ; then
   echo Sybase ancora attivo nonostante il tentativo di shutdown
fi

if [ $sybase_ancora_attivo -gt 0 -a $forzato -eq 1 ] ; then

   echo Eseguo il checkpoint su tutti i db
   $UTILITY_DIR/checkpointalldb.sh
   echo Eseguo lo shutdown forzato

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -e << EOF
SHUTDOWN SYB_BACKUP with nowait
go
SHUTDOWN with nowait
go
EOF

   echo Attendo 120 secondi prima di verificare che Sybase sia inattivo ...
   sleep 30
   echo Ancora 90 secondi ...
   sleep 30
   echo Ancora 60 secondi ...
   sleep 30
   echo Ancora 30 secondi ...
   sleep 30

   sybase_ancora_attivo=`showserver | grep dataserver | wc -l`

   if [ $sybase_ancora_attivo -gt 0 ] ; then
      echo Sybase ancora attivo anche dopo il tentativo di shutdown forzato
   fi

fi

echo Verificare se sia il dataserver che il backupserver sono chiusi
showserver

