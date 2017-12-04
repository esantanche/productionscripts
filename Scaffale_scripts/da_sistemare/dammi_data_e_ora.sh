#!/bin/sh 
#

. /home/sybase/.profile

# Script per il reorg delle tabelle
# Vengono cancellate le tabelle utente nel tempdb

# Devo avere come parametro il nome del database su cui fare il reorg
# un parametro '-u' indica che va fatto solo l'update delle statistiche
# Quindi primo parametro nome del database, secondo parametro opzionale, -u 
#NOMEDB=$1

/usr/bin/date +%Y%m%d-%H:%M
/usr/bin/date +%Y.%m.%d-%H:%M:%S
/usr/bin/date +%Y%m%d%H%M

exit


