#!/bin/sh 

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

# export PATH_ERRORLOG_BACKUPSERVER=/sybase/ASE-12_5/install/MX1_DEV_2_back.log

echo -----------------------------------------------------------
echo Ultimi dump completati come da output dello script di dump
echo -----------------------------------------------------------
#cat $PATH_ERRORLOG_BACKUPSERVER | grep "DUMP is complete" | tail -9
cat $UTILITY_DIR/dumperrs.tmp | grep "DUMP is complete" 
#rm  $UTILITY_DIR/dumperrs.tmp 

echo ------------------------------------------------------------
echo Ultimi dump effettuati
echo ------------------------------------------------------------
ls -ltr /sybased1/dump | tail -10

echo ------------------------------------------------------------
echo Comando showserver
echo ------------------------------------------------------------
showserver
echo ------------------------------------------------------------
