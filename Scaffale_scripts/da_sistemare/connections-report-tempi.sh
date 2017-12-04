#!/bin/sh -x
#

###TIMEOUT=60   # Tempo di connessione oltre il quale si produce il critical
TIMEOUT=$1    # L'ho messo come parametro

. /home/sybase/.profile

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

DATA=$(/usr/bin/date +%Y%m%d-%H%M%S)
INIZIO_ORE=$(/usr/bin/date +%H)
INIZIO_MIN=$(/usr/bin/date +%M)
INIZIO_SEC=$(/usr/bin/date +%S)

# connections-report.sh   

OKENTRATO=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 <<EOF | grep OKENTRATO | wc -l 
select "OKENTRATO"
go
quit
EOF`

FINE_ORE=$(/usr/bin/date +%H)
FINE_MIN=$(/usr/bin/date +%M)
FINE_SEC=$(/usr/bin/date +%S)

TEMPO=`echo $DATA $INIZIO_ORE $INIZIO_MIN $INIZIO_SEC $FINE_ORE $FINE_MIN $FINE_SEC | nawk '
                                    { inizio_ore=$2;
                                      inizio_min=$3;
                                      inizio_sec=$4;
                                      fine_ore=$5;
                                      fine_min=$6;
                                      fine_sec=$7;
                                      diff=((fine_ore * 60) + fine_min) - ((inizio_ore * 60) + inizio_min);
                                      diff=(diff * 60) + (fine_sec - inizio_sec);
                                      if (diff < 0) diff += 86400;
                                      print "",diff;
                                    }' `

#echo $TEMPO

if [ $OKENTRATO -eq 0 ] ; then
   if [ $TEMPO -eq 0 ] ; then
      TEMPO=9999
   fi
   TEMPO=-$TEMPO
fi

if [ $TEMPO -gt $TIMEOUT -o $TEMPO -lt 0 ] ; then
   echo $DATA $TEMPO >> /nagios_reps/Connessione_a_${ASE_NAME}_rallentata
   echo $DATA $TEMPO | nawk '{ 
      printf "%-10s Tempo impiegato per la connessione (sec) %8d (negativo su mancata connessione) \n",$1,$2; }' >> $UTILITY_DIR/out/connection-report-tempi.log
fi

exit

