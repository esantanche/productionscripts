#!/bin/sh 

# Per trasferire dump prodotti da script di dump che non
# producono il file di notifica, es. il dump notturno, 
# fare uno script di dump
# fittizio che non fa il dump che giÃ  c'e' ma semplicemente
# produce e copia sulla macchina destinataria il file di
# notifica

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
INIZIO_EPOCH=`epoch-it.pl`

NOME_SCRIPT=$0

function segnalazione_errore {

   FINE_ORE=$(/usr/bin/date +%H)
   FINE_MIN=$(/usr/bin/date +%M)
   FINE_EPOCH=`epoch-it.pl`

   #sh $UTILITY_DIR/centro_log_operazioni.sh TRASF $DB_DESTINAZIONE 1 $INIZIO_ORE $INIZIO_MIN $FINE_ORE $FINE_MIN

   echo "Subject: [TRASF] ERRORE NEL TRASFERIMENTO SU "$ASE_NAME > /tmp/trasf.$$.mail
   echo "To: dba@kyneste.com" >> /tmp/trasf.$$.mail
   echo "(by $NOME_SCRIPT)" >> /tmp/trasf.$$.mail
   echo "Errore nel trasferimento di un dump e load su altro db" >> /tmp/trasf.$$.mail
   echo "Fase andata in errore --- "$FASE_ERRORE >> /tmp/trasf.$$.mail
   echo "Hostname di questa macchina --- "`hostname` >> /tmp/trasf.$$.mail
   echo "  " >> /tmp/trasf.$$.mail
   echo "Parametri usati ---" >> /tmp/trasf.$$.mail
   echo "(file $PARS)" >> /tmp/trasf.$$.mail
   echo "  " >> /tmp/trasf.$$.mail
   cat $PARS | grep -v "^ *#" | awk 'BEGIN { FS="="; }{ printf "%-50s %-50s\n",$1,$2; }' >> /tmp/trasf.$$.mail
   echo "  " >> /tmp/trasf.$$.mail
   echo "Log operazioni svolte ---" >> /tmp/trasf.$$.mail
   echo "  " >> /tmp/trasf.$$.mail
   cat $LOG >> /tmp/trasf.$$.mail
   if [ -s $PATH_FILE_NOTIFICA ] ; then
      echo "  " >> /tmp/trasf.$$.mail
      echo "File di notifica del termine del dump ---" >> /tmp/trasf.$$.mail
      echo "  " >> /tmp/trasf.$$.mail
      cat $PATH_FILE_NOTIFICA >> /tmp/trasf.$$.mail
   fi
   #echo "(by $NOME_SCRIPT)" >> /tmp/trasf.$$.mail
   echo "  " >> /tmp/trasf.$$.mail

   sh $UTILITY_DIR/centro_unificato_messaggi.sh TRASF $DB_DESTINAZIONE 1 $INIZIO_EPOCH $FINE_EPOCH /tmp/trasf.$$.mail

}

function datora {
   echo $(date +%Y%m%d-%H%M)
}

function calcolo_pattern_ricerca_stripe {
   #echo Nome prima stripe   $NOMEPRIMASTRIPE 
   PARTESX=`echo $NOMEPRIMASTRIPE    | cut -d "#" -f 1`
   PARTEDX=`echo $NOMEPRIMASTRIPE    | cut -d "#" -f 3`
   PATTERN_RICERCA_STRIPE=`echo $PARTESX#?#$PARTEDX`
   #echo $PATTERN_RICERCA_STRIPE
}

#echo $(datora) provo a scrivere data e ora

# Un controllo che esistano i volume group sybase. Non fa mai male
if [ $(lsvg -o | grep $SYBASE_VG_NAME | wc -l) -eq 0 ]
then 
   exit 0;
fi

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 1
fi

if [ $1a = a ] ; then
   echo "Usage: dare come parametro il path completo del file"
   echo "contenente i parametri necessari a questo script"
   exit 1
fi

PARS=$1

if [ ! -s $PARS ] ; then
   echo "File parametri $PARS non trovato"
   exit 1
fi

# il parametro su linea comando contiene il path nel file di impostazioni
# che contiene i seguenti parametri:
# DIR_APPOGGIO directory di appoggio per la copia
# DB_MITTENTE db mittente
# DB_DESTINAZIONE db destinazione
# HOST_MITTENTE macchina mittente
#  non in uso PATH_FILE_NOTIFICA path completo del file di notifica di fine dump
#    proveniente dalla macchina mittente
# DURATA_ATTESA_MINUTI quanto deve essere lunga l'attesa che arrivi
#    la notifica di fine dump
# ESEGUIRE_DBCC  vale 1 se va eseguito il dbcc, 0 altrimenti

DB_DESTINAZIONE=`grep DB_DESTINAZIONE $PARS | grep -v "^ *#" | cut -f 2 -d =`
DB_MITTENTE=`grep DB_MITTENTE $PARS | grep -v "^ *#" | cut -f 2 -d =`
HOST_MITTENTE=`grep HOST_MITTENTE $PARS | grep -v "^ *#" | cut -f 2 -d =`
DIR_APPOGGIO=`grep DIR_APPOGGIO $PARS | grep -v "^ *#" | cut -f 2 -d =`
PATH_FILE_NOTIFICA=`grep PATH_FILE_NOTIFICA $PARS | grep -v "^ *#" | cut -f 2 -d =`
DURATA_ATTESA_MINUTI=`grep DURATA_ATTESA_MINUTI $PARS | grep -v "^ *#" | cut -f 2 -d =`
ESEGUIRE_DBCC=`grep ESEGUIRE_DBCC $PARS | grep -v "^ *#" | cut -f 2 -d =`

if [ `grep CANCELLA_DUMP $PARS | grep -v "^ *#" | wc -l` -eq 0 ] ; then
   CANCELLA_DUMP=1
else
   CANCELLA_DUMP=`grep CANCELLA_DUMP $PARS | grep -v "^ *#" | cut -f 2 -d =`
fi

PATH_FILE_NOTIFICA=/tmp/notifica_dumpmx#${HOST_MITTENTE}#${DB_MITTENTE}

DBESISTENTE=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF  | awk '/DBESISTENTE/ { print $2; }'
select "DBESISTENTE",count(*) from sysdatabases where name="$DB_DESTINAZIONE"
go
exit
EOF`

if [ $DBESISTENTE -eq 0 ] ; then
   echo $(datora) ERRORE >> $LOG
   echo $(datora) "Il db "$DB_DESTINAZIONE" non esiste" >> $LOG
   FASE_ERRORE="Controllo che il db destinazione $DB_DESTINAZIONE esista"
   segnalazione_errore
   exit 1;
fi

LOG=$UTILITY_DIR/out/trasferimento_e_load_$DB_DESTINAZIONE.log

echo $(datora) Sono nello script trasferimento_e_load.sh > $LOG

echo $(datora) Path del file di notifica $PATH_FILE_NOTIFICA >> $LOG

# Cancello il file di notifica
rm -f $PATH_FILE_NOTIFICA

if [ -s $PATH_FILE_NOTIFICA ] ; then
   echo $(datora) ERRORE >> $LOG
   echo $(datora) Non riesco a cancellare il file di notifica >> $LOG
   FASE_ERRORE="Cancellazione file di notifica"
   segnalazione_errore
   exit 1;
fi

# Attendo DURATA_MINUTI minuti che appaia il file di notifica

#echo attesa in minuti $DURATA_ATTESA_MINUTI fine notifica $PATH_FILE_NOTIFICA

countdown_minuti=$DURATA_ATTESA_MINUTI
echo $(datora) Avvio il countdown di $countdown_minuti minuti >> $LOG
while [ $countdown_minuti -gt 0 -a ! -s $PATH_FILE_NOTIFICA ] ; 
do
   sleep 60
   countdown_minuti=`expr $countdown_minuti \- 1`
done

# Aspetto un pochino che finisca di scrivere il file 
sleep 60

if [ ! -s $PATH_FILE_NOTIFICA ] ; then
   echo $(datora) ERRORE >> $LOG
   echo $(datora) Non arriva il file $PATH_FILE_NOTIFICA >> $LOG
   FASE_ERRORE="Attesa del file di notifica"
   segnalazione_errore
   exit 1;
fi

echo $(datora) Notifica arrivata inizio scp e load e eventuale dbcc >> $LOG

DB_MITTENTE_CORRETTO=`grep " ${DB_MITTENTE} *$" $PATH_FILE_NOTIFICA | wc -l`

echo $(datora) Controllo che il dump sia quello del db mittente ${DB_MITTENTE} >> $LOG

if [ $DB_MITTENTE_CORRETTO -eq 0 ] ; then
   echo $(datora) ERRORE >> $LOG
   echo $(datora) "Che me stai a da, non e' il dump di $DB_MITTENTE!"  >> $LOG
   FASE_ERRORE="Controllo che il dump sia di $DB_MITTENTE"
   segnalazione_errore
   exit 1;
fi


#######################################################################
# Adesso devo fare l'scp delle stripe

echo $(datora) Avvio scp delle stripe verso $DIR_APPOGGIO >> $LOG
ERRORE=1
for s in `grep STRIPE $PATH_FILE_NOTIFICA | grep -v NOMEPRIMASTRIPE | awk '{ print $2; }'`
do
   echo $(datora) "      Avvio scp della stripe "$s >> $LOG
   scp $s $DIR_APPOGGIO >> $LOG
   ERRORE=$?
   if [ $ERRORE -gt 0 ] ; then
      break
   fi
done

if [ $ERRORE -gt 0 ] ; then
   echo $(datora) ERRORE >> $LOG
   echo $(datora) "Errore nell' scp del dump di $DB_MITTENTE!"  >> $LOG
   FASE_ERRORE="Copia mediante scp del dump di $DB_MITTENTE, cod errore $ERRORE"
   segnalazione_errore
   exit 1;
fi



#####################################################################
# Fase del load

NOMEPRIMASTRIPE=`grep NOMEPRIMASTRIPE $PATH_FILE_NOTIFICA | awk '{ print $2; }'`
echo $(datora) Avvio il load su $DB_DESTINAZIONE con prima stripe $NOMEPRIMASTRIPE >> $LOG

sh $UTILITY_DIR/loadmx_in_crontab_striped.multistripe.sh $DB_DESTINAZIONE $DIR_APPOGGIO/$NOMEPRIMASTRIPE
ERRORE=$?

if [ $ERRORE -gt 0 ] ; then
   echo $(datora) ERRORE >> $LOG
   echo $(datora) Errore nel load su $DB_DESTINAZIONE da esaminare >> $LOG
   FASE_ERRORE="Load su $DB_DESTINAZIONE, cod errore $ERRORE"
   segnalazione_errore
   exit 1;
fi

#######################################################################
# Adesso cancello il dump usato per il load

if [ $CANCELLA_DUMP -eq 1 ] ; then

   echo $(datora) Cancello il dump usato e presente in $DIR_APPOGGIO >> $LOG
   calcolo_pattern_ricerca_stripe
   rm -f $DIR_APPOGGIO/$PATTERN_RICERCA_STRIPE
   ERRORE=$? 

   if [ $ERRORE -gt 0 ] ; then
      echo $(datora) ERRORE >> $LOG
      echo $(datora) "Errore nella rimozione dei dump di $DB_MITTENTE!"  >> $LOG
      FASE_ERRORE="Rimozione del dump di $DB_MITTENTE, cod errore $ERRORE"
      segnalazione_errore
      exit 1;
   fi

else

   echo $(datora) Non cancello il dump usato e presente in $DIR_APPOGGIO >> $LOG

fi

###################################################################
# Fase del dbcc


if [ $ESEGUIRE_DBCC -gt 0 ] ; then

   echo $(datora) Avvio il dbcc del db $DB_DESTINAZIONE >> $LOG
   sh $UTILITY_DIR/dbccmx_singolodb.sh $DB_DESTINAZIONE
   ERRORE=$?

   if [ $ERRORE -gt 0 ] ; then
      echo $(datora) ERRORE >> $LOG
      echo $(datora) Errore nel dbcc di $DB_DESTINAZIONE >> $LOG
      FASE_ERRORE="Dbcc su $DB_DESTINAZIONE, cod errore $ERRORE"
      segnalazione_errore
      exit 1;
   fi

fi


FINE_ORE=$(/usr/bin/date +%H)
FINE_MIN=$(/usr/bin/date +%M)
FINE_EPOCH=`epoch-it.pl`

echo $(datora) Termine operazioni senza errori  >> $LOG

#sh $UTILITY_DIR/centro_log_operazioni.sh TRASF $DB_DESTINAZIONE 0 $INIZIO_ORE $INIZIO_MIN $FINE_ORE $FINE_MIN

echo "Subject: [TRASF] <OK> $DB_MITTENTE su $DB_DESTINAZIONE"  > /tmp/trasf.$$.mail
echo "To: dba@kyneste.com" >> /tmp/trasf.$$.mail
echo "(by $NOME_SCRIPT)" >> /tmp/trasf.$$.mail
echo "Trasferimento andato a buon fine" >> /tmp/trasf.$$.mail
echo "Hostname di questa macchina --- "`hostname` >> /tmp/trasf.$$.mail
echo "  " >> /tmp/trasf.$$.mail
echo "Parametri usati ---" >> /tmp/trasf.$$.mail
echo "(file $PARS)" >> /tmp/trasf.$$.mail
echo "  " >> /tmp/trasf.$$.mail
cat $PARS | grep -v "^ *#" | awk 'BEGIN { FS="="; }{ printf "%-50s %-50s\n",$1,$2; }' >> /tmp/trasf.$$.mail
echo "  " >> /tmp/trasf.$$.mail
echo "Log operazioni svolte ---" >> /tmp/trasf.$$.mail
echo "  " >> /tmp/trasf.$$.mail
cat $LOG >> /tmp/trasf.$$.mail
if [ -s $PATH_FILE_NOTIFICA ] ; then
   echo "  " >> /tmp/trasf.$$.mail
   echo "File di notifica del termine del dump ---" >> /tmp/trasf.$$.mail
   echo "  " >> /tmp/trasf.$$.mail
   cat $PATH_FILE_NOTIFICA >> /tmp/trasf.$$.mail >> /tmp/trasf.$$.mail
fi
#echo "(by $NOME_SCRIPT)" >> /tmp/trasf.$$.mail
echo "  " >> /tmp/trasf.$$.mail

#sh $UTILITY_DIR/centro_unificato_messaggi.sh LOAD $NOMEDB 0 $INIZIO_EPOCH $FINE_EPOCH $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
sh $UTILITY_DIR/centro_unificato_messaggi.sh TRASF $DB_DESTINAZIONE 0 $INIZIO_EPOCH $FINE_EPOCH /tmp/trasf.$$.mail


exit
