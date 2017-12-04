#!/bin/sh 
#

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Questo script va eseguito da linea comando o richiamato da altri script
# e non in crontab 
# Se lo si vuole eseguire in crontab richiamarlo da altro script che
# va, quest'ultimo, in crontab

# Questo script esegue il kill dei processi che operano sul database che viene
# dato come parametro, escluso il database master

if [ $(lsvg -o | grep $SYBASE_VG_NAME | wc -l) -eq 0 ]
then
      exit 0;
fi

#if [ $USER != sybase ] ; then
#   echo Eseguire come sybase
#   exit 0
#fi

if [ $1a = a ] ; then
   echo "Usage: dare come parametro il nome del db verso il quale sono"
   echo "dirette le connessioni da killare"
   exit 0
fi

NOMEDB=$1

#rm -f  /tmp/kill_process.*   1>/dev/null 2>&1

# Verifico che il db esista

DBESISTENTE=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF  | awk '/DBESISTENTE/ { print $2; }'
select "DBESISTENTE",count(*) from sysdatabases where name="$NOMEDB"
go
exit
EOF`

if [ $DBESISTENTE -eq 0 ] ; then
   echo "Il db " $NOMEDB " non esiste."
   exit 0
fi

if [ $NOMEDB = master ] ; then
   echo "Non si eseguono cancellazioni di processi collegati al db master"
   exit 0
fi

# Eseguo la query che individua i numeri di processo da killare ovvero quelli delle
# connessioni verso il db dato come parametro e che non siano di sistema (suid > 0)

isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF > /tmp/kill_process_$$.out
select 'PROC',p.spid, p.hostname, p.suid from sysprocesses p, sysdatabases d where d.dbid=p.dbid and p.suid > 0 and d.name = '$NOMEDB'
if @@error = 0 select 'okselectprocess'
go
exit
EOF

#cp /tmp/kill_process_$$.out $UTILITY_DIR/out/output_kill_sessions

# Verifico che ci sia la stringa okselectprocess nell'output 
# altrimenti esco con errore

OKSELECTPROCESS=`grep okselectprocess /tmp/kill_process_$$.out | wc -l`

if [ $OKSELECTPROCESS -eq 0 ] ; then
   echo Errore nella query di individuazione dei processi da killare in kill_sessions.sh 
   rm -f /tmp/kill_process_$$.*
   exit 1
fi

# Costruisco lo script sql che effettuera' i kill

cat /tmp/kill_process_$$.out | awk '/PROC/ { print "kill ",$2;
                                          print "if @@error != 0 select \047 errorekill \047";
                                          print "go"; }' > /tmp/kill_process_$$.sql
echo exit >> /tmp/kill_process_$$.sql

# Eseguo lo script sql che effettua i kill

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -i /tmp/kill_process_$$.sql > /tmp/kill_process_$$.esitokill

# Se trovo la stringa errorekill nell'output vuol dire che c'e' stato un errore

ERRKILL=`grep errorekill /tmp/kill_process_$$.esitokill | wc -l`

if [ $ERRKILL -gt 0 ] ; then
   echo Errore nello script sql di esecuzione dei kill in kill_sessions.sh
   rm -f /tmp/kill_process_$$.*
   exit 1
fi

rm -f /tmp/kill_process_$$.*

exit 0

# niente mail qui perche' questo script viene richiamato da altri script
# solo codici di ritorno 
# eventualmente lo script chiamante pensa a mandare mail

