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
   exit 1
fi

NOMEDB=CAP_REPORT
NOMEDUMP=CAP_PROD_TO_LOAD-NOZIP.cmp.dmp

#NOMEDB=kymx_dbadb
#NOMEDUMP=cancellami.cmp.dmp     

DATA=$(/usr/bin/date +%Y%m%d)

if [ ! -f /sybased1/dump/CAP_PROD_TO_LOAD-NOZIP.cmp.dmp ] ; then
   echo "Dump non trovato per script load_CAP_REPORT_comp.sh" 
   echo "Il dump non va cancellato perche' deve rimanere come"
   echo "segnaposto"
   echo "    "
   REPNAGIOS=/nagios_reps/Fallimento_load_CAP_REPORT_$DATA
   echo "Fallimento load_CAP_REPORT_comp.sh" > $REPNAGIOS
   echo "Caso dump non trovato" >> $REPNAGIOS
   echo "Rifare trasferimento da CAP_PROD a CAP_REPORT con loadmx_preservando_sysusers.sh" >> $REPNAGIOS
   echo "Vedere DOCMUREX-Dump&Load handbook.txt" >> $REPNAGIOS
   cat $REPNAGIOS
   segnalazione_errore
   exit 1;
fi

ESITO_DUMP_OK=`grep ok $UTILITY_DIR/out/esito_ultimo_dumpmx_alldb_su_prod | wc -l`
rm -f $UTILITY_DIR/out/esito_ultimo_dumpmx_alldb_su_prod 2>/dev/null
if [ $ESITO_DUMP_OK -eq 0 ] ; then
   echo "Dump non riuscito su mx2-prod-pridb."
   echo "   "
   REPNAGIOS=/nagios_reps/Fallimento_load_CAP_REPORT_$DATA
   echo "Fallimento load_CAP_REPORT_comp.sh" > $REPNAGIOS
   echo "Caso dump non riuscito su mx2-prod-pridb" >> $REPNAGIOS
   echo "Rifare trasferimento da CAP_PROD a CAP_REPORT con loadmx_preservando_sysusers.sh" >> $REPNAGIOS
   echo "Vedere DOCMUREX-Dump&Load handbook.txt" >> $REPNAGIOS
   cat $REPNAGIOS
   segnalazione_errore
   exit 1;
fi

sh $UTILITY_DIR/kill_sessions.sh $NOMEDB
ERRORE=$?
if [ $ERRORE -gt 0 ] ; then
   echo Errore nella kill delle sessioni su $NOMEDB
   echo ==
fi

#echo "============================================================="
#echo "Eseguo il bcp out di sysusers e sysalternates..."

bcp $NOMEDB..sysusers out $UTILITY_DIR/data/sysusers_${NOMEDB}.bcp -c -P $SAPWD -S $ASE_NAME -U $SAUSER >/dev/null 

ERR=$?
if [ $ERR -gt 0 ] ; then
   echo "Errore nella bcp out sysusers: " $ERR
   segnalazione_errore
   exit 1
fi

bcp $NOMEDB..sysalternates out $UTILITY_DIR/data/sysalternates_${NOMEDB}.bcp -c -P $SAPWD -S $ASE_NAME -U $SAUSER >/dev/null

ERR=$?
if [ $ERR -gt 0 ] ; then
   echo "Errore nella bcp out sysalternates: " $ERR
   segnalazione_errore
   exit 1
fi

#echo ===================================================
#echo Load di CAP_REPORT
#echo "  "

isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF > /tmp/output_load_capreport_comp
load database $NOMEDB from "compress::/sybased1/dump/${NOMEDUMP}"
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

#load database $NOMEDB from "compress::/sybased1/dump/CAP_PROD_TO_LOAD-NOZIP.cmp.dmp"

LOAD_IS_COMPLETE=`grep "LOAD is complete" /tmp/output_load_capreport_comp | wc -l`
#echo $LOAD_IS_COMPLETE
if [ $LOAD_IS_COMPLETE -eq 0 ] ; then
   echo "ERRORE NELLA LOAD DI CAP_REPORT!"
   echo "Load da rifare!"
   echo "    "
   REPNAGIOS=/nagios_reps/Fallimento_load_CAP_REPORT_$DATA
   echo "Fallimento load_CAP_REPORT_comp.sh" > $REPNAGIOS
   echo "Caso load non riuscito" >> $REPNAGIOS
   echo "Rifare trasferimento da CAP_PROD a CAP_REPORT con loadmx_preservando_sysusers.sh" >> $REPNAGIOS
   echo "Vedere DOCMUREX-Dump&Load handbook.txt" >> $REPNAGIOS
   cat $REPNAGIOS
   segnalazione_errore
   exit 1;
fi

#echo ===================================================
#echo bcp della sysusers e della sysalternates
#echo "   "

bcp $NOMEDB..sysusers in /sybase/utility/data/sysusers_${NOMEDB}.bcp -c -P $SAPWD -S $ASE_NAME -U $SAUSER >/dev/null

ERR=$?
if [ $ERR -gt 0 ] ; then
   echo "Errore nella bcp in sysusers: " $ERR
   echo "    "
   REPNAGIOS=/nagios_reps/Fallimento_load_CAP_REPORT_$DATA
   echo "Fallimento load_CAP_REPORT_comp.sh" > $REPNAGIOS
   echo "Caso errore nella bcp in sysusers: " $ERR >> $REPNAGIOS
   echo "Rifare trasferimento da CAP_PROD a CAP_REPORT con loadmx_preservando_sysusers.sh" >> $REPNAGIOS
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
   REPNAGIOS=/nagios_reps/Fallimento_load_CAP_REPORT_$DATA
   echo "Fallimento load_CAP_REPORT_comp.sh" > $REPNAGIOS
   echo "Caso errore nella bcp in sysalternates: " $ERR >> $REPNAGIOS
   echo "Rifare trasferimento da CAP_PROD a CAP_REPORT con loadmx_preservando_sysusers.sh" >> $REPNAGIOS
   echo "Vedere DOCMUREX-Dump&Load handbook.txt" >> $REPNAGIOS
   cat $REPNAGIOS
   segnalazione_errore
   exit 1;
fi

#rm /sybased1/dump/CAP_PROD_TO_LOAD-NOZIP.cmp.dmp
rm /tmp/output_load_capreport_comp
chmod 660 $UTILITY_DIR/data/sysusers_${NOMEDB}.bcp
chmod 660 $UTILITY_DIR/data/sysalternates_${NOMEDB}.bcp

echo "Subject: [LOADMX] Load ok su "$ASE_NAME" - db "$NOMEDB >  /tmp/loadmx.mail
echo "To: dba@kyneste.com"  >> /tmp/loadmx.mail
echo "Load effettuato" >> /tmp/loadmx.mail
echo "ASE " $ASE_NAME >> /tmp/loadmx.mail
echo "Host "`hostname` >> /tmp/loadmx.mail
echo "Nome db " $NOMEDB >> /tmp/loadmx.mail
echo "Nome dump utilizzato " $NOMEDUMP >> /tmp/loadmx.mail
echo "    " >> /tmp/loadmx.mail
/usr/sbin/sendmail -f loadmxok@kyneste.com dba@kyneste.com < /tmp/loadmx.mail

rm -f /tmp/loadmx.mail

exit 0;

