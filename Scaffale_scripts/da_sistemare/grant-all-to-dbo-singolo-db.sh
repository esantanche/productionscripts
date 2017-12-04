#!/bin/sh 
#

# Parametri che ricevo:
# 1 - nomedb
# Poi eseguo il grant select,update,delete,insert per tutte le tabelle al dbo

NOMEDB=$1

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 1
fi

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME

# Codici di ritorno
# 1 parametri insufficienti
# 2 il db non esiste
# 3 errore nello svolgimento delle grant

if [ $1a = a ] ; then
   echo "Usage: dare come parametro il nome del db in cui ci sono le tabelle"
   echo "delle quali dare il grant di select,update,insert,delete al dbo"
   exit 1
fi

DBESISTENTE=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF  | awk '/DBESISTENTE/ { print $2; }'
select "DBESISTENTE",count(*) from sysdatabases where name="$1"
go
exit
EOF`

if [ $DBESISTENTE -eq 0 ] ; then
   echo "Il db " $1 " non esiste."
   exit 2
fi

##################################
# Faccio la lista delle tabelle per le quali
# dare il grant

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 >/tmp/grant_alldbo_query1 <<EOF
set nocount on
go
use $NOMEDB
go
select 'TABDAGRANTARE',u.name,o.name from sysobjects o, sysusers u where o.type='U' and u.uid=o.uid
        and o.uid != 1
        order by o.name
go
quit
EOF

grep TABDAGRANTARE /tmp/grant_alldbo_query1 | awk '{ printf "%s.%s\n",$2,$3; }'  > /tmp/grant_alldbo_query2

#cat /tmp/grant_alldbo_query2

cp /tmp/grant_alldbo_query2 $UTILITY_DIR/out/grant_alldbo_lista_tabelle_grantate

# Creo il file con le istruzioni da eseguire

QRY=$UTILITY_DIR/out/grant_alldbo_query_to_run.sql
echo use $NOMEDB > $QRY
echo go >> $QRY

for i in `cat /tmp/grant_alldbo_query2`
do
   echo grant select,insert,delete,update on $i to dbo >> $QRY
   echo go >> $QRY
done

echo quit >> $QRY

# ESEGUO I GRANT

#cat $QRY

rm -f $UTILITY_DIR/out/grant_alldbo_result.log

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -i $QRY > $UTILITY_DIR/out/grant_alldbo_result.log 

#echo tappo >> $UTILITY_DIR/out/grant_select_result.log

if [ -s $UTILITY_DIR/out/grant_alldbo_result.log ] ; then
   echo $NOMEDB grant all a dbo errori trovati
   cat $UTILITY_DIR/out/grant_alldbo_result.log
   exit 3
fi

NUMERO_TABELLE_GRANTATE=`cat $UTILITY_DIR/out/grant_alldbo_lista_tabelle_grantate | wc -l`

DATA=$(/usr/bin/date +%Y%m%d-%H:%M)
#echo $DATA $NOMEDB $NOME_OWNER $NOME_GRANTEE $NUMERO_TABELLE_GRANTATE | awk '{ printf "%-14s %-20s %-10s %-10s %6d\n",
#                                                       $1,$2,$3,$4,$5; }' >> $UTILITY_DIR/out/grant_log

echo `hostname`
echo Nome db $NOMEDB
echo Grant select,update,insert,delete dato a $NUMERO_TABELLE_GRANTATE tabelle

#rm /tmp/grant_select*

exit 0 

