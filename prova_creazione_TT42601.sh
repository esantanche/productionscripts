#!/bin/sh 
#

. /home/sybase/.profile

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

. /sis/SIS-AUX-Envsetting.Sybase.sh

if [ $(lsvg -o | grep $SYBASE_VG_NAME | wc -l) -eq 0 ]
then
        exit 0;
fi


DATA=$(/usr/bin/date +%Y%m%d)
INIZIO_ORE=$(/usr/bin/date +%H) 
INIZIO_MIN=$(/usr/bin/date +%M)    

NOME_DB=CAP_PIPPO

#isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF > $UTILITY_DIR/creazione_db_TT42601_${NOME_DB}
cat << EOF > /tmp/.oggi/prova_TT42601_${NOME_DB}
disk init name = "${NOME_DB}#D01", physname = "/syb_db_${NOME_DB}/${NOME_DB}#D01.sybdev", size="32000M"
if @@error != 0 select 'ERROREINIT1'
go
disk init name = "${NOME_DB}#D02", physname = "/syb_db_${NOME_DB}/${NOME_DB}#D02.sybdev", size="32000M"
if @@error != 0 select 'ERROREINIT2'
go
disk init name = "${NOME_DB}#D03", physname = "/syb_db_${NOME_DB}/${NOME_DB}#D03.sybdev", size="24000M"
if @@error != 0 select 'ERROREINIT3'
go
disk init name = "${NOME_DB}#L01", physname = "/syb_db_${NOME_DB}/${NOME_DB}#L01.sybdev", size="8000M"
if @@error != 0 select 'ERROREINIT4'
go
create database ${NOME_DB} on ${NOME_DB}#D01 = "32000M", 
                              ${NOME_DB}#D02 = "32000M", 
                              ${NOME_DB}#D03 = "24000M"  
                       log on ${NOME_DB}#L01 = "8000M"
go
sp_dboption ${NOME_DB}, "select into/bulkcopy/pllsort", true
go
sp_dboption ${NOME_DB}, "trunc log on chkpt", true
go
use ${NOME_DB}
go
checkpoint
go
exit
EOF

FINE_ORE=$(/usr/bin/date +%H)       
FINE_MIN=$(/usr/bin/date +%M)   

cat $UTILITY_DIR/creazione_db_TT42601_${NOME_DB}

exit 0;

