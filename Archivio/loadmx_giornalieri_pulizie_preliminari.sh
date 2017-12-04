#!/bin/sh 

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME

DUMP_DIR=/sybased1/dump

function segnalazione_errore {

   echo "Subject: [LOADMX] ERRORE NEL LOAD SU "$ASE_NAME >  /tmp/loadmx.mail
   echo "To: dba@kyneste.com"  >> /tmp/loadmx.mail
   echo "Si e' verificato un errore sul load sull'ASE "$ASE_NAME >> /tmp/loadmx.mail
   echo "sulla macchina "`hostname` >> /tmp/loadmx.mail
   echo "Nome db "$NOMEDB >> /tmp/loadmx.mail
   echo "Nome dump utilizzato "$NOMEDUMP >> /tmp/loadmx.mail
   echo "    " >> /tmp/loadmx.mail
   echo "Provvedere immediatamente a rifare il load" >> /tmp/loadmx.mail
   /usr/sbin/sendmail -f loadmxerr@kyneste.com esantanche@tim.it < /tmp/loadmx.mail
   /usr/sbin/sendmail -f loadmxerr@kyneste.com dba@kyneste.com < /tmp/loadmx.mail
   rm -f /tmp/loadmx.mail

}

# Un controllo che esistano i volume group sybase. Non fa mai male
if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then 
        exit 0;
fi

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   #segnalazione_errore
   exit 1
fi

if [ $1a = a -o $2a = a ] ; then
   echo "Usage: dare come parametri il nome del db destinazione e il nome del file di dump"
   echo "presente in "$DUMP_DIR
   #segnalazione_errore
   exit 1
fi

NOMEDB=$1
NOMEDUMP=$2 

if [ ! -f $DUMP_DIR/$NOMEDUMP ] ; then
   echo Dump $DUMP_DIR/$NOMEDUMP non esistente
   segnalazione_errore
   exit 1;
fi 

DATA=$(/usr/bin/date +%Y%m%d)

sh $UTILITY_DIR/kill_sessions.sh $NOMEDB
ERRORE=$?
if [ $ERRORE -gt 0 ] ; then
   echo Errore nella kill delle sessioni su $NOMEDB
   echo ==
fi

#echo ===================================================
#echo bcp out della sysusers e della sysalternates
#echo "   "

bcp $NOMEDB..sysusers out /sybase/utility/data/sysusers_${NOMEDB}.bcp -c -P $SAPWD -S $ASE_NAME -U $SAUSER         >/dev/null

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

isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF > /tmp/output_load_in_crontab
load database $NOMEDB from "compress::/sybased1/dump/$NOMEDUMP"
go
online database $NOMEDB
go
use $NOMEDB
go
if @@error = 0 delete from sysusers
go
exit
EOF

LOAD_IS_COMPLETE=`grep "LOAD is complete" /tmp/output_load_in_crontab | wc -l`
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

rm /tmp/output_load_in_crontab
chmod 660 $UTILITY_DIR/data/sysusers_${NOMEDB}.bcp
chmod 660 $UTILITY_DIR/data/sysalternates_${NOMEDB}.bcp

#echo "Load effettuato"
#echo "Host " `hostname`
#echo "Db   " $NOMEDB
#echo "Dump " $NOMEDUMP

echo "Subject: [LOADMX] Load ok su "$ASE_NAME" - db "$NOMEDB >  /tmp/loadmx.mail
echo "To: dba@kyneste.com"  >> /tmp/loadmx.mail
echo "Ripristino di database effettuato con successo" >> /tmp/loadmx.mail
echo "Nome del server Sybase sul quale e' stato fatto il ripristino - " $ASE_NAME >> /tmp/loadmx.mail
echo "Nome della macchina che ospita il server Sybase - "`hostname` >> /tmp/loadmx.mail
echo "Nome del database sul quale e' stato fatto il ripristino - " $NOMEDB >> /tmp/loadmx.mail
echo "Nome del file utilizzato per il ripristino - "$NOMEDUMP >> /tmp/loadmx.mail
echo "    " >> /tmp/loadmx.mail
cat $UTILITY_DIR/loadmx_in_crontab_spiegazioni_per_csc >> /tmp/loadmx.mail

/usr/sbin/sendmail -f loadmxok@kyneste.com dba@kyneste.com < /tmp/loadmx.mail
/usr/sbin/sendmail -f loadmxok@kyneste.com csc@kyneste.com < /tmp/loadmx.mail

rm -f /tmp/loadmx.mail

exit 0;

