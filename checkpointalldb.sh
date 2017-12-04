#!/bin/sh 
#

# E.Santanche 6.2.2004 script che esegue un checkpoint su tutti i db Sybase
# Va usato prima di effettuare uno shutdown 'forced' del server per evitare
# perdite di dati

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME

# Un controllo che esistano i volume group sybase. Non fa mai male
if [ $(lsvg -o | grep $SYBASE_VG_NAME | wc -l) -eq 0 ]
then 
        exit 0;
fi

for i in `isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF | egrep -v 'name|----------'
set nocount on
go
select name from sysdatabases order by dbid
go
EOF`
do
       echo "use " $i >> /tmp/$$.checkpoint
       echo "go" >> /tmp/$$.checkpoint
       echo "checkpoint" >> /tmp/$$.checkpoint
       echo "go" >> /tmp/$$.checkpoint
done

cat /tmp/$$.checkpoint > $UTILITY_DIR/out/checkpoint.tmp
isql -U$SAUSER -P$SAPWD -S$ASE_NAME -i /tmp/$$.checkpoint > /tmp/$$.errcheckpoint
cat /tmp/$$.errcheckpoint > $UTILITY_DIR/out/checkpoint.err

rm -f /tmp/$$.checkpoint
rm -f /tmp/$$.errcheckpoint

echo Checkpoint di tutti i db concluso

