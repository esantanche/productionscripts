#!/bin/sh
#

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
# PATH_INSTALLDIR (/sybase/ASE-12_5/install)

codice_ritorno=0
REPORT=/tmp/.oggi/start_ase_$$

echo "Riavvio il license manager" > $REPORT
sh $UTILITY_DIR/gestore_license_manager.sh
errore=$?
if [ $errore -ne 0 ] ; then
   echo "Attenzione: codice di ritorno diverso da zero: " $errore >> $REPORT
   codice_ritorno=$errore
fi

echo "Doing: $PATH_INSTALLDIR/startserver -f $PATH_INSTALLDIR/RUN_$ASE_NAME"  >> $REPORT
nohup $PATH_INSTALLDIR/startserver -f $PATH_INSTALLDIR/RUN_$ASE_NAME 2>&1 >/dev/null &
errore=$?
if [ $errore -ne 0 ] ; then
   echo "Attenzione: codice di ritorno diverso da zero: " $errore >> $REPORT
   codice_ritorno=$errore
fi
sleep 20
echo "Doing: $PATH_INSTALLDIR/startserver -f $PATH_INSTALLDIR/RUN_${ASE_NAME}_back" >> $REPORT
nohup $PATH_INSTALLDIR/startserver -f $PATH_INSTALLDIR/RUN_${ASE_NAME}_back 2>&1 >/dev/null &
errore=$?
if [ $errore -ne 0 ] ; then
   echo "Attenzione: codice di ritorno diverso da zero: " $errore >> $REPORT
   codice_ritorno=$errore
fi
sleep 20
echo Done
echo "  " >> $REPORT
echo "Nota: l'XP server non necessita di avvio, viene avviato automaticamente" >> $REPORT
echo "quando e' richiesto" >> $REPORT
echo "Il monitor server non e' utilizzato" >> $REPORT
echo " " >> $REPORT

if [ $TERM != dumb ] ; then 
   cat $REPORT
   MODALITA=Da_linea_comando
else
   MODALITA=Da_crontab
fi

sh $UTILITY_DIR/centro_unificato_messaggi.sh STARTASE $MODALITA $codice_ritorno 0 0 $REPORT

exit $codice_ritorno


