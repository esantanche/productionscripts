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

sh $UTILITY_DIR/stop_ase_4tempi.sh
sleep 60
sh $UTILITY_DIR/start_ase.sh
sleep 60

exit



