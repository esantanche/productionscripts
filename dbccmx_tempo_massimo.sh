#!/bin/sh 
#

# dbccmx_alldb.sh
# Questo script esegue il check di integrità dei database Sybase presenti nel server ASE attivo sulla macchina sulla
# quale lo script viene eseguito.
# I check vengono effettuati mediante opportuni comandi dbcc eseguiti dallo script dbccmx_singolodb.sh che viene 
# richiamato per ogni database
# Si utilizza il file dbccmx_parametri che contiene i parametri di funzionamento di questo script, quali l'elenco dei
# database dei quali non va fatto il check

. /home/sybase/.profile
. /sis/SIS-AUX-Envsetting.Sybase.sh

if [ $(lsvg -o | grep $SYBASE_VG_NAME | wc -l) -eq 0 ]
then
        exit 0;
fi

DATA=$(/usr/bin/date +%Y%m%d)

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

DATA=$(/usr/bin/date +%Y%m%d)

ORA=$(/usr/bin/date +%H:%M)

PRESENTI_SESSIONI_DBCC=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 <<EOF | awk '/NUM_SESSIONI_DBCC/ { print $2; }'
select 'NUM_SESSIONI_DBCC',count(*) from sysprocesses where cmd = 'DBCC' 
go
quit
EOF`

#echo PRESENTI_SESSIONI_DBCC=$PRESENTI_SESSIONI_DBCC 

if [ $PRESENTI_SESSIONI_DBCC -gt 0 ] ; then
   echo "Subject: [DBCCMX] RITARDO ESECUZIONE DBCC !!!!! (su "$ASE_NAME")" >  /tmp/dbccmx.mail
   echo "To: dba@kyneste.com"  >> /tmp/dbccmx.mail
   echo "Sono le $ORA e il dbcc ancora non e' finito" >> /tmp/dbccmx.mail
   echo "Si suggerisce di killarlo" >> /tmp/dbccmx.mail 
   echo "Hostname "`hostname` >> /tmp/dbccmx.mail
   echo "    " >> /tmp/dbccmx.mail
   #/usr/sbin/sendmail -f dbccmxerr@kyneste.com esantanche@tim.it < /tmp/dbccmx.mail
   #/usr/sbin/sendmail -f dbccmxerr@kyneste.com dba@kyneste.com < /tmp/dbccmx.mail
   echo "Dbcc in ritardo "$DATA"-"$ORA" su ASE "$ASE_NAME > /tmp/dbccmx.nagiosrep
   cp /tmp/dbccmx.nagiosrep /nagios_reps/Errore_dbcc_$DATA
   rm /tmp/dbccmx.nagiosrep
   rm -f /tmp/dbccmx.mail
fi

exit

