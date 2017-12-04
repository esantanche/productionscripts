#!/bin/sh 
#

. /home/sybase/.profile

# Script per il reorg delle tabelle
# Vengono cancellate le tabelle utente nel tempdb

# Devo avere come parametro il nome del database su cui fare il reorg
# un parametro '-u' indica che va fatto solo l'update delle statistiche
# Quindi primo parametro nome del database, secondo parametro opzionale, -u 
#NOMEDB=$1

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

if [ $1'a' = 'a'  ] ; then
   echo "Usage: dare come parametro il nome dello script sql da eseguire, presente in $UTILITY_DIR"
   exit 0
fi

# Parametri da passare: nome del db, data aaaammgg, directory in cui mettere il dump
NOMESCRIPT=$1

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w2000 -i $UTILITY_DIR/$NOMESCRIPT > $UTILITY_DIR/$NOMESCRIPT.output 

echo Esecuzione terminata
echo Output in $UTILITY_DIR/$NOMESCRIPT.output

exit


