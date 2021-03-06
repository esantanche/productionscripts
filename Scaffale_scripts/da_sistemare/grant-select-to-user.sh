#!/bin/sh 
#

# VOLENDO CAMBIARE GLI UTENTI OWNER E GRANTEE, MODIFICARE QUI IL NOME
# ??? TBW prendere i nomi da linea comando
NOME_OWNER=MUREXDB
NOME_GRANTEE=SIFinanza

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

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
   exit 0
fi

DBESISTENTE=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF  | awk '/DBESISTENTE/ { print $2; }'
select "DBESISTENTE",count(*) from sysdatabases where name="$1"
go
exit
EOF`

if [ $DBESISTENTE -eq 0 ] ; then
   echo "Il db " $1 " non esiste."
   exit 0
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

#echo $UID_OWNER,$UID_GRANTEE

if [ a$UID_OWNER = a ] ; then
   echo Errore: owner $NOME_OWNER non trovato
   exit 0;
fi

if [ a$UID_GRANTEE = a ] ; then
   echo Errore: grantee $NOME_GRANTEE non trovato
   exit 0;
fi

clear
echo " " 
echo "Questo script dara' il grant di select all'utente " $NOME_GRANTEE "(uid="$UID_GRANTEE")"
echo "per tutte le tabelle (solo tabelle) di proprieta' dell'utente " $NOME_OWNER "(uid="$UID_OWNER")"
echo "presenti nel database " $NOMEDB 
echo "Ricordo che siamo sull'ASE " $ASE_NAME 
echo " "

echo "Dare S poi invio per avviare l'operazione o N e invio per non proseguire"
read risposta
if [ $risposta != "S" ] ; then
   exit 0;
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

# PROVA
#head -2 /tmp/grant_select_query2  > /tmp/grant_select_appo
#cp /tmp/grant_select_appo /tmp/grant_select_query2
#

echo " "

# Controllo se non ho grant da dare

# PROVA
#echo RTI#HISLINK_DBF    > /tmp/grant_select_query2
#echo RTI#HISXLINK_DBF      >> /tmp/grant_select_query2

NUMERO_TABELLE_DA_GRANTARE=`cat /tmp/grant_select_query2 | wc -l`
if [ $NUMERO_TABELLE_DA_GRANTARE -eq 0 ] ; then
   echo "Nessuna tabella a cui dare il grant."
   echo " "
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

echo "Query effettuata: "
echo ------------------------------------------
cat $QRY
echo ------------------------------------------
echo " "

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -i $QRY > $UTILITY_DIR/out/grant_select_result.log 

echo "Viene ora inviata una mail a dba@kyneste.com con gli"
echo "eventuali errori e la lista delle tabelle per le quali"
echo "e' stato effettuato il grant." 
echo "Se non ci sono errori la lista va inviata al cliente."
echo " "

echo "Subject: 1B Report operazione di grant select"  >  /tmp/grant$$.mail
echo "To: dba@kyneste.com"  >> /tmp/grant$$.mail

echo " " >> /tmp/grant$$.mail
echo "ASE     " $ASE_NAME  >> /tmp/grant$$.mail
echo "Owner   " $NOME_OWNER  >> /tmp/grant$$.mail
echo "Grantee " $NOME_GRANTEE  >> /tmp/grant$$.mail
echo "DB      " $NOMEDB >> /tmp/grant$$.mail

echo " " >> /tmp/grant$$.mail
echo "Errori riscontrati" >> /tmp/grant$$.mail
echo "-------------------------------------------" >> /tmp/grant$$.mail
cat $UTILITY_DIR/out/grant_select_result.log >> /tmp/grant$$.mail
echo "-------------------------------------------" >> /tmp/grant$$.mail
echo " " >> /tmp/grant$$.mail
echo "Tabelle per le quali e' stato effettuato il grant" >> /tmp/grant$$.mail
echo "-------------------------------------------" >> /tmp/grant$$.mail
cat $UTILITY_DIR/out/grant_select_lista_tabelle_grantate >> /tmp/grant$$.mail 
echo "-------------------------------------------" >> /tmp/grant$$.mail

/usr/sbin/sendmail -f murex@kyneste.com dba@kyneste.com < /tmp/grant$$.mail       

rm /tmp/grant$$.mail      

rm /tmp/grant_select*

