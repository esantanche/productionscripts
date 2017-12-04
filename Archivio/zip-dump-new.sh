#!/bin/sh -x
#

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME
# SOGLIA_FS_DUMP_MB
# SOGLIA_FS_DB_MB

sh $UTILITY_DIR/controllo_spazio_manovra_realtime.sh

for dump in `ls -1 /sybased1/dump | grep -v ".gz" | grep -v "NOZIP"` 
do
        echo gzipping $dump
        gzip -f -6 -c /sybased1/dump/$dump > /sybased1/dump/$dump.gz
        sh $UTILITY_DIR/controllo_spazio_manovra_realtime.sh
        rm /sybased1/dump/$dump
done
