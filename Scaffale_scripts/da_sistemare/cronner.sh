#!/bin/sh 

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME

# Un controllo che esistano i volume group sybase. Non fa mai male
if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then 
        exit 0;
fi

NOME_SCRIPT=$1

/usr/bin/sh $UTILITY_DIR/$NOME_SCRIPT > /tmp/cronner_out.$$ 2>&1

ERRORE=$?

if [ $ERRORE -gt 0 ] ; then
   DATAORA=`date +%Y%m%d%H%M`
   cp /tmp/cronner_out.$$ /nagios_reps/$DATAORA-$NOME_SCRIPT
fi

cat /tmp/cronner_out.$$
rm -f /tmp/cronner_out.$$ 2>/dev/null


