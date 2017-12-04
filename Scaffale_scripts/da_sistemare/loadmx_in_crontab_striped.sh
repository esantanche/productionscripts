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

DUMP_DIR=$PATH_DUMP_DIR
INIZIO_ORE=$(/usr/bin/date +%H)
INIZIO_MIN=$(/usr/bin/date +%M)

function calcolo_nome_altre_stripe {
   #echo Nome prima stripe $NOMESTRIPE1
   PARTESX=`echo $NOMESTRIPE1 | cut -d "#" -f 1` 
   PARTEDX=`echo $NOMESTRIPE1 | cut -d "#" -f 3`
   NOMESTRIPE2=`echo $PARTESX#2#$PARTEDX`
   NOMESTRIPE3=`echo $PARTESX#3#$PARTEDX`
   #echo $NOMESTRIPE2
}

function segnalazione_errore {

   FINE_ORE=$(/usr/bin/date +%H)
   FINE_MIN=$(/usr/bin/date +%M)

   sh $UTILITY_DIR/centro_log_operazioni.sh LOAD $NOMEDB 1 $INIZIO_ORE $INIZIO_MIN $FINE_ORE $FINE_MIN

   echo "Subject: [LOADMX] ERRORE NEL LOAD SU "$ASE_NAME >  /tmp/loadmx_in_crontab_$NOMEDB.mail
   echo "To: dba@kyneste.com"  >> /tmp/loadmx_in_crontab_$NOMEDB.mail
   echo "Si e' verificato un errore sul load sull'ASE "$ASE_NAME >> /tmp/loadmx_in_crontab_$NOMEDB.mail
   echo "sulla macchina "`hostname` >> /tmp/loadmx_in_crontab_$NOMEDB.mail
   echo "Nome db "$NOMEDB >> /tmp/loadmx_in_crontab_$NOMEDB.mail
   echo "Nome stripe 1 "$NOMESTRIPE1 >> /tmp/loadmx_in_crontab_$NOMEDB.mail
   echo "Nome stripe 2 "$NOMESTRIPE2 >> /tmp/loadmx_in_crontab_$NOMEDB.mail
   echo "Nome stripe 3 "$NOMESTRIPE3 >> /tmp/loadmx_in_crontab_$NOMEDB.mail
   echo "    " >> /tmp/loadmx_in_crontab_$NOMEDB.mail
   echo "Provvedere immediatamente a rifare il load" >> /tmp/loadmx_in_crontab_$NOMEDB.mail
   #/usr/sbin/sendmail -f loadmxerr@kyneste.com esantanche@tim.it < /tmp/loadmx_in_crontab_$NOMEDB.mail
   /usr/sbin/sendmail -f loadmxerr@kyneste.com dba@kyneste.com < /tmp/loadmx_in_crontab_$NOMEDB.mail
   rm -f /tmp/loadmx_in_crontab_$NOMEDB.mail

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
   #segnalazione_errore
   exit 1
fi

NOMEDB=$1
NOMESTRIPE1=$2 

if [ ! -f $NOMESTRIPE1 ] ; then
   echo Dump $NOMESTRIPE1 non esistente
   segnalazione_errore
   exit 1;
fi 

# Calcolo il nome della seconda stripe
calcolo_nome_altre_stripe

#echo Dopo chiamata funzione $NOMESTRIPE2

if [ ! -f $NOMESTRIPE2 ] ; then
   echo Dump $NOMESTRIPE2 non esistente
   segnalazione_errore
   exit 1;
fi

if [ ! -f $NOMESTRIPE3 ] ; then
   echo Dump $NOMESTRIPE3 non esistente
   #segnalazione_errore
   #exit 1;
   echo La terza stripe al momento va considerata opzionale
   CLAUSOLA_STRIPE3=""
else
   CLAUSOLA_STRIPE3="stripe on \"compress::$NOMESTRIPE3\""
fi

#echo $CLAUSOLA_STRIPE3

DATA=$(/usr/bin/date +%Y%m%d)

sh $UTILITY_DIR/kill_sessions.sh $NOMEDB
ERRORE=$?
if [ $ERRORE -gt 0 ] ; then
   echo Errore nella kill delle sessioni su $NOMEDB
   echo Codice errore $ERRORE
   echo ==
fi

#echo ===================================================
#echo bcp out della sysusers e della sysalternates
#echo "   "

bcp $NOMEDB..sysusers out /sybase/utility/data/sysusers_${NOMEDB}.bcp -c -P $SAPWD -S $ASE_NAME -U $SAUSER >/dev/null

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

bcp $NOMEDB..sysalternates out /sybase/utility/data/sysalternates_${NOMEDB}.bcp -c -P $SAPWD -S $ASE_NAME -U $SAUSER         >/dev/null

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

#echo ===================================================
#echo Load di $NOMEDB
#echo "  "

isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF > /tmp/loadmx_in_crontab_$NOMEDB.outload
load database $NOMEDB from "compress::$NOMESTRIPE1"
     stripe on "compress::$NOMESTRIPE2"
     $CLAUSOLA_STRIPE3
go
online database $NOMEDB
go
use $NOMEDB
go
if @@error = 0 delete from sysusers
go
if @@error = 0 delete from sysalternates
go
exit
EOF

LOAD_IS_COMPLETE=`grep "LOAD is complete" /tmp/loadmx_in_crontab_$NOMEDB.outload | wc -l`
#echo $LOAD_IS_COMPLETE
if [ $LOAD_IS_COMPLETE -eq 0 ] ; then
   echo "ERRORE NELLA LOAD DI "$NOMEDB"!"
   echo "Load da rifare!"
   echo "    "
   REPNAGIOS=/nagios_reps/Fallimento_load_${NOMEDB}_$DATA
   echo "Fallimento loadmx_in_crontab.sh" > $REPNAGIOS
   echo "Caso load non riuscito" >> $REPNAGIOS
   echo "Vedere DOCMUREX-Dump&Load handbook.txt" >> $REPNAGIOS
   cat $REPNAGIOS
   segnalazione_errore
   exit 1;
fi

#echo ===================================================
#echo bcp in della sysusers e della sysalternates
#echo "   "

bcp $NOMEDB..sysusers in /sybase/utility/data/sysusers_${NOMEDB}.bcp -c -P $SAPWD -S $ASE_NAME -U $SAUSER >/dev/null

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

bcp $NOMEDB..sysalternates in /sybase/utility/data/sysalternates_${NOMEDB}.bcp -c -P $SAPWD -S $ASE_NAME -U $SAUSER >/dev/null

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

rm /tmp/loadmx_in_crontab_$NOMEDB.outload
chmod 660 $UTILITY_DIR/data/sysusers_${NOMEDB}.bcp
chmod 660 $UTILITY_DIR/data/sysalternates_${NOMEDB}.bcp

#echo "Load effettuato"
#echo "Host " `hostname`
#echo "Db   " $NOMEDB
#echo "Dump " $NOMESTRIPE1

echo "Subject: [LOADMX] Load ok su "$ASE_NAME" - db "$NOMEDB >  /tmp/loadmx_in_crontab_$NOMEDB.mail
echo "To: dba@kyneste.com"  >> /tmp/loadmx_in_crontab_$NOMEDB.mail
echo "Ripristino di database effettuato con successo" >> /tmp/loadmx_in_crontab_$NOMEDB.mail
echo "Nome del server Sybase sul quale e' stato fatto il ripristino - " $ASE_NAME >> /tmp/loadmx_in_crontab_$NOMEDB.mail
echo "Nome della macchina che ospita il server Sybase - "`hostname` >> /tmp/loadmx_in_crontab_$NOMEDB.mail
echo "Nome del database sul quale e' stato fatto il ripristino - " $NOMEDB >> /tmp/loadmx_in_crontab_$NOMEDB.mail
echo "Nome del file utilizzato per il ripristino - stripe 1 - "$NOMESTRIPE1 >> /tmp/loadmx_in_crontab_$NOMEDB.mail
echo "Nome del file utilizzato per il ripristino - stripe 2 - "$NOMESTRIPE2 >> /tmp/loadmx_in_crontab_$NOMEDB.mail
echo "Nome del file utilizzato per il ripristino - stripe 3 - "$NOMESTRIPE3 >> /tmp/loadmx_in_crontab_$NOMEDB.mail
echo "Dettagli file usati per il ripristino" >> /tmp/loadmx_in_crontab_$NOMEDB.mail
ls -al $NOMESTRIPE1 >> /tmp/loadmx_in_crontab_$NOMEDB.mail
ls -al $NOMESTRIPE2 >> /tmp/loadmx_in_crontab_$NOMEDB.mail
ls -al $NOMESTRIPE3 >> /tmp/loadmx_in_crontab_$NOMEDB.mail
echo "    " >> /tmp/loadmx_in_crontab_$NOMEDB.mail
#cat $UTILITY_DIR/loadmx_in_crontab_spiegazioni_per_csc >> /tmp/loadmx_in_crontab_$NOMEDB.mail

/usr/sbin/sendmail -f loadmxok@kyneste.com dba@kyneste.com < /tmp/loadmx_in_crontab_$NOMEDB.mail
#/usr/sbin/sendmail -f loadmxok@kyneste.com csc@kyneste.com < /tmp/loadmx_in_crontab_$NOMEDB.mail

FINE_ORE=$(/usr/bin/date +%H)
FINE_MIN=$(/usr/bin/date +%M)

sh $UTILITY_DIR/centro_log_operazioni.sh LOAD $NOMEDB 0 $INIZIO_ORE $INIZIO_MIN $FINE_ORE $FINE_MIN

rm -f /tmp/loadmx_in_crontab_$NOMEDB.mail

exit 0;

