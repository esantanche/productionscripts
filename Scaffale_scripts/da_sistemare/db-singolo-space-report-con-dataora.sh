#!/bin/sh -x
#

. /home/sybase/.profile

DATA=$(/usr/bin/date +%Y%m%d-%H%M)

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

# DA migliorare: e' bene estrarre i dati anche della sola occupazione
# Il parametro su linea comando e' il nome del db
NOMEDB=$1
#$UTILITY_DIR/out/lista_dei_db 

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 >/tmp/db-singolo-space-report-dataora-$NOMEDB <<EOF
set nocount on
go
use $NOMEDB
go
sp_spaceused
go
select "COLLEGATOOK"
go
quit
EOF

COLLOK=`grep "COLLEGATOOK" /tmp/db-singolo-space-report-dataora-$NOMEDB | wc -l`
if [ $COLLOK -eq 0 ] ; then
   rm /tmp/db-singolo-space-report-dataora-$NOMEDB
   exit 0
fi 


DIMENSIONE_TOTALE_MB=`tail -n +3 /tmp/db-singolo-space-report-dataora-$NOMEDB | head -1 | awk '{ printf "%5.0f\n",$2; }'`

SPAZIO_OCCUPATO=`tail -n +6 /tmp/db-singolo-space-report-dataora-$NOMEDB | head -1 | awk '{ printf "%5.0f\n",$1/1000; }'`

echo $DATA $DIMENSIONE_TOTALE_MB $SPAZIO_OCCUPATO >>$UTILITY_DIR/out/spazio-db-$NOMEDB-dataora

rm /tmp/db-singolo-space-report-dataora-$NOMEDB
