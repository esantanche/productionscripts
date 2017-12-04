#!/bin/sh 
#

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

if [ $(lsvg -o | grep $SYBASE_VG_NAME | wc -l) -eq 0 ]
then
        exit 0;
fi

# Prendo in input
# operazione effettuata
#   non ci devono essere spazi
# eventuale ulteriore specificazione dell'operazione (es. nome db per i dump 1shot)
#   non ci devono essere spazi
# esito 0 per ok, >0 per errore     
# inizio ore
# inizio minuti
# fine ore
# fine minuti

# controllo devo avere 7 parametri


OPERAZIONE=$1
SPECIF=$2

#echo OPERAZIONE=$OPERAZIONE
#echo SPECIF=$SPECIF

DATAORA=`date +%Y.%m.%m-%H:%M:%S`
PATH_LOG=$UTILITY_DIR/logs/mxmain_$ASE_NAME.log
PATH_LOG_FULL=/tmp/.oggi/mxmain_$ASE_NAME.log.full

rm -f /tmp/.oggi/mxmain_$ASE_NAME.log*

cp $UTILITY_DIR/logs/mxmain_$ASE_NAME.log* /tmp/.oggi

gunzip /tmp/.oggi/mxmain_$ASE_NAME.log*.gz

for l in `ls -1r /tmp/.oggi/mxmain_$ASE_NAME.log*`
do
   echo $l
   cat $l >> $PATH_LOG_FULL 
done

cat $PATH_LOG_FULL | awk 'BEGIN { FS=";"; }{ secondi=$6-$5; ore = int(secondi / 3600);minuti=int((secondi - (ore * 3600))/60);esito="KO";if ($4 == 0) { esito="  ";};printf "%-20s %-20s %-40s %02d:%02d  %-2s\n", $1,$2,$3,ore,minuti,esito; }'

exit

