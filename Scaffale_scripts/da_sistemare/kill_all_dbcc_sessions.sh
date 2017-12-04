#!/bin/sh 
#

# Questo script va eseguito da linea comando o richiamato da altri script
# e non in crontab 
# Se lo si vuole eseguire in crontab richiamarlo da altro script che
# va, quest'ultimo, in crontab

# Script che esegue il kill dei processi escludendo pero' quelli che stanno
# lavorando sul database master (quindi tipicamente quelli lanciati dal superuser
# e quindi anche i processi delle query eseguite da questo stesso script)

. /sis/SIS-AUX-Envsetting.Sybase.sh

if [ $(lsvg -o | grep $SYBASE_VG_NAME | wc -l) -eq 0 ]
then
      exit 0;
fi

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

# Eseguo la query che individua i numeri di processo da killare ovvero quelli di tutte
# le connessioni utente verso il db dato come parametro e che non siano di sistema (suid > 0) 

# Non c'e' il problema del fatto che potrebbe killare se stesso perche' la sessione
# isql che trova gli spid e' diversa da quella che fa i kill
# Puo' invece accadere che non trovi poi uno spid perche' quello della sessione
# che fa la select non c'e' piu' ma anche questo problema viene evitato escludendo tutti
# i processi che usano il db master

rm -f  /tmp/kill_all_dbcc_process.*   1>/dev/null 2>&1

isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF > /tmp/kill_all_dbcc_process.out
select 'PROC',spid from sysprocesses where cmd like 'DBCC%'
if @@error = 0 select 'okselectprocess'
go
quit
EOF

# Verifico che ci sia la stringa okselectprocess nell'output 
# altrimenti esco con errore

OKSELECTPROCESS=`grep okselectprocess /tmp/kill_all_dbcc_process.out | wc -l`
#echo $OKSELECTPROCESS

if [ $OKSELECTPROCESS -eq 0 ] ; then
   echo Errore nella query di individuazione dei processi da killare in kill_all_dbcc_sessions.sh 
   exit 1
fi

# Costruisco lo script sql che effettuera' i kill

cat /tmp/kill_all_dbcc_process.out | awk '/PROC/ { print "kill ",$2;
                                          print "if @@error != 0 select \047 errorekill \047";
                                          print "go"; }' > /tmp/kill_all_dbcc_process.sql
echo exit >> /tmp/kill_all_dbcc_process.sql

# Eseguo lo script sql che effettua i kill

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -i /tmp/kill_all_dbcc_process.sql > /tmp/kill_all_dbcc_process.esitokill

# Se trovo la stringa errorekill nell'output vuol dire che c'e' stato un errore

ERRKILL=`grep errorekill /tmp/kill_all_dbcc_process.esitokill | wc -l`
#echo $ERRKILL

if [ $ERRKILL -gt 0 ] ; then
   echo Errore nello script sql di esecuzione dei kill in kill_all_dbcc_sessions.sh
   exit 1
fi

exit 0

# niente mail qui perche' questo script viene richiamato da altri script
# solo codici di ritorno 
# eventualmente lo script chiamante pensa a mandare mail

