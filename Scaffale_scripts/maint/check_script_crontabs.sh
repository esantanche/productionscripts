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

cd $UTILITY_DIR
#ls -1 Dati/Crontabs

#ls -1 *.sh

for file in `ls -1 *.sh`
do
   #echo $file
   USED=`grep -v "^#" Dati/Crontabs/cronta* | grep $file | wc -l`
   if [ $USED -gt 0 ] ; then
      echo $file 
   fi
done

