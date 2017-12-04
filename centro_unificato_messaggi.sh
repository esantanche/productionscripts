#!/bin/sh 
#

#****S* Messaging/Centro unificato messaggi
# NAME
#    centro_unificato_messaggi Gestore centralizzato messaggi degli script
# USAGE
#    Lo script viene chiamato dagli altri script al termine delle operazioni
#    per riportare in un apposito log l'esito dell'operazione e per inviare
#    messaggi via mail
# PURPOSE
#    Lo script riceve diversi parametri relativi all'operazione svolta dallo
#    script che l'ha eseguita e che lo chiama.
#    Lo script riporta le informazioni in un log poi, in caso di operazione non
#    riuscita scrive un file nella directory /nagios_reps in modo che nagios
#    lo legga e segnali un critical. Inoltre invia un messaggio via mail.
#    Se l'operazione e' andata a buon fine viene inviato il messaggio ed 
#    eventualmente viene scritto un file nella directory /inbacheca che verra'
#    poi segnalato dal server informativo SIS
# HISTORY
#    Versione iniziale
# INPUTS
#    I parametri richiesti sono:
#    * operazione, stringa identificativa dell'operazione effettuata
#    * specificazione, stringa che specifica per es. il nome del db sul quale e' stata effettuata
#    l'operazione
#    * esito, zero per operazione svolta con successo, maggiore di zero per operazione fallita
#    * ora di inizio, epoch dell'inizio dell'operazione
#    * ora di fine, epoch della fine dell'operazione
#    * path completo messaggio da mandare
# OUTPUT
#    Non sono prodotti output su console, vengono mandati messaggi email, viene prodotto un log
#    e vengono creati dei file nelle directory /nagios_reps e /inbacheca
# EXAMPLE
#    Viene riportata l'invocazione di questo script da parte
#    dello script loadmx_in_crontab_striped.multistripe.sh che esegue il load
#    di un db (i parametri sono posti su due righe)
#       sh $UTILITY_DIR/centro_unificato_messaggi.sh LOAD $NOMEDB 0 
#       $INIZIO_EPOCH $FINE_EPOCH $SYB_TMP_DIR/loadmx_cron.$TMS.$NOMEDB.mail
# NOTES
#    All'inizio dello script e' possibile impostare le variabili INVIO_IN_BACHECA e INVIO_MAIL
#    per attivare o disattivare rispettivamente la creazione di file nella directory /inbacheca
#    e l'invio di mail. Queste impostazioni vengono solitamente utilizzate quando ci sono
#    problemi con l'invio di mail. La variabile DESTINATARI_OK contiene l'elenco dei destinatari
#    delle mail da inviare se l'operazione e' andata a buon fine, la variabile DESTINATARI_KO
#    contiene l'elenco dei destinatari nel caso di operazioni fallite.
#    Il log prodotto si trova nella directory /sybase/utility/logs e ha nome mxmain_<nome ase>.log
#    e viene ruotato mediante lo script perl-logrotate.pl
# ERRORS
#    Non sono gestiti errori. Eventuali messaggi di errore si ottengono sullo stderr
# SEE ALSO
#    Quasi tutti gli script utilizzano questo per il logging e l'invio di messaggi
#***

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

if [ $(lsvg -o | grep $SYBASE_VG_NAME | wc -l) -eq 0 ]
then
        exit 0;
fi

# Parametro che dice se vanno mandate in bacheca le operazioni riuscite
# 1=inviare, 0=non inviare
INVIO_IN_BACHECA=0
#
# Parametro che dice se mandare mail
# 1=inviare, 0=non inviare
INVIO_MAIL=1
#
# Destinatari mail
DESTINATARI_OK=dba@kyneste.com
#DESTINATARI_KO=dba@kyneste.com
DESTINATARI_KO=dba@kyneste.com,esantanche@tim.it

# Prendo in input
# operazione effettuata
#   non ci devono essere spazi
# eventuale ulteriore specificazione dell'operazione (es. nome db per i dump 1shot)
#   non ci devono essere spazi
# esito 0 per ok, >0 per errore     
# inizio ore
# inizio minuti
# fine ore
# fine minuti

# controllo devo avere 7 parametri

Creazione_messaggio () {
   if [ $ESITO -eq 0 ] ; then
      STRESITO="<OK>"
   else
      STRESITO="<CRIT>"
   fi 
   echo "Subject: [$ASEID] $STRESITO ($OPERAZIONE) $SPECIF"
   cat $PATH_MSG | egrep -v -e "Subject:|To:" 
}

if [ $1a = a -o $2a = a -o $3a = a -o $4a = a -o $5a = a -o $6a = a ] ; then
   echo "Usage: $0 seguito dai parametri:"
   echo "   operazione"
   echo "      stringa identificativa dell'operazione effettuata"
   echo "   specificazione"
   echo "      stringa specificativa quale per es il nome del db sul quale"
   echo "      e' stata effettuata l'operazione, oppure ALL per tutti"
   echo "      oppure un generico messaggio. Se ci sono spazi occorre mettere"
   echo "      il messaggio tra virgolette."
   echo "   esito"
   echo "      vale zero per operazione svolta con successo, maggiore di zero"
   echo "      per operazione fallita"
   echo "   ora di inizio"
   echo "      epoch dell'inizio dell'operazione"
   echo "   ora di fine"
   echo "      epoch della fine dell'operazione"
   echo "   path completo messaggio da mandare" 
   exit 0
fi

OPERAZIONE=$1
SPECIF=$2
ESITO=$3
ORA_INIZIO=$4
ORA_FINE=$5
PATH_MSG=$6

DATAORA=`date +%Y.%m.%d-%H:%M:%S`
PATH_LOG=$UTILITY_DIR/logs/mxmain_$ASE_NAME.log

echo "$DATAORA;$OPERAZIONE;$SPECIF;$ESITO;$ORA_INIZIO;$ORA_FINE" >> $PATH_LOG

NOME_FILE=${DATAORA}_${OPERAZIONE}_`echo $SPECIF | awk '{ print $1; }'`

if [ $ESITO -eq 0 ] ; then
   # Bacheca
   if [ $INVIO_IN_BACHECA -eq 1 ] ; then
      PATH_MSG_BACHECA=/inbacheca/$NOME_FILE
      echo OPERAZIONE=$OPERAZIONE > $PATH_MSG_BACHECA
      echo SPECIF=$SPECIF >> $PATH_MSG_BACHECA
      cat $PATH_MSG | egrep -v -e "Subject:|To:" >> $PATH_MSG_BACHECA
   fi
   if [ $INVIO_MAIL -eq 1 ] ; then
      # mail
      Creazione_messaggio | sendmail -f mxmainok@kyneste.com $DESTINATARI_OK
   fi
else
   # Nagiosreps
   PATH_MSG_NAGIOS=/nagios_reps/$NOME_FILE
   echo OPERAZIONE=$OPERAZIONE > $PATH_MSG_NAGIOS
   echo SPECIF=$SPECIF >> $PATH_MSG_NAGIOS
   cat $PATH_MSG | egrep -v -e "Subject:|To:" >> $PATH_MSG_NAGIOS
   if [ $INVIO_MAIL -eq 1 ] ; then
      # mail
      Creazione_messaggio | sendmail -f mxmainko@kyneste.com $DESTINATARI_KO
   fi
fi

exit

