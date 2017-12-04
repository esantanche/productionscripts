#!/bin/sh
#

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

# Parametri:
# primo parametro: signal (senza segno meno)
# secondo parametro: nome processo

if [ $1a = a -o $2a = a ] ; then
   echo "Usage: dare come parametri il segnale da inviare ai processi e il nome del processo"
   exit 0
fi

SEGNALE=$1
NOMEPROC=$2

echo Nome processo da killare -$NOMEPROC-

for p in `ps -ef | fgrep $NOMEPROC | fgrep -v grep | fgrep -v kill_all_pid | awk '{ print $2; }'`
do
   echo Killing $p segnale $SEGNALE
   #ps -ef | fgrep $p
   kill -$SEGNALE $p
   sleep 10
done

exit


