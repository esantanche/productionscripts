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

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 1
fi

WORK_DIR=$UTILITY_DIR

cd ${WORK_DIR}/sysmondir

for file in `ls -p1t | grep "2.*_.*_.*/" | tail -n +10`
do
       echo Rimuovo vecchi sysmon ${file}
       rm -f ${file}* 2>/dev/null
       rmdir ${file}
done

for file in `ls -p1t sysmon_summary* | tail -n +60`
do
       echo Rimuovo vecchi sysmon-summary ${file}
       rm -f ${file} 2>/dev/null
done

exit

