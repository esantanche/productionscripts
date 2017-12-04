#!/bin/sh 
#

. /home/sybase/.profile

# Script per il reorg delle tabelle
# Vengono cancellate le tabelle utente nel tempdb

# Devo avere come parametro il nome del database su cui fare il reorg
# un parametro '-u' indica che va fatto solo l'update delle statistiche
# Quindi primo parametro nome del database, secondo parametro opzionale, -u 
NOMEDB=$1

SOLO_UPDATE=0
if [ $2a = -ua ] ; then
   echo reorg Solo update $NOMEDB
   SOLO_UPDATE=1
fi

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

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 >/tmp/reorgmx-singolodb1 <<EOF
set nocount on
go
use $NOMEDB
go
select 'OWNERTABLEK7  ',u.name,o.name from sysobjects o, sysusers u where o.uid=u.uid and o.type='U' order by o.name
go
if @@error != 0 select 'erroreselectsysobjects'
go
select 'stringadiconfermaconnessione'
go
quit
EOF

if [ `grep "stringadiconfermaconnessione" /tmp/reorgmx-singolodb1 | wc -l` -eq 0 ] ; then
   echo Errore nella connessione $NOMEDB
   exit 1
fi

if [ `grep "erroreselectsysobjects" /tmp/reorgmx-singolodb1 | wc -l` -eq 1 ] ; then
   echo Errore nella select di sysobjects $NOMEDB
   exit 1
fi

#echo solo update $SOLO_UPDATE

cat /tmp/reorgmx-singolodb1 | grep "OWNERTABLEK7" | awk '{ printf "%s.%s\n",$2,$3; }' > /tmp/reorgmx-singolodb2

# Controllo se non ho tabelle da riorganizzare

NUMERO_TABELLE_DA_ELABORARE=`cat /tmp/reorgmx-singolodb2 | wc -l`
if [ $NUMERO_TABELLE_DA_ELABORARE -eq 0 ] ; then
   #echo "Nessuna tabella utente da elaborare."
   #echo " "
   exit 0;
fi

# Creo il file con le istruzioni da eseguire

QRY=/tmp/reorgmx-singolodb3
echo use $NOMEDB > $QRY
echo go >> $QRY

if [ $SOLO_UPDATE -eq 1 ] ; then
   for i in `cat /tmp/reorgmx-singolodb2`
   do
      echo update statistics $i >> $QRY
      echo if @@error != 0 select "'"erroret5"'" >> $QRY
      echo go >> $QRY
   done
else
   for i in `cat /tmp/reorgmx-singolodb2`
   do
      echo reorg rebuild $i >> $QRY
      #echo select @@error >> $QRY
      echo if @@error != 0 and @@error != 11903 select "'"erroret5"'" >> $QRY
      echo go >> $QRY
      echo sp_recompile \'$i\' >> $QRY
      echo if @@error != 0 select "'"erroret5"'" >> $QRY
      echo go >> $QRY
      echo update statistics $i >> $QRY
      echo if @@error != 0 select "'"erroret5"'" >> $QRY
      echo go >> $QRY
   done
fi

echo quit >> $QRY

#echo "Query effettuata: "
#echo ------------------------------------------
#cat $QRY
#echo ------------------------------------------
#echo " "

echo Inizio `date` > /tmp/reorgmx-singolodb4

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -i $QRY >> /tmp/reorgmx-singolodb4 

# Vedo se ho errori

if [ `grep "erroret5" /tmp/reorgmx-singolodb4 | wc -l` -gt 0 ] ; then
   echo Errore nel reorg o nel update statistics nel db $NOMEDB
   exit 1
fi

echo Fine `date` >> /tmp/reorgmx-singolodb4

#rm /tmp/reorgmx-singolodb*

exit 0

