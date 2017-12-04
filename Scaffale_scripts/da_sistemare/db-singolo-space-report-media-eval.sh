#!/bin/sh -x
#

. /home/sybase/.profile

DATA=$(/usr/bin/date +%Y%m%d)

#if [ $USER != sybase ] ; then
#   echo Eseguire come sybase
#   exit 0
#fi

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

#isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 >/tmp/db-singolo-space-report$NOMEDB <<EOF
#set nocount on
#go
#use $NOMEDB
#go
#sp_spaceused
#go
#quit
#EOF

cat $UTILITY_DIR/out/spazio-db-$NOMEDB

cat $UTILITY_DIR/out/spazio-db-$NOMEDB | awk 'BEGIN { media=1500; prec=4404; } 
                                                    { diff=$3-prec; prec=$3; media=(media*29/30)+diff/30; 
                                                      printf "Differenza: %8.2f MB  Media: %10.0f MB/mese\n",diff,media*30; } 
                                              END   { print "END"; }'

#DIMENSIONE_TOTALE_MB=`tail -n +3 /tmp/db-singolo-space-report$NOMEDB | head -1 | awk '{ printf "%5.0f\n",$2; }'`

#SPAZIO_OCCUPATO=`tail -n +6 /tmp/db-singolo-space-report$NOMEDB | head -1 | awk '{ printf "%5.0f\n",$1/1000; }'`

#echo $DATA $DIMENSIONE_TOTALE_MB $SPAZIO_OCCUPATO >>$UTILITY_DIR/out/spazio-db-$NOMEDB

#rm /tmp/db-singolo-space-report$NOMEDB
