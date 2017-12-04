#!/bin/sh 
#

#echo script incompleto da sviluppare

. /home/sybase/.profile

# Script per il reorg delle tabelle
# Vengono cancellate le tabelle utente nel tempdb

# Devo avere come parametro il nome del database su cui fare il reorg
# un parametro '-u' indica che va fatto solo l'update delle statistiche
# Quindi primo parametro nome del database, secondo parametro opzionale, -u 
NOMEDB=$1
SOLO_UPDATE=0

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

NOMEDB=$1
PATH_OPTDIAG_FULL=/tmp/.oggi/tbl_sel_full_$NOMEDB
PATH_OPTDIAG_EXTRACT=/tmp/.oggi/tbl_sel_extract_$NOMEDB
#PATH_OPTDIAG_EXTRACT_NAMESONLY=/tmp/.oggi/tbl_sel_extract_namesonly_$NOMEDB
SOGLIA_PAGINE_MIN=100
SOGLIA_PAGINE_MAX=1000000
#SOGLIA_PAGINE_MAX=100000000
#SOGLIA_PAGINE_MAX=10000

rm -f $PATH_OPTDIAG_FULL
rm -f $PATH_OPTDIAG_EXTRACT

optdiag statistics $NOMEDB -U$SAUSER -P$SAPWD -S$ASE_NAME -o $PATH_OPTDIAG_FULL

cat $PATH_OPTDIAG_FULL | nawk -v spmin=$SOGLIA_PAGINE_MIN -v spmax=$SOGLIA_PAGINE_MAX 'BEGIN { dpc=-1; }
                    /Table owner/ { split($3,atbo,/\"/); new_tbo=atbo[2]; }
                    /Table name/ { if (dpc > spmin && drc > 0 && dpc < spmax) {
                                      p_edpc=(edpc*100/dpc);
                                      p_frc=(frc*100/drc);
                                      p_delrc=(delrc*100/drc);
                                      if ((p_edpc+p_frc+p_delrc) > 1.0)
                                         printf "%-40s %8d (%6d MB)  %5.1f%%  %5.1f%%  %5.1f%%\n",(old_tbo "." tbn),dpc,(dpc/256),p_edpc,p_frc,p_delrc;
                                   }
                                   split($3,atbn,/\"/); tbn=atbn[2];
                                   old_tbo=new_tbo; }
                    /Empty data page count/ { edpc=$5;  }
                    /Forwarded row count/ { frc=$4; }
                    /Deleted row count/ { delrc=$4; }
                    /Data row count/ { drc=$4; }
                    /Data page count/ { dpc=$4; }' | sort -n -k 2 > $PATH_OPTDIAG_EXTRACT

#cat $PATH_OPTDIAG_EXTRACT

NUM_TABELLE_SIGNIFICATIVE=`cat $PATH_OPTDIAG_EXTRACT | wc -l`

if [ $NUM_TABELLE_SIGNIFICATIVE -eq 0 ] ; then
   #echo Non ci sono tabelle che necessitano di riorganizzazione >> $PATH_OPTDIAG_EXTRA
   exit
fi

# Creo il file con le istruzioni da eseguire

QRY=/tmp/.oggi/reorgmx-selezionate
echo use $NOMEDB > $QRY
echo go >> $QRY

if [ $SOLO_UPDATE -eq 1 ] ; then
   for i in `cat $PATH_OPTDIAG_EXTRACT | awk '{ print $1; }'`
   do
      echo update statistics $i >> $QRY
      echo if @@error != 0 select "'"erroret5"'" >> $QRY
      echo go >> $QRY
   done
else
   for i in `cat $PATH_OPTDIAG_EXTRACT | awk '{ print $1; }'`
   do
      echo reorg rebuild $i >> $QRY
      #echo select @@error >> $QRY
      echo if @@error != 0 and @@error != 11903 select "'"erroret5"'" >> $QRY
      echo go >> $QRY
      echo sp_recompile \'$i\' >> $QRY
      echo if @@error != 0 select "'"erroret5"'" >> $QRY
      echo go >> $QRY
      echo update statistics $i >> $QRY
      echo if @@error != 0 select "'"erroret5"'" >> $QRY
      echo go >> $QRY
   done
fi

echo quit >> $QRY

   cat <<EOF >> $PATH_OPTDIAG_EXTRACT
Colonna 1 Nome tabella
Colonna 2 Numero pagine (tra parentesi la dimensione in MB)
Colonna 3 Percentuale pagine vuote
Colonna 4 Percentuale forwarded rows
Colonna 5 Percentuale righe cancellate
Le tabelle qui elencate sono state riorganizzate salvo fallimento
delle operazioni di reorg
EOF

(echo "Subject: Minireorg db "$NOMEDB ; echo "========="; cat $PATH_OPTDIAG_EXTRACT) | sendmail -f minireorg@kyneste.com dba@kyneste.com

PATH_OUT=/tmp/.oggi/reorgmx-selezionate-output-$NOMEDB
echo Inizio `date` > $PATH_OUT 
echo ASE_NAME=$ASE_NAME >> $PATH_OUT
echo NOMEDB=$NOMEDB >> $PATH_OUT

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -i $QRY >> $PATH_OUT   

# Vedo se ho errori

if [ `grep "erroret5" $PATH_OUT | wc -l` -gt 0 ] ; then
   echo Errore nel reorg o nel update statistics nel db $NOMEDB >> $PATH_OUT        
fi

echo Fine `date` >> $PATH_OUT    

#echo DOVREI CHIAMARE centro_unif_messaggi ma non lo chiamo tanto non importa se fa questo reorg

exit 0

