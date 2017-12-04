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

# Un controllo che esistano i volume group sybase. Non fa mai male
if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then 
        exit 0;
fi

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 1
fi

# il 7.10 va fatto poi non piu'
MESE=$(/usr/bin/date +%m)
GIORNO=$(/usr/bin/date +%d)

if [ $MESE -gt 10 ] ; then
   echo CAP_SVIL DA non caricare
   exit 0
fi
if [ $MESE -eq 10 -a $GIORNO -gt 7 ] ; then
   echo CAP_SVIL DA non caricare
   exit 0
fi

DATA=$(/usr/bin/date +%Y%m%d)

if [ ! -f /sybased1/dump/CAP_PROD_TO_LOAD-NOZIP.cmp.dmp ] ; then
   echo "Dump non trovato per script load_CAP_SVIL_comp.sh" 
   echo "Il dump non va cancellato perche' deve rimanere come"
   echo "segnaposto"
   echo "    "
   REPNAGIOS=/nagios_reps/Fallimento_load_CAP_SVIL_$DATA
   echo "Fallimento load_CAP_SVIL_comp.sh" > $REPNAGIOS
   echo "Caso dump non trovato" >> $REPNAGIOS
   echo "Rifare trasferimento da CAP_PROD a CAP_SVIL con loadmx_preservando_sysusers.sh" >> $REPNAGIOS
   echo "Vedere DOCMUREX-Dump&Load handbook.txt" >> $REPNAGIOS
   cat $REPNAGIOS
   exit 1;
fi

ESITO_DUMP_OK=`grep ok $UTILITY_DIR/out/esito_ultimo_dumpmx_alldb_su_prod | wc -l`
# QUI NON CANCELLO L'ESITO PERCHE' CI PENSERA' load_CAP_REPORT_comp.sh
#rm -f $UTILITY_DIR/out/esito_ultimo_dumpmx_alldb_su_prod 2>/dev/null
if [ $ESITO_DUMP_OK -eq 0 ] ; then
   echo "Dump non riuscito su mx2-prod-pridb."
   echo "   "
   REPNAGIOS=/nagios_reps/Fallimento_load_CAP_SVIL_$DATA
   echo "Fallimento load_CAP_SVIL_comp.sh" > $REPNAGIOS
   echo "Caso dump non riuscito su mx2-prod-pridb" >> $REPNAGIOS
   echo "Rifare trasferimento da CAP_PROD a CAP_SVIL con loadmx_preservando_sysusers.sh" >> $REPNAGIOS
   echo "Vedere DOCMUREX-Dump&Load handbook.txt" >> $REPNAGIOS
   cat $REPNAGIOS
   exit 1;
fi

NOMEDB=CAP_SVIL

echo ===================================================
echo Elenco delle sessioni rimaste aperte su CAP_SVIL
echo "   "

isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF
select p.spid, p.hostname, p.suid, p.program_name from sysprocesses p, sysdatabases d where d.dbid=p.dbid and p.suid > 0 and d.name = 'CAP_SVIL'
go
exit
EOF

echo ===================================================
echo Load di CAP_SVIL
echo "  "

isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF > /tmp/output_load_capsvil_comp
load database $NOMEDB from "compress::/sybased1/dump/CAP_PROD_TO_LOAD-NOZIP.cmp.dmp"
go
online database $NOMEDB
go
use $NOMEDB
go
if @@error = 0 delete from sysusers
go
exit
EOF

LOAD_IS_COMPLETE=`grep "LOAD is complete" /tmp/output_load_capsvil_comp | wc -l`
#echo $LOAD_IS_COMPLETE
if [ $LOAD_IS_COMPLETE -eq 0 ] ; then
   echo "ERRORE NELLA LOAD DI CAP_SVIL!"
   echo "Load da rifare!"
   echo "    "
   REPNAGIOS=/nagios_reps/Fallimento_load_CAP_SVIL_$DATA
   echo "Fallimento load_CAP_SVIL_comp.sh" > $REPNAGIOS
   echo "Caso load non riuscito su mx2-prod-pridb" >> $REPNAGIOS
   echo "Rifare trasferimento da CAP_PROD a CAP_SVIL con loadmx_preservando_sysusers.sh" >> $REPNAGIOS
   echo "Vedere DOCMUREX-Dump&Load handbook.txt" >> $REPNAGIOS
   cat $REPNAGIOS
   exit 1;
else
   echo "LOAD CAP_SVIL ok"
fi

echo ===================================================
echo bcp della sysusers
echo "   "

bcp $NOMEDB..sysusers in /sybase/utility/data/sysusers_capsvil.bcp -c -P $SAPWD -S $ASE_NAME -U $SAUSER 

ERR=$?
if [ $ERR -gt 0 ] ; then
   echo "Errore nella bcp in: " $ERR
   echo "    "
   REPNAGIOS=/nagios_reps/Fallimento_load_CAP_SVIL_$DATA
   echo "Fallimento load_CAP_SVIL_comp.sh" > $REPNAGIOS
   echo "Caso errore nella bcp in: " $ERR >> $REPNAGIOS
   echo "Rifare trasferimento da CAP_PROD a CAP_SVIL con loadmx_preservando_sysusers.sh" >> $REPNAGIOS
   echo "Vedere DOCMUREX-Dump&Load handbook.txt" >> $REPNAGIOS
   cat $REPNAGIOS
   exit 1;
fi

#rm /sybased1/dump/CAP_PROD_TO_LOAD-NOZIP.cmp.dmp
rm /tmp/output_load_capsvil_comp

echo "Subject: Caricamento di CAP_SVIL da CAP_PROD eseguito correttamente"  >  /tmp/capsvil.mail
echo "To: dba@kyneste.com,csc@kyneste.com"  >> /tmp/capsvil.mail
echo "Il caricamento del db CAP_SVIL da CAP_PROD e' stato eseguito correttamente" >> /tmp/capsvil.mail
echo "occorre comunicarlo al cliente Murex" >> /tmp/capsvil.mail
echo `/usr/bin/date +%Y%m%d-%H%M` >> /tmp/capsvil.mail
/usr/sbin/sendmail -f capsvilok@kyneste.com dba@kyneste.com < /tmp/capsvil.mail
/usr/sbin/sendmail -f capsvilok@kyneste.com csc@kyneste.com < /tmp/capsvil.mail
rm -f /tmp/capsvil.mail
exit 0;

