#!/bin/sh -x

# 2.1.2004 E.Santanche script chiamato dall'ASE mediante l'XP server
# per segnalare i threshold sui database
# i parametri passati sono quattro: nome del db, nome del segmento per il quale
# il threshold è stato superato, soglia in pagine del threshold, un indicatore
# di stato che vale 1 se si tratta di un last chance threshold, 0 altrimenti  
# 25.5.2004 Aggiungo un parametro di threshold urgente
# Sarebbe il quinto e vale URGENTE se appunto il threshold richiede una valutazione urgente
# Inoltre i last chance threshold vengono valutati come urgenti
# 9.8.2004 Il quinto parametro puo' ora valere anche LOG_ACTION a indicare che
# il threshold e' quello con la procedura sp_thr_azioni_su_log che effettua alcune
# azioni al raggiungimento di una data soglia sul log. Per es. esegue un checkpoint
# che potrebbe troncare il log in caso di riempimento eccessivo 

. /sis/SIS-AUX-Envsetting.Sybase.sh

###### Parametri impostati da set-scripts-env.sh e utilizzati qui #######################
# UTILITY_DIR        ovvero il path della directory di utility di Sybase
#################################################################

cd $UTILITY_DIR

DATA=$(/usr/bin/date +%Y%m%d-%H:%M)

SOGLIA=`echo $3 | awk '{ print int($1*4096/1048576); }'`

URGENTE=0
if [ $5'x' = 'URGENTEx' ] ; then
   URGENTE=1
fi

# Ignoro la log action ovvero il tentativo di checkpoint
# quando il log cresce troppo, tanto non serve a niente 

##########################################################
# Scrittura su log

if [ $4 -eq 1 ] ; then
   NOMELOG=thrlog-lastchance-$1
else
   NOMELOG=thrlog-$2-$1
fi 

echo $(/usr/bin/date +%Y%m%d-%H:%M) $SOGLIA | awk '{ printf "%-15s %6.0f MB\n",$1,$2; }' >> $UTILITY_DIR/out/$NOMELOG

echo "Subject: [THR] "$1" - "$2" - "$SOGLIA" Mb" >  /tmp/thr$$.mail
echo "To: dba@kyneste.com"  >> /tmp/thr$$.mail
echo "--------------------------------------------------------------------------------------" >> /tmp/thr$$.mail
echo "Il database " $1 " sulla macchina " `hostname` " per il segmento " $2 >> /tmp/thr$$.mail
echo "ha meno di " $SOGLIA " Mb liberi" >> /tmp/thr$$.mail
echo "--------------------------------------------------------------------------------------" >> /tmp/thr$$.mail
echo "Hostname:      " `hostname` >> /tmp/thr$$.mail
echo "Date:           $DATA  "  >> /tmp/thr$$.mail
echo "Problem: Threshold superato" >> /tmp/thr$$.mail
echo "Last chance flag:    $4" >> /tmp/thr$$.mail
echo "Database:      " $1 >> /tmp/thr$$.mail
echo "Segmento:      " $2 >> /tmp/thr$$.mail
echo "Soglia in Mb:  " $SOGLIA >> /tmp/thr$$.mail
echo "--------------------------------------------------------------------------------------" >> /tmp/thr$$.mail

if [ $URGENTE -eq 1 -o $4 -eq 1 ] ; then
   CODICE=1
else
   CODICE=0
fi

sh $UTILITY_DIR/centro_unificato_messaggi.sh THR ${1}_${2}_${SOGLIA} $CODICE 0 0 /tmp/thr$$.mail 

rm /tmp/thr$$.mail

exit 0

