#!/bin/sh 
#

# Parametri che ricevo:
# 1 - nomedb
# 2 - nomeowner
# 3 - nomegrantee
# Poi eseguo il grant di select per tutte le tabelle dell'owner al grantee
# ma controllo che il grantee e l'owner esistano

# VOLENDO CAMBIARE GLI UTENTI OWNER E GRANTEE, MODIFICARE QUI IL NOME
NOMEDB=$1
NOME_OWNER=$2
NOME_GRANTEE=$3

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

# 1) andare sul db richiesto
# 2) ricavare l'uid dell'utente proprietario delle tabelle cercate (MUREXDB=3)
#     select uid from sysusers where name = 'MUREXDB'
# 3) ricavare l'uid dell'utente al quale si vuole dare il grant (SIFinanza=4)
# 4) La query 
#    select name from sysobjects where type='U' and uid=3 and id not in 
#    (select id from sysprotects where action=193 and uid=4)
#    order by name
#    mi dice i nomi delle tabelle (solo tabelle!) per le quali SIFInanza NON
#    ha il grant di select
# 5) il grant si fa cosi': grant select on MUREXDB.RTI#RTITEMP_DBF  to SIFinanza 

# Codici di ritorno
# 1 parametri insufficienti
# 2 il db non esiste
# 3 owner non trovato
# 4 grantee non trovato 
# 5 errore nello svolgimento delle grant

if [ $1a = a -o $2a = a -o $3a = a ] ; then
   echo "Usage: dare come parametro il nome del db in cui ci sono le tabelle"
   echo "delle quali dare il grant di select"
   echo "poi il nome dell'owner e il nome del grantee"
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

# Ricavo l'uid dell'owner e del grantee
UID_OWNER=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF  | awk '/UIDOWNER/ { print $2; }'
use $NOMEDB
go
select "UIDOWNER",uid from sysusers where name='$NOME_OWNER' 
go
quit
EOF`

UID_GRANTEE=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF  | awk '/UIDGRANTEE/ { print $2; }'
use $NOMEDB
go
select "UIDGRANTEE",uid from sysusers where name='$NOME_GRANTEE'           
go
quit
EOF`

if [ a$UID_OWNER = a ] ; then
   #echo Errore: owner $NOME_OWNER non trovato
   exit 3;
fi

if [ a$UID_GRANTEE = a ] ; then
   #echo Errore: grantee $NOME_GRANTEE non trovato
   exit 4;
fi

##################################
# Faccio la lista delle tabelle per le quali
# dare il grant

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 >/tmp/grant_select_query1 <<EOF
set nocount on
go
use $NOMEDB
go
select 'TABDAGRANTARE',name from sysobjects where type='U' and uid=$UID_OWNER and id not in 
(select id from sysprotects where action=193 and uid=$UID_GRANTEE)
order by name
go
quit
EOF

grep TABDAGRANTARE /tmp/grant_select_query1 | awk '{ print $2; }'  > /tmp/grant_select_query2
#tail -n +3 /tmp/grant_select_query1 > /tmp/grant_select_query2 

# Controllo se non ho grant da dare

NUMERO_TABELLE_DA_GRANTARE=`cat /tmp/grant_select_query2 | wc -l`
if [ $NUMERO_TABELLE_DA_GRANTARE -eq 0 ] ; then
   DATA=$(/usr/bin/date +%Y%m%d-%H:%M)
   echo $DATA $NOMEDB $NOME_OWNER $NOME_GRANTEE | awk '{ printf "%-14s %-20s %-10s %-10s %6d\n",
                                                         $1,$2,$3,$4,0; }' >> $UTILITY_DIR/out/grant_log 
   #rm -f /tmp/grant_select*
   exit 0;
fi

cp /tmp/grant_select_query2 $UTILITY_DIR/out/grant_select_lista_tabelle_grantate

# Creo il file con le istruzioni da eseguire

QRY=$UTILITY_DIR/out/grant_select_query_to_run.sql
echo use $NOMEDB > $QRY
echo go >> $QRY

for i in `cat /tmp/grant_select_query2`
do
   echo grant select on $NOME_OWNER.$i to $NOME_GRANTEE >> $QRY
   echo go >> $QRY
done

echo quit >> $QRY

# ESEGUO I GRANT

rm -f $UTILITY_DIR/out/grant_select_result.log

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -i $QRY > $UTILITY_DIR/out/grant_select_result.log 

#echo tappo >> $UTILITY_DIR/out/grant_select_result.log

if [ -s $UTILITY_DIR/out/grant_select_result.log ] ; then
   echo $NOMEDB $NOME_OWNER $NOME_GRANTEE
   cat $UTILITY_DIR/out/grant_select_result.log
   exit 6
fi

NUMERO_TABELLE_GRANTATE=`cat $UTILITY_DIR/out/grant_select_lista_tabelle_grantate | wc -l`

DATA=$(/usr/bin/date +%Y%m%d-%H:%M)
echo $DATA $NOMEDB $NOME_OWNER $NOME_GRANTEE $NUMERO_TABELLE_GRANTATE | awk '{ printf "%-14s %-20s %-10s %-10s %6d\n",
                                                       $1,$2,$3,$4,$5; }' >> $UTILITY_DIR/out/grant_log

#rm /tmp/grant_select*

exit 0 

