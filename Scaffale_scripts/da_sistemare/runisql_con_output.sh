#!/bin/sh 
#

# E.Santanche 
# Script che lancia isql
# da eseguire come root

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME

echo " "
echo "Inserire il path completo del file verso il quale inviare l'output dei comandi"
echo "che inserirete nella sessione interattiva."
read path_output


# FARE UN TOUCH per vedere se riesce
touch $path_output 2>/dev/null
CODRET=$?

if [ $CODRET -ne  0 ] ; then
   echo "  "
   echo Non posso creare il file di output $path_output
   echo "  "
   exit 1
fi

echo "  "
echo "ATTENZIONE! l'output dei comandi andra' solo nel file di output e non a video"
echo "Non dimenticate il go dopo ogni comando"
echo "  "

if [ $USER = root ] ; then
   chown sybase:dba $path_output
   su - sybase "-c isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w4000 -e -o $path_output"
else
   isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w4000 -e -o $path_output
fi

