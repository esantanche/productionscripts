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

# Il parametro su linea comando e' il nome del db
NOMEDB=$1

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 >/tmp/db-singolo-space-report$NOMEDB <<EOF
set nocount on
go
use $NOMEDB
go
sp_spaceused
go
quit
EOF


DIMENSIONE_TOTALE_MB=`tail -n +3 /tmp/db-singolo-space-report$NOMEDB | head -1 | awk '{ printf "%5.0f\n",$2; }'`

SPAZIO_OCCUPATO=`tail -n +6 /tmp/db-singolo-space-report$NOMEDB | head -1 | awk '{ printf "%5.0f\n",$1/1000; }'`

echo $DATA $DIMENSIONE_TOTALE_MB $SPAZIO_OCCUPATO >>$UTILITY_DIR/out/spazio-db-$NOMEDB

tail -60 $UTILITY_DIR/out/spazio-db-$NOMEDB | awk 'BEGIN { attuale=0; } { precedente=attuale; attuale=$3; crescita=attuale-precedente; print crescita; }' > /tmp/db-singolo-space-report$NOMEDB.crescita1

CRESCITA30=`tail -30  /tmp/db-singolo-space-report$NOMEDB.crescita1 | awk 'BEGIN { sum=0; num=0; } { sum=sum+$1; num=num+1; } END { printf "%6.0f\n",(sum/num)*30; }' `

CRESCITA15=`tail -15  /tmp/db-singolo-space-report$NOMEDB.crescita1 | awk 'BEGIN { sum=0; num=0; } { sum=sum+$1; num=num+1; } END { printf "%6.0f\n",(sum/num)*30; }' `

echo $DATA $CRESCITA30 $CRESCITA15 | awk '{ printf "%-8s Crescita in MB/mese ultimi 30 gg %6.0f ultimi 15 gg %6.0f\n", $1,$2,$3; }' >> $UTILITY_DIR/out/spazio-db-$NOMEDB-crescita

#echo db-singolo-space-report
#cat $UTILITY_DIR/out/spazio-db-$NOMEDB-crescita

#cat /tmp/db-singolo-space-report$NOMEDB.crescita1

rm /tmp/db-singolo-space-report${NOMEDB}*
