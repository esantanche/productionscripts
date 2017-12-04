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

if [ ! -f $UTILITY_DIR/out/esito_ultimo_dumpmx_alldb ] ; then
   
   echo `hostname`
   echo "    "
   echo "    "
   echo "Essendo le ore "`date +%H:%M`" il dump su questa macchina non e' ancora finito"
   echo "Si prega di verificare le cause di tale ritardo" 
   echo "    "
   echo "    "

   DATA=$(/usr/bin/date +%Y%m%d)

   echo "Essendo le ore "`date +%H:%M`" il dump su questa macchina non e' ancora finito" > /nagios_reps/Ritardo_nel_dump_$DATA
   echo "Si prega di verificare le cause di tale ritardo" >> /nagios_reps/Ritardo_nel_dump_$DATA

fi

