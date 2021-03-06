#!/bin/sh -x
#
date > /tmp/date-dump.log
#DATA=$(/usr/bin/date +%d)

PWD=capdevpwd
ASENAME=MX1_DEV_2

# Dump a rotazione per gli ultimi 10 gg
# Corrado: 3 giugno 2003

# Modifiche E.Santanche 13.10.2003 per utilizzo script che fa il backup di tutti i db

# Impostando ROT a 5 vengono conservati 6 giorni di dump (E.Santanche)
ROT=5
HOST=$(hostname)
DD=$(date)

if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then 
        exit 0;
fi

if [ ! -f "/sybase/utility/progr.txt" ];
        then
        echo "0" > /sybase/utility/progr.txt
fi

ONE=$(cat /sybase/utility/progr.txt)
DATA=`expr $ONE + 1`

if [ $DATA -gt $ROT ];
        then
        DATA=0
fi

echo $DATA > /sybase/utility/progr.txt    #### DECOMMENTARE !!!!!!!!!!!!!!!!!!!!!!!!!!!
#DATA=2505  #  !!!! CANCELLARE QUESTA RIGA !!!!!

for i in `isql -Usa -P$PWD -S$ASENAME  <<  EOF | egrep -v 'name|----------'
set nocount on
go
select name from sysdatabases where name not in ("dbccdb","tempdb","model","sybsystemdb","CAP_REPORT") order by dbid
go
EOF`
do
       echo "echo PROCESSING " $i $i$DATA.dmp >> /tmp/$$.dump
       echo "# " $i $i$DATA.dmp `date` >> /tmp/$$.dump
       echo "isql -Usa -P" $PWD " -S" $ASENAME " << EOF > /tmp/$$.err " >> /tmp/$$.dump
       echo dump database $i to \"/sybased1/dump/$i$DATA.dmp\" >> /tmp/$$.dump
       echo go >> /tmp/$$.dump
       echo quit >> /tmp/$$.dump
       echo EOF >> /tmp/$$.dump
       echo "cat /tmp/$$.err >> /tmp/$$.allerr" >> /tmp/$$.dump  
       echo "echo ZIPPING " $i >> /tmp/$$.dump
       echo sh /sybase/utility/zip-dump.sh >> /tmp/$$.dump 
done

cat /tmp/$$.dump > /sybase/utility/dumpscript.tmp
sh /tmp/$$.dump
cat /tmp/$$.allerr > /sybase/utility/dumperrs.tmp

# bisognera' fare il grep "DUMP is complete" di /sybase/utility/dumperrs.tmp
# e contare quanti DUMP is complete sono usciti
# e verificare che siano in numero uguale al numero di db da dumpare
# altrimenti mandare un messaggio

ER=$(cat /tmp/$$.allerr | egrep 'No space left on device|Error writing|ERROR' | wc -l)

if [ $ER != 0 ]
then
  echo "Date:      $DD" >> /sybased1/dump/dump.err
  echo "Problem:   No space left on device - Error writing" >> /sybased1/dump/dump.err
  echo "--------------------------------------------------------------------------------------" >> /sybased1/dump/dump.err
  cat /tmp/$$.allerr >> /sybased1/dump/dump.err
fi

echo "FINAL ZIPPING"
sh /sybase/utility/zip-dump.sh

# E.Santanche' 10.12.2003 bcp delle tabelle di sistema
#cd /sybase/utility
#rm *.bcp
#rm $ASENAME-sysbcp*
#sh sysbcp.sh
#tar cvf $ASENAME-sysbcp-$DATA.tar *.bcp
#gzip $ASENAME-sysbcp-$DATA.tar
#mv $ASENAME-sysbcp-$DATA.tar.gz /sybased1/dump

# 15.12.2003: cdaquino
rm -f /tmp/$$.err
rm -f /tmp/$$.dump
rm -f /tmp/$$.allerr

echo Backup concluso
date >> /tmp/date-dump.log
