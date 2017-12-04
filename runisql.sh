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

if [ $USER = root ] ; then
   su - sybase "-c isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w4000"
else
   isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w4000
fi

