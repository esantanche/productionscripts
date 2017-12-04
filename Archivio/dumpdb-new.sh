#!/bin/sh -x
#
# ??? a che serve ? (per i messaggi ?)
date > /tmp/date-dump.log
#DATA=$(/usr/bin/date +%d)

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

# Modifiche E.Santanche 13.10.2003 per utilizzo script che fa il backup di tutti i db

# Impostando ROT a 6 vengono conservati 7 giorni di dump (E.Santanche)
ROT=6
HOST=$(hostname)
DD=$(date)

if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then 
        exit 0;
fi

echo "${UTILITY_DIR}"
exit 0;

if [ ! -f "${UTILITY_DIR}/progr.txt" ];
        then
        echo "0" > $UTILITY_DIR/progr.txt
fi

ONE=$(cat $UTILITY_DIR/progr.txt)
DATA=`expr $ONE + 1`

if [ $DATA -gt $ROT ];
        then
        DATA=0
fi

# ???
#echo $DATA > /sybase/utility/progr.txt    #### DECOMMENTARE !!!!!!!!!!!!!!!!!!!!!!!!!!!
DATA=2805prova  #  !!!! CANCELLARE QUESTA RIGA !!!!!
#echo "select @@servername" > /tmp/$$.dump
#echo "go" >> /tmp/$$.dump

# ???? rimettere tutti i db (togli cioe' cap_svil e cap_test dalla lista degli esclusi)
for i in `isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF | egrep -v 'name|----------'
set nocount on
go
select name from sysdatabases where name not in ("dbccdb","tempdb","model","sybsystemdb","CAP_REPORT","CAP_SVIL","CAP_TEST") order by dbid
go
EOF`
do
       echo "echo PROCESSING " $i $i$DATA.dmp >> /tmp/$$.dump
       echo "# " $i $i$DATA.dmp `date` >> /tmp/$$.dump
       echo "isql -U" $SAUSER " -P" $SAPWD " -S" $ASE_NAME " << EOF > /tmp/$$.err " >> /tmp/$$.dump
       echo dump database $i to \"/sybased1/dump/$i$DATA.dmp\" >> /tmp/$$.dump
       echo go >> /tmp/$$.dump
       echo quit >> /tmp/$$.dump
       echo EOF >> /tmp/$$.dump
       echo "cat /tmp/$$.err >> /tmp/$$.allerr" >> /tmp/$$.dump  
       echo "echo ZIPPING " $i >> /tmp/$$.dump
       echo "sh /sybase/utility/zip-dump-new.sh" >> /tmp/$$.dump 
done

cat /tmp/$$.dump > /sybase/utility/dumpscript.tmp
# Qui vengono eseguiti i dump e i zip dopo ogni dump
# ??? sh /tmp/$$.dump
cat /tmp/$$.allerr > /sybase/utility/dumperrs.tmp

ER=$(cat /tmp/$$.allerr | egrep 'No space left on device|Error writing|ERROR' | wc -l)

if [ $ER != 0 ]
then
  echo "Date:      $DD" >> /sybased1/dump/dump-NOZIP.err
  echo "Problem:   No space left on device - Error writing" >> /sybased1/dump/dump-NOZIP.err
  echo "--------------------------------------------------------------------------------------" >> /sybased1/dump/dump-NOZIP.err
  cat /tmp/$$.allerr >> /sybased1/dump/dump-NOZIP.err
fi

echo "FINAL ZIPPING"
sh $UTILITY_DIR/zip-dump.sh

# E.Santanche' 10.12.2003 bcp delle tabelle di sistema
# DA RIMETTERE A POSTO
cd $UTILITY_DIR
rm *.bcp
rm $ASENAME-sysbcp*
sh $UTILITY_DIR/sysbcp.sh
tar cvf $ASENAME-sysbcp-$DATA.tar *.bcp
gzip $ASENAME-sysbcp-$DATA.tar
mv $ASENAME-sysbcp-$DATA.tar.gz /sybased1/dump

# 15.12.2003: cdaquino
rm -f /tmp/$$.err
rm -f /tmp/$$.dump
rm -f /tmp/$$.allerr

echo Backup concluso
date >> /tmp/date-dump.log
