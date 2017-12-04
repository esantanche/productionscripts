#!/bin/sh 
#

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

if [ $(lsvg -o | grep $SYBASE_VG_NAME | wc -l) -eq 0 ]
then
        exit 0;
fi


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


if [ $1a = a -o $2a = a -o $3a = a -o $4a = a -o $5a = a -o $6a = a -o $7a = a ] ; then
   echo "Usage: centro_log_operazioni.sh seguito dai parametri:"
   echo "   operazione"
   echo "      stringa identificativa dell'operazione effettuata"
   echo "   specificazione"
   echo "      stringa specificativa quale per es il nome del db sul quale"
   echo "      e' stata effettuata l'operazione, oppure ALL per tutti"
   echo "   esito"
   echo "      vale zero per operazione svolta con successo, maggiore di zero"
   echo "      per operazione fallita"
   echo "   ora di inizio dell'operazione"
   echo "   minuti di inizio dell'operazione"
   echo "   ora di fine dell'operazione"
   echo "   minuti di fine dell'operazione" 
   exit 0
fi

if [ $3 -gt 0 ] ; then
   echo $1 $2 $3 $4 $5 $6 $7 $(date +%Y%m%d%H%M) | nawk '  
                                    { inizio_ore=$4;
                                      inizio_min=$5;
                                      fine_ore=$6;
                                      fine_min=$7;
                                      diff=((fine_ore * 60) + fine_min) - ((inizio_ore * 60) + inizio_min);
                                      if (diff < 0) { diff += 1440; };
                                      printf "%-12s %-10s %-40s %02d:%02d %02d:%02d %4d FAIL %3d\n",
                                              $8, $1, $2, inizio_ore, inizio_min, 
                                              fine_ore, fine_min, diff, $3; 
                                    }' >> $UTILITY_DIR/out/log_centralizzato_operazioni_fallite
   echo $1 $2 $3 $4 $5 $6 $7 $(date +%Y%m%d%H%M) > /nagios_reps/Operazione_fallita_$(date +%Y.%m.%d-%H:%M)
else
   echo $1 $2 $3 $4 $5 $6 $7 $(date +%Y%m%d%H%M) | nawk '
                                    { inizio_ore=$4;
                                      inizio_min=$5;
                                      fine_ore=$6;
                                      fine_min=$7;
                                      diff=((fine_ore * 60) + fine_min) - ((inizio_ore * 60) + inizio_min);
                                      if (diff < 0) { diff += 1440; };
                                      printf "%-12s %-10s %-40s %02d:%02d %02d:%02d %4d OK\n",
                                              $8, $1, $2, inizio_ore, inizio_min,
                                              fine_ore, fine_min, diff;
                                    }' >> $UTILITY_DIR/out/log_centralizzato_operazioni_riuscite
   echo $1 $2 $(date +%Y.%m.%d-%H:%M) > /inbacheca/Operazione_riuscita_$1_$2_$(date +%Y.%m.%d-%H:%M)
fi

exit 0

