#!/bin/sh 
#

# TI sta per tempo impiegato. Queste variabili servono per calcolare il tempo impiegato dallo script

TI_INIZIO_ORA=$(/usr/bin/date +%H)
TI_INIZIO_MINUTI=$(/usr/bin/date +%M)
TI_INIZIO_SECONDI=$(/usr/bin/date +%S)

DATA=$(/usr/bin/date +%Y%m%d)

. /home/sybase/.profile

# Script per la pulizia del tempdb
# Vengono cancellate le tabelle utente nel tempdb

# Vengono cancellate tutte le tabelle create fino a NUM_GIORNI prima
# dell'esecuzione dello script
NUM_GIORNI=0  

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

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 >/tmp/db-pulizia-tempdb1 <<EOF
set nocount on
go
use tempdb
go
select name from sysobjects where type='U' and crdate < dateadd(dd,-$NUM_GIORNI,getdate()) order by name 
go
if @@error != 0 select 'erroreselectsysobjects'
go
quit
EOF

if [ `grep "erroreselectsysobjects" /tmp/db-pulizia-tempdb1 | wc -l` -eq 1 ] ; then
   echo Errore nella select di sysobjects
   exit 1
fi

tail -n +3 /tmp/db-pulizia-tempdb1 > /tmp/db-pulizia-tempdb2

# Controllo se non ho tabelle da droppare

NUMERO_TABELLE_DA_DROPPARE=`cat /tmp/db-pulizia-tempdb2 | wc -l`
if [ $NUMERO_TABELLE_DA_DROPPARE -gt 0 ] ; then

   cp /tmp/db-pulizia-tempdb2 $UTILITY_DIR/out/db_pulizia_tempdb_lista_tabelle

   # Creo il file con le istruzioni da eseguire

   QRY=$UTILITY_DIR/out/db_pulizia_tempdb_query_to_run.sql
   echo use tempdb > $QRY
   echo go >> $QRY

   for i in `cat /tmp/db-pulizia-tempdb2`
   do
      echo drop table guest.$i >> $QRY
      echo go >> $QRY
      echo if @@error != 0 select "'"erroredroptabletempdb"'" >> $QRY
      echo go >> $QRY
   done

   echo quit >> $QRY

   isql -U$SAUSER -P$SAPWD -S$ASE_NAME -i $QRY > $UTILITY_DIR/out/db_pulizia_tempdb_result.log 

   # Vedo se ho errori

   if [ `grep "erroredroptabletempdb" $UTILITY_DIR/out/db_pulizia_tempdb_result.log | wc -l` -gt 0 ] ; then
      echo Errore nel drop delle tabelle nel tempdb
      exit 1
   fi

fi

echo "Fine pulizia tempdb" >> $UTILITY_DIR/out/db_pulizia_tempdb_result.log

rm /tmp/db-pulizia-tempdb*

# TI sta per tempo impiegato. Queste variabili servono per calcolare il tempo impiegato dallo script
TI_FINE_ORA=$(/usr/bin/date +%H)
TI_FINE_MINUTI=$(/usr/bin/date +%M)
TI_FINE_SECONDI=$(/usr/bin/date +%S)

#echo $TI_INIZIO_ORA $TI_INIZIO_MINUTI $TI_INIZIO_SECONDI $TI_FINE_ORA $TI_FINE_MINUTI $TI_FINE_SECONDI
TI_INIZIO_SECTOT=`echo $TI_INIZIO_ORA $TI_INIZIO_MINUTI $TI_INIZIO_SECONDI | awk '{ print ($1*3600+$2*60+$3); }'`
TI_FINE_SECTOT=`echo $TI_FINE_ORA $TI_FINE_MINUTI $TI_FINE_SECONDI | awk '{ print ($1*3600+$2*60+$3); }'`
#echo $TI_INIZIO_SECTOT $TI_FINE_SECTOT
TI_SEC_IMPIEGATI=`echo $TI_INIZIO_SECTOT $TI_FINE_SECTOT | awk '{ secimp=($2-$1); if (secimp < 0) { secimp=secimp+86400; }; print secimp; }'`
echo $DATA $TI_SEC_IMPIEGATI >> $UTILITY_DIR/out/db_pulizia_tempdb_tempo_impiegato

exit 0

