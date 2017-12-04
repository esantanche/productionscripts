#!/bin/sh 
#

# VOLENDO CAMBIARE GLI UTENTI OWNER E GRANTEE, MODIFICARE QUI IL NOME
NOME_OWNER=MUREXDB
NOME_GRANTEE=SIFinanza

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

if [ $1a = a ] ; then
   echo "Usage: dare come parametro il nome del db in cui ci sono le tabelle"
   echo "delle quali dare il grant di select"
   exit 1
fi

DBESISTENTE=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF  | awk '/DBESISTENTE/ { print $2; }'
select "DBESISTENTE",count(*) from sysdatabases where name="$1"
go
exit
EOF`

if [ $DBESISTENTE -eq 0 ] ; then
   echo "Il db " $1 " non esiste."
   exit 1
fi

NOMEDB=$1

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
   echo Errore: owner $NOME_OWNER non trovato
   exit 1;
fi

if [ a$UID_GRANTEE = a ] ; then
   echo Errore: grantee $NOME_GRANTEE non trovato
   exit 1;
fi

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 >/tmp/grant_select_query1 <<EOF
set nocount on
go
use $NOMEDB
go
select name from sysobjects where type='U' and uid=$UID_OWNER and id not in 
(select id from sysprotects where action=193 and uid=$UID_GRANTEE)
order by name
go
quit
EOF

tail -n +3 /tmp/grant_select_query1 > /tmp/grant_select_query2 

# Controllo se non ho grant da dare

NUMERO_TABELLE_DA_GRANTARE=`cat /tmp/grant_select_query2 | wc -l`
if [ $NUMERO_TABELLE_DA_GRANTARE -eq 0 ] ; then
   echo "Nessuna tabella a cui dare il grant." > $UTILITY_DIR/out/grant_select_result.notables
   echo $(/usr/bin/date +%Y%m%d-%H:%M:%S) >> $UTILITY_DIR/out/grant_select_result.notables
   rm -f /tmp/grant_select*
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

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -i $QRY > $UTILITY_DIR/out/grant_select_result.log 

if [ -s $UTILITY_DIR/out/grant_select_result.log ] ; then
   echo "Subject: [GRANT] ERRORI IN OPERAZIONE DI GRANT SELECT IN CRONTAB"  >  /tmp/grant$$.mail
else
   echo "Subject: [GRANT] Report operazione di grant select in crontab"  >  /tmp/grant$$.mail
fi

echo "To: dba@kyneste.com"  >> /tmp/grant$$.mail

echo "(Made by $UTILITY_DIR/grant-select-to-user-in-crontab.sh)"  >> /tmp/grant$$.mail

echo " " >> /tmp/grant$$.mail
echo "ASE     " $ASE_NAME  >> /tmp/grant$$.mail
#echo "Owner   " $NOME_OWNER  >> /tmp/grant$$.mail
#echo "Grantee " $NOME_GRANTEE  >> /tmp/grant$$.mail
echo "DB      " $NOMEDB >> /tmp/grant$$.mail

echo " " >> /tmp/grant$$.mail

if [ -s $UTILITY_DIR/out/grant_select_result.log ] ; then
   echo "ERRORI riscontrati" >> /tmp/grant$$.mail
   echo "-------------------------------------------" >> /tmp/grant$$.mail
   cat $UTILITY_DIR/out/grant_select_result.log >> /tmp/grant$$.mail
   echo "-------------------------------------------" >> /tmp/grant$$.mail
   echo " " >> /tmp/grant$$.mail
fi

#echo " " >> /tmp/grant$$.mail
echo "Grant effettuato per " `cat $UTILITY_DIR/out/grant_select_lista_tabelle_grantate | wc -l` "tabelle" >> /tmp/grant$$.mail

#echo "Tabelle per le quali e' stato effettuato il grant" >> /tmp/grant$$.mail
#echo "-------------------------------------------" >> /tmp/grant$$.mail
#cat $UTILITY_DIR/out/grant_select_lista_tabelle_grantate >> /tmp/grant$$.mail 
#echo "-------------------------------------------" >> /tmp/grant$$.mail

/usr/sbin/sendmail -f murex@kyneste.com dba@kyneste.com < /tmp/grant$$.mail       

rm /tmp/grant$$.mail      

rm /tmp/grant_select*

exit 0

