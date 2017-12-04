#!/bin/sh 
#

. /home/sybase/.profile

# Script per il reorg delle tabelle
# Vengono cancellate le tabelle utente nel tempdb

# Devo avere come parametro il nome del database su cui fare il reorg
# un parametro '-u' indica che va fatto solo l'update delle statistiche
# Quindi primo parametro nome del database, secondo parametro opzionale, -u 
#NOMEDB=$1

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME

#date; optdiag statistics CAP_MLCPROD -Usa -PSybMxProd -o /tmp/.oggi/opt_CAP_MLCPROD; date
#Empty data page count

NOMEDB=$1
PATH_OPTDIAG_FULL=/tmp/.oggi/optdiag_$NOMEDB
PATH_OPTDIAG_EXTRACT=$UTILITY_DIR/out/optdiag_extract_$NOMEDB
PATH_OPTDIAG_EXTRACT_NAMESONLY=$UTILITY_DIR/out/optdiag_extract_namesonly_$NOMEDB
SOGLIA_PAGINE=100

rm -f $PATH_OPTDIAG_FULL
rm -f $PATH_OPTDIAG_EXTRACT

optdiag statistics $NOMEDB -U$SAUSER -P$SAPWD -S$ASE_NAME -o $PATH_OPTDIAG_FULL 

cat $PATH_OPTDIAG_FULL | nawk -v sp=$SOGLIA_PAGINE 'BEGIN { dpc=-1; }
                    /Table owner/ { split($3,atbo,/\"/); new_tbo=atbo[2]; }
                    /Table name/ { if (dpc > sp && drc > 0) {
                                      p_edpc=(edpc*100/dpc);
                                      p_frc=(frc*100/drc);
                                      p_delrc=(delrc*100/drc);
                                      if ((p_edpc+p_frc+p_delrc) > 0.5) 
                                         printf "%8d (%6d MB) %8d %-40s  %5.1f%%  %5.1f%%  %5.1f%%\n",dpc,(dpc/256),drc,(old_tbo "." tbn),p_edpc,p_frc,p_delrc; 
                                   }
                                   split($3,atbn,/\"/); tbn=atbn[2];
                                   old_tbo=new_tbo; }
                    /Empty data page count/ { edpc=$5;  }
                    /Forwarded row count/ { frc=$4; }
                    /Deleted row count/ { delrc=$4; }
                    /Data row count/ { drc=$4; }
                    /Data page count/ { dpc=$4; }' | sort -n > $PATH_OPTDIAG_EXTRACT

NUM_TABELLE_SIGNIFICATIVE=`cat $PATH_OPTDIAG_EXTRACT | wc -l`

cat $PATH_OPTDIAG_EXTRACT | cut -c 30- | awk '{ print $1; }' > $PATH_OPTDIAG_EXTRACT_NAMESONLY

if [ $NUM_TABELLE_SIGNIFICATIVE -eq 0 ] ; then
   echo Non ci sono tabelle che necessitano di riorganizzazione >> $PATH_OPTDIAG_EXTRACT
else

   cat <<EOF >> $PATH_OPTDIAG_EXTRACT
Colonna 1 Numero pagine (tra parentesi la dimensione in MB)
Colonna 2 Numero righe
Colonna 3 Nome tabella
Colonna 4 Percentuale pagine vuote
Colonna 5 Percentuale forwarded rows
Colonna 6 Percentuale righe cancellate
La tabella necessita di reorg se una delle tre percentuali e' maggiore di zero  
Sono riportate quindi solo tali tabelle
EOF

fi

#echo NUMERO TABELLE SIGNIFICATIVE $NUM_TABELLE_SIGNIFICATIVE >> $PATH_OPTDIAG_EXTRACT

(echo "Subject: Report frammentazione db "$NOMEDB ; echo "========="; cat $PATH_OPTDIAG_EXTRACT) | sendmail -f optdiag@kyneste.com dba@kyneste.com

exit

