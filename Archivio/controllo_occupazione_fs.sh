#!/bin/sh 

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

DATA=`date +%Y%m%d`

SPAZIO_LIBERO_FS_DUMP=`df -k | awk '/sybased1/ { print int($3 / 1000); }' `
SPAZIO_LIBERO_FS_DB=`df -k | awk '/sybased2/ { print int($3 / 1000); }' `  

if [ $SPAZIO_LIBERO_FS_DUMP -lt $SOGLIA_FS_DUMP_MB ] ; then
   echo `hostname`
   echo "    "
   echo "    "
   echo "ATTENZIONE !!!!!! FILE SYSTEM /sybased1 SENZA SPAZIO DI MANOVRA"
   echo "SPAZIO LIBERO: " $SPAZIO_LIBERO_FS_DUMP "Mb < " $SOGLIA_FS_DUMP_MB " Mb"
   echo "    "
   echo "    "
fi

if [ $SPAZIO_LIBERO_FS_DB -lt $SOGLIA_FS_DB_MB ] ; then
   echo `hostname`
   echo "    "
   echo "    "
   echo "ATTENZIONE !!!!!! FILE SYSTEM /sybased2 SENZA SPAZIO DI MANOVRA"
   echo "SPAZIO LIBERO: " $SPAZIO_LIBERO_FS_DB "Mb < " $SOGLIA_FS_DB_MB " Mb"
   echo "    "
   echo "    "
fi
