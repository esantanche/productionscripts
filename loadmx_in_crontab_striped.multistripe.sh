#!/bin/sh 

# Questa e' la versione con gli stripe del load

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME

TMS=$(/usr/bin/date +%Y%m%d%H%M)
DUMP_DIR=$PATH_DUMP_DIR
INIZIO_ORE=$(/usr/bin/date +%H)
INIZIO_MIN=$(/usr/bin/date +%M)
INIZIO_EPOCH=`epoch-it.pl`

function calcolo_pattern_ricerca_stripe {
   #echo Nome prima stripe $NOMESTRIPE1
   PARTESX=`echo $NOMESTRIPE1 | cut -d "#" -f 1` 
   PARTEDX=`echo $NOMESTRIPE1 | cut -d "#" -f 3`
   PATTERN_RICERCA_STRIPE=`echo $PARTESX#?#$PARTEDX`
   #echo $PATTERN_RICERCA_STRIPE
}

function segnalazione_errore {

   FINE_ORE=$(/usr/bin/date +%H)
   FINE_MIN=$(/usr/bin/date +%M)
   FINE_EPOCH=`epoch-it.pl`

   sh $UTILITY_DIR/centro_log_operazioni.sh LOAD $NOMEDB 1 $INIZIO_ORE $INIZIO_MIN $FINE_ORE $FINE_MIN

   echo "Subject: [LOADMX] ERRORE NEL LOAD SU "$ASE_NAME >  $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
   echo "To: dba@kyneste.com"  >> $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
   echo "Si e' verificato un errore sul load sull'ASE "$ASE_NAME >> $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
   echo "sulla macchina "`hostname` >> $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
   echo "Nome db "$NOMEDB >> $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
   echo "Nome stripe 1 "$NOMESTRIPE1 >> $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
   #echo "Nome stripe 2 "$NOMESTRIPE2 >> $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
   #echo "Nome stripe 3 "$NOMESTRIPE3 >> $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
   echo "    " >> $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
   echo "Provvedere immediatamente a rifare il load" >> $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
   #/usr/sbin/sendmail -f loadmxerr@kyneste.com esantanche@tim.it < $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
   #/usr/sbin/sendmail -f loadmxerr@kyneste.com dba@kyneste.com < $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail

   sh $UTILITY_DIR/centro_unificato_messaggi.sh LOAD $NOMEDB 1 $INIZIO_EPOCH $FINE_EPOCH $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail

}

# Un controllo che esistano i volume group sybase. Non fa mai male
if [ $(lsvg -o | grep $SYBASE_VG_NAME | wc -l) -eq 0 ]
then 
        exit 0;
fi

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   #segnalazione_errore
   exit 1
fi

if [ $1a = a -o $2a = a ] ; then
   echo "Usage: dare come parametri il nome del db destinazione e il path completo del file contenente la prima"
   echo "stripe del dump. Per es. /syb_bkp_vari/dmpmx-MLC_CAP_TEST-20060312#1#.cmp.dmp"
   echo "Naturalmente nella stessa directory ci devono essere anche le altre stripe"
   echo "Come terzo parametro opzionale si puo' dare la stringa NOBCP per evitare il bcp out e in"
   echo "delle tabelle sysusers e sysalternates"
   #segnalazione_errore
   exit 1
fi

NOMEDB=$1
NOMESTRIPE1=$2 

if [ a$3 = aNOBCP ] ; then
   echo $0
   echo "Non devo fare bcp out e in di sysusers e sysalternates"
   NON_FARE_BCP=1
else
   NON_FARE_BCP=0
fi

#echo NON_FARE_BCP=$NON_FARE_BCP

if [ ! -f $NOMESTRIPE1 ] ; then
   echo Dump $NOMESTRIPE1 non esistente
   segnalazione_errore
   exit 1;
fi 

DBESISTENTE=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF  | awk '/DBESISTENTE/ { print $2; }'
select "DBESISTENTE",count(*) from sysdatabases where name="$NOMEDB"
go
exit
EOF`

if [ $DBESISTENTE -eq 0 ] ; then
   echo "Il db " $NOMEDB " non esiste."
   segnalazione_errore
   exit 1;
fi

# Calcolo il pattern di tutte le stripe
calcolo_pattern_ricerca_stripe

# Costruisco lo script sql da eseguire
# $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
PATH_SCRIPT_LOAD=$SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.sql
echo "load database $NOMEDB from" > $PATH_SCRIPT_LOAD
ls -1 $PATTERN_RICERCA_STRIPE | awk 'BEGIN { stripon="           "; }
                                           { print stripon,"\"compress::"$1"\""; stripon="  stripe on"; }' >> $PATH_SCRIPT_LOAD
cat >> $PATH_SCRIPT_LOAD <<EOF
go
online database $NOMEDB
go
exit
EOF

#cat $PATH_SCRIPT_LOAD

DATA=$(/usr/bin/date +%Y%m%d)

sh $UTILITY_DIR/kill_sessions.sh $NOMEDB
ERRORE=$?
if [ $ERRORE -gt 0 ] ; then
   echo Errore nella kill delle sessioni su $NOMEDB
   echo Codice errore $ERRORE
   echo ==
fi

if [ $NON_FARE_BCP -eq 0 ] ; then

   #echo ===================================================
   #echo bcp out della sysusers e della sysalternates
   #echo "   "

   if [ -s $UTILITY_DIR/data/sysusers_${NOMEDB}.bcp ] ; then
      cp $UTILITY_DIR/data/sysusers_${NOMEDB}.bcp $UTILITY_DIR/data/sysusers_${NOMEDB}.bcp.old
   fi
   bcp $NOMEDB..sysusers out $UTILITY_DIR/data/sysusers_${NOMEDB}.bcp -c -P $SAPWD -S $ASE_NAME -U $SAUSER >/dev/null

   ERR=$?
   if [ $ERR -gt 0 ] ; then
      echo "Errore nella bcp out sysusers: " $ERR
      echo "    "
      REPNAGIOS=/nagios_reps/Fallimento_load_${NOMEDB}_$DATA
      echo "Fallimento loadmx_in_crontab.sh" > $REPNAGIOS
      echo "Caso errore nella bcp out sysusers: " $ERR >> $REPNAGIOS
      echo "Vedere DOCMUREX-Dump&Load handbook.txt" >> $REPNAGIOS
      cat $REPNAGIOS
      segnalazione_errore
      exit 1;
   fi

   if [ -s $UTILITY_DIR/data/sysalternates_${NOMEDB}.bcp ] ; then
      cp $UTILITY_DIR/data/sysalternates_${NOMEDB}.bcp $UTILITY_DIR/data/sysalternates_${NOMEDB}.bcp.old
   fi
   bcp $NOMEDB..sysalternates out $UTILITY_DIR/data/sysalternates_${NOMEDB}.bcp -c -P $SAPWD -S $ASE_NAME -U $SAUSER         >/dev/null

   ERR=$?
   if [ $ERR -gt 0 ] ; then
      echo "Errore nella bcp out sysalternates: " $ERR
      echo "    "
      REPNAGIOS=/nagios_reps/Fallimento_load_${NOMEDB}_$DATA
      echo "Fallimento loadmx_in_crontab.sh" > $REPNAGIOS
      echo "Caso errore nella bcp out sysalternates: " $ERR >> $REPNAGIOS
      echo "Vedere DOCMUREX-Dump&Load handbook.txt" >> $REPNAGIOS
      cat $REPNAGIOS
      segnalazione_errore
      exit 1;
   fi

fi # if [ $NON_FARE_BCP -eq 0 ] ; then

#echo ===================================================
#echo Load di $NOMEDB
#echo "  "

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -i $PATH_SCRIPT_LOAD > $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.outload

LOAD_IS_COMPLETE=`grep "LOAD is complete" $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.outload | wc -l`
#echo $LOAD_IS_COMPLETE
if [ $LOAD_IS_COMPLETE -eq 0 ] ; then
   echo "ERRORE NELLA LOAD DI "$NOMEDB"!"
   echo "Load da rifare!"
   echo "    "
   REPNAGIOS=/nagios_reps/Fallimento_load_${NOMEDB}_$DATA
   echo "Fallimento loadmx_in_crontab.sh" > $REPNAGIOS
   echo "Caso load non riuscito" >> $REPNAGIOS
   echo "Vedere DOCMUREX-Dump&Load handbook.txt" >> $REPNAGIOS
   echo "======== output del load ========" >> $REPNAGIOS
   cat $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.outload >> $REPNAGIOS
   cat $REPNAGIOS
   segnalazione_errore
   exit 1;
fi

if [ $NON_FARE_BCP -eq 0 ] ; then

   #echo ===================================================
   #echo bcp in della sysusers e della sysalternates
   #echo "   "

   isql -U$SAUSER -P$SAPWD -S$ASE_NAME <<EOF > $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.outdelsystab
use $NOMEDB
go
delete from sysusers
if @@error != 0 select 'DELFALLITA_SYSUSERS'
go
delete from sysalternates
if @@error != 0 select 'DELFALLITA_SYSALTERNATES'
go
exit
EOF

   ERRORI_IN_DEL_SYSTABS=`grep DELFALLITA $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.outdelsystab | wc -l`
   if [ $ERRORI_IN_DEL_SYSTABS -gt 0 ] ; then
      echo "Errore nella delete delle tabelle sysusers e sysalternates" 
      echo "    "
      REPNAGIOS=/nagios_reps/Fallimento_load_${NOMEDB}_$DATA
      echo "Fallimento loadmx_in_crontab.sh" > $REPNAGIOS
      echo "Caso errore nella delete delle tabelle sysusers e sysalternates" >> $REPNAGIOS
      echo "Vedere DOCMUREX-Dump&Load handbook.txt" >> $REPNAGIOS
      cat $REPNAGIOS
      segnalazione_errore
      exit 1;
   fi

   bcp $NOMEDB..sysusers in $UTILITY_DIR/data/sysusers_${NOMEDB}.bcp -c -P $SAPWD -S $ASE_NAME -U $SAUSER >/dev/null

   ERR=$?
   if [ $ERR -gt 0 ] ; then
      echo "Errore nella bcp in sysusers: " $ERR
      echo "    "
      REPNAGIOS=/nagios_reps/Fallimento_load_${NOMEDB}_$DATA
      echo "Fallimento loadmx_in_crontab.sh" > $REPNAGIOS
      echo "Caso errore nella bcp in sysusers: " $ERR >> $REPNAGIOS
      echo "Vedere DOCMUREX-Dump&Load handbook.txt" >> $REPNAGIOS
      cat $REPNAGIOS
      segnalazione_errore
      exit 1;
   fi

   bcp $NOMEDB..sysalternates in $UTILITY_DIR/data/sysalternates_${NOMEDB}.bcp -c -P $SAPWD -S $ASE_NAME -U $SAUSER >/dev/null

   ERR=$?
   if [ $ERR -gt 0 ] ; then
      echo "Errore nella bcp in sysalternates: " $ERR
      echo "    "
      REPNAGIOS=/nagios_reps/Fallimento_load_${NOMEDB}_$DATA
      echo "Fallimento loadmx_in_crontab.sh" > $REPNAGIOS
      echo "Caso errore nella bcp in sysalternates: " $ERR >> $REPNAGIOS
      echo "Vedere DOCMUREX-Dump&Load handbook.txt" >> $REPNAGIOS
      cat $REPNAGIOS
      segnalazione_errore
      exit 1;
   fi

   chmod 660 $UTILITY_DIR/data/sysusers_${NOMEDB}.*
   chmod 660 $UTILITY_DIR/data/sysalternates_${NOMEDB}.*

fi # if [ $NON_FARE_BCP -eq 0 ] ; then

#echo "Load effettuato"
#echo "Host " `hostname`
#echo "Db   " $NOMEDB
#echo "Dump " $NOMESTRIPE1

echo "Subject: [LOADMX] Load ok su "$ASE_NAME" - db "$NOMEDB >  $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
echo "To: dba@kyneste.com"  >> $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
echo "Ripristino di database effettuato con successo" >> $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
echo "Nome del server Sybase sul quale e' stato fatto il ripristino - " $ASE_NAME >> $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
echo "Nome della macchina che ospita il server Sybase - "`hostname` >> $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
echo "Nome del database sul quale e' stato fatto il ripristino - " $NOMEDB >> $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
echo "Path della prima stripe $NOMESTRIPE1" >> $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
echo "Dettagli delle stripe" >> $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
ls -al $PATTERN_RICERCA_STRIPE >> $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
echo "    " >> $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
echo "=====================================" >> $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
echo "Script di load" >> $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
cat $PATH_SCRIPT_LOAD >> $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
#cat $UTILITY_DIR/loadmx-_in_crontab_spiegazioni_per_csc >> $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail

#/usr/sbin/sendmail -f loadmxok@kyneste.com dba@kyneste.com < $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
#/usr/sbin/sendmail -f loadmxok@kyneste.com csc@kyneste.com < $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail

FINE_ORE=$(/usr/bin/date +%H)
FINE_MIN=$(/usr/bin/date +%M)
FINE_EPOCH=`epoch-it.pl`

#sh $UTILITY_DIR/centro_log_operazioni.sh LOAD $NOMEDB 0 $INIZIO_ORE $INIZIO_MIN $FINE_ORE $FINE_MIN
sh $UTILITY_DIR/centro_unificato_messaggi.sh LOAD $NOMEDB 0 $INIZIO_EPOCH $FINE_EPOCH $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail

rm -f $PATH_SCRIPT_LOAD 

exit 0;

