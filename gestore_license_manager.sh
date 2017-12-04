#!/bin/sh
#

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

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

# Se abbiamo un parametro in linea comandi vuol dire che questa e'
# la seconda chiamata di questo script, vedi in fondo, ovvero
# il caso in cui questo script chiama se stesso

NOME_SCRIPT=$0

if [ $1a = a ] ; then
   FASE=1
else
   FASE=2
fi

echo `date` - Gestione del License Manager - $ASE_NAME
echo Fase $FASE


# Deve fare: 
# chiudere il lic mgr se attivo
# avviare il lic mgr in background
# dopo 10 min vedere se è attivo il vendor daemon (SYBASE)
# se non lo è segnalare
# dopo altri 10 min chiudere il lic mgr

# parametri necessari
# directory del SYSAM
# /opt/sybase-12.5/SYSAM

#SYBASE_SYSAM=SYSAM-1_0
#export SYBASE_SYSAM
#SYBASE_OCS=OCS-12_5
#export SYBASE_OCS
#SYBASE=/sybase

DIR_SYSAM=$SYBASE/$SYBASE_SYSAM
FILE_ERRORI=/nagios_reps/Errore_avvio_license_manager
PATH_DATE=/usr/bin/date

function lic_mgr_attivo {
   LIC_MGR_ATTIVO=0
   LIC_MGR_ATTIVO=`ps -o comm -u root,sybase| egrep "lmgrd|SYBASE" | wc -l`
}

function chiusura_lic_mgr {
   CHIUSURA_LIC_MGR_RIUSCITA=1
   $DIR_SYSAM/bin/lmutil lmdown -q >/dev/null
   sleep 15
   lic_mgr_attivo
   if [ $LIC_MGR_ATTIVO -gt 0 ] ; then
      PIDS=`ps -o pid,comm -u root,sybase | egrep "lmgrd|SYBASE" | awk '{ printf "%d ",$1; }'`
      echo Killing $PIDS
      kill $PIDS
      sleep 15
   fi
   lic_mgr_attivo
   if [ $LIC_MGR_ATTIVO -gt 0 ] ; then
      PIDS=`ps -o pid,comm -u root,sybase | egrep "lmgrd|SYBASE" | awk '{ printf "%d ",$1; }'`
      echo Killing SIGKILL $PIDS
      kill -9 $PIDS
      sleep 15
   fi
   lic_mgr_attivo
   if [ $LIC_MGR_ATTIVO -gt 0 ] ; then
      PIDS=`ps -o pid,comm -u root,sybase | egrep "lmgrd|SYBASE" | awk '{ printf "%d ",$1; }'`
      echo Impossibile killare il lic mgr - pid $PIDS
      CHIUSURA_LIC_MGR_RIUSCITA=0
   fi

}

################################################################
# Questa funzione scrive nel file di path $FILE_ERRORI un messaggio di errore oppure
# di ok se il codice di errore e' zero
# La variabile CODICE_ERRORE contiene il codice di errore
# Il messaggio esplicativo dell'errore viene letto dal file dbccmx_messaggi
function segnalazione_errore {
   #echo FN segnalazione_errore

   # CODICE_ERRORE=1 non riuscita chiusura lic mgr
   # CODICE_ERRORE=2 non riuscito avviamento lic mgr
   # CODICE_ERRORE=3 lic mgr non attivo al controllo dopo 5 minuti
   echo codice errore $CODICE_ERRORE > $FILE_ERRORI
   echo codice errore $CODICE_ERRORE 

   MESSAGGIO_ERRORE=`cat <<EOF | grep "^$CODICE_ERRORE"
1 Non riuscita la chiusura del License Manager
2 Non riuscito avviamento del License Manager
3 License Manager trovato inattivo 5 minuti dopo l'avviamento
EOF`

   DATA=$($PATH_DATE +%Y%m%d-%H%M)
   echo $DATA > $FILE_ERRORI
   echo Errore nella gestione del License Manager >> $FILE_ERRORI
   echo Script $NOME_SCRIPT >> $FILE_ERRORI
   echo Codice di errore $CODICE_ERRORE >> $FILE_ERRORI
   echo Messaggio di errore $MESSAGGIO_ERRORE >> $FILE_ERRORI

}

if [ $FASE -eq 2 ] ; then
   # Nella fase 2 abbiamo gia' avviato il Lic  Mgr e vogliamo solo verificare
   # che dopo un periodo di tempo, per es. 5 minuti, sia ancora attivo
   sleep 300
   lic_mgr_attivo

   if [ $LIC_MGR_ATTIVO -eq 0 ] ; then
      CODICE_ERRORE=3
      segnalazione_errore
      exit $CODICE_ERRORE
   fi

   exit 0
fi

# chiudere il lic mgr se attivo

# vedo se il lic mgr e' attivo
# o meglio devo vedere se e' perfettamente chiuso
# per cui vado a vedere la lista dei processi

lic_mgr_attivo

if [ $LIC_MGR_ATTIVO -gt 0 ] ; then
   echo "License Manager attivo"
   chiusura_lic_mgr
   # Chiudere Lic Mgr
   echo CHIUSURA_LIC_MGR_RIUSCITA=$CHIUSURA_LIC_MGR_RIUSCITA
   if [ $CHIUSURA_LIC_MGR_RIUSCITA -eq 0 ] ; then
      CODICE_ERRORE=1
      segnalazione_errore
      exit $CODICE_ERRORE
   fi     
else
   echo "License Manager *NON* attivo"
fi

# Avviare il lic mgr e vedere subito se e' partito
# (poi vedremo se il vendor daemon rimane in piedi)

# TBD configurare il log analizer per vedere se l'ASE parte senza lic mgr
# ./lmutil lmstat
# license server UP

# Avvio il lic mgr

P1="/sybase/SYSAM-1_0"
cd $P1
$P1/bin/lmgrd -c $P1/licenses/license.dat -l $P1/log/lmgrd.log 2> $P1/log/stderr.out &
sleep 15

# Controllo che sia partito
LIC_MGR_PARTITO=`$P1/bin/lmutil lmstat | grep "license server UP" | wc -l`

echo LIC_MGR_PARTITO=$LIC_MGR_PARTITO

if [ $LIC_MGR_PARTITO -eq 0 ] ; then
   CODICE_ERRORE=2
   segnalazione_errore
   exit $CODICE_ERRORE
fi

# Adesso esco in modo che possa partire l'avvio dell'ASE, ma lancio la
# seconda fase ovvero l'esecuzione di questo stesso script con un parametro
# non vuoto sulla linea comando
# Questa seconda esecuzione, vedere all'inizio di questo script, aspettera'
# 5 minuti e poi controllera' che il Lic Mgr sia ancora attivo

nohup $NOME_SCRIPT fase2 >/dev/null &

exit 0


