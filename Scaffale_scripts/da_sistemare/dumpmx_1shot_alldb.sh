#!/bin/sh 
#

if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then
        exit 0;
fi

if [ $1a = a ] ; then
   echo "Usage: dare come parametro il path di destinazione per il dump"
   echo "senza barra finale (es. /sybased2/savedump)"
   exit 0
fi

DUMP_DIR=$1

DATA=$(/usr/bin/date +%Y%m%d)

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

DB_NODUMP=`grep DB_DA_NON_DUMPARE $UTILITY_DIR/dumpmx_parametri | cut -f 2 -d =`

rm -f $DUMP_DIR/dmpmx1shot-$DATA.rep 2>/dev/null

NUMERODB=0
for i in `isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF | egrep -v 'name|----------'
set nocount on
go
select name from sysdatabases where name not in ($DB_NODUMP) order by name
go
EOF`
do
       sh $UTILITY_DIR/dumpmx_1shot_singolodb.sh $i $DATA $DUMP_DIR
       #echo $i
       NUMERODB=`expr $NUMERODB + 1`
done

echo $NUMERODB db dumpati verificare

# Esaminare il report
echo Risultati
cat $DUMP_DIR/dmpmx1shot-$DATA.rep 

exit 0;


