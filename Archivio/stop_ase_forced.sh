#!/bin/sh
#
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

# Un controllo che esistano i volume group sybase. Non fa mai male
if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then 
        exit 0;
fi

$UTILITY_DIR/attivita_sui_processi.sh
$UTILITY_DIR/checkpointalldb.sh

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -e << EOF
SHUTDOWN SYB_BACKUP with nowait
go
SHUTDOWN with nowait
go
quit
EOF

