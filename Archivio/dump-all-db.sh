#!/bin/sh -x
#

PWD=capdevpwd
ASENAME=MX1_DEV_2

# E.Santanche' - script di dump di tutti i db da utilizzare per dump cautelativi occasionali

# Questa variabile e' il suffisso numerico che viene messo ai dump
DATA=999

# Controllo che esistano i logical volume sybase
if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then 
        exit 0;
fi

# Produco lo script che esegue il dump di tutti i db e li zippa uno alla volta
for i in `isql -Usa -P$PWD -S$ASENAME  <<  EOF | egrep -v 'name|----------'
set nocount on
go
select name from sysdatabases where name not in ("dbccdb","tempdb","model","sybsystemdb") order by dbid
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

# Eseguo lo script creato
sh /tmp/$$.dump > /sybase/utility/dump-all.out
cat /tmp/$$.allerr > /sybase/utility/dump-all.err

rm /tmp/$$.dump
rm /tmp/$$.allerr

# Uno zip cautelativo finale di tutti i dump che dovessero essere rimasti non zippati
echo "FINAL ZIPPING"
sh /sybase/utility/zip-dump.sh

# Salvo le tabelle di sistema in /sybase/utility
sh /sybase/utility/sysbcp.sh

echo Backup concluso

