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
   for file2 in `cat $ELENCO`
   do
      USED=`grep -v "^#" $file2 | grep $file | wc -l`
      if [ $USED -gt 0 ] ; then
         if [ $file != $file2 ] ; then
            echo $file
         fi
      fi
   done
done

