#!/bin/sh 
#
# eseguibile da crontab di sybase, puo' eseguire script che utilizzano Sybase

. /home/sybase/.profile

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

. /sis/SIS-AUX-Envsetting.Sybase.sh

if [ $(lsvg -o | grep $SYBASE_VG_NAME | wc -l) -eq 0 ]
then
        exit 0;
fi

if [ $1'a' = 'a' ] ; then
   echo "Usage: dare come parametro il nome dello script da eseguire presente in $UTILITY_DIR"
   exit 0
fi

# Parametri da passare: nome del db, data aaaammgg, directory in cui mettere il dump
NOME_SCRIPT=$1

sh $UTILITY_DIR/$NOME_SCRIPT
COD_RET=$?

echo Termine esecutore_estemporaneo.sh $NOME_SCRIPT
echo Codice di ritorno $COD_RET

exit $COD_RET

