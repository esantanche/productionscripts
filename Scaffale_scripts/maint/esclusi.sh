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

ELENCO=$1

cd $UTILITY_DIR
#ls -1 Dati/Crontabs

#ls -1 *.sh

for file in `ls -1 *.sh`
do
   #echo $file
   USED_IN_ALMENO_UNO_SCRIPT=0
   for file2 in `cat $ELENCO`
   do
      USED=`grep $file $ELENCO | wc -l`
      if [ $USED -gt 0 ] ; then
         USED_IN_ALMENO_UNO_SCRIPT=1
      fi
   done
   if [ $USED_IN_ALMENO_UNO_SCRIPT -eq 0 ] ; then
      echo $file 
   fi
done

