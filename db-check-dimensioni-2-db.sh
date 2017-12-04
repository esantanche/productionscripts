#!/bin/sh -x
#

. /home/sybase/.profile

DATA=$(/usr/bin/date +%Y%m%d)

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

if [ $1a = a -o $2a = a ] ; then
   echo "Usage: dare come parametri i 2 nomi dei db di cui confrontare le dimensioni"
   exit 0
fi

NOMEDB1=$1
NOMEDB2=$2

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 >/tmp/db-check-dimensioni-2-db$NOMEDB1 <<EOF
set nocount on
go
use $NOMEDB1
go
sp_spaceused
go
quit
EOF

DIMENSIONE_TOTALE_MB1=`tail -n +3 /tmp/db-check-dimensioni-2-db$NOMEDB1 | head -1 | awk '{ printf "%5.0f\n",$2; }'`

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 >/tmp/db-check-dimensioni-2-db$NOMEDB2 <<EOF
set nocount on
go
use $NOMEDB2
go
sp_spaceused
go
quit
EOF

DIMENSIONE_TOTALE_MB2=`tail -n +3 /tmp/db-check-dimensioni-2-db$NOMEDB2 | head -1 | awk '{ printf "%5.0f\n",$2; }'`

#echo $NOMEDB1 $DIMENSIONE_TOTALE_MB1 $NOMEDB2 $DIMENSIONE_TOTALE_MB2

CODICE_RITORNO=1
if [ $DIMENSIONE_TOTALE_MB1 -ne $DIMENSIONE_TOTALE_MB2 ] ; then
   #echo Dump errato $DATA > $UTILITY_DIR/out/esito_ultimo_dumpmx_alldb 
   #echo Invio messaggio errore
   echo "Subject: [CHECK 2 DB] Db di dimensione diversa su "$ASE_NAME >  /tmp/check2db.mail
   echo "To: dba@kyneste.com"  >> /tmp/check2db.mail
   echo "ASE "$ASE_NAME >> /tmp/check2db.mail
   echo "Host "`hostname` >> /tmp/check2db.mail
   echo "I database "$NOMEDB1" e "$NOMEDB2" sono di dimensioni diverse" >> /tmp/check2db.mail
   echo "mentre dovrebbero essere uguali. Provvedere all'allineamento." >> /tmp/check2db.mail
   echo "ATTENZIONE - ATTENZIONE !!!!! Anche altri db con lo stesso nome o simili" >> /tmp/check2db.mail
   echo "sulle altre macchine (es. i db il cui nome inizia per SIF_ devono essere tutti uguali)." >> /tmp/check2db.mail
   echo "    " >> /tmp/check2db.mail
   #/usr/sbin/sendmail -f dumpmxerr@kyneste.com esantanche@tim.it < /tmp/check2db.mail
   /usr/sbin/sendmail -f check2db@kyneste.com dba@kyneste.com < /tmp/check2db.mail
   echo "Database "$NOMEDB1" e "$NOMEDB2" da riallineare" > /tmp/check2db.nagiosrep
   echo "perche' di dimensioni diverse." >> /tmp/check2db.nagiosrep
   cp /tmp/check2db.nagiosrep /nagios_reps/Db_di_dimensioni_diverse_$DATA
   rm /tmp/check2db.nagiosrep
   rm -f /tmp/check2db.mail
   CODICE_RITORNO=1
else
   CODICE_RITORNO=0
fi

exit $CODICE_RITORNO

#rm /tmp/db-singolo-space-report$NOMEDB
