#!/bin/sh 
#
# Questo script salva le tabelle di sistema
# i cui nomi sono indicati nel file sysbcp-tables
# e le mette nella directory /sybase/utility/out
# Viene lanciato da crontab di sybase

. /home/sybase/.profile

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

if [ $(lsvg -o | grep $SYBASE_VG_NAME | wc -l) -eq 0 ]
then
        exit 0;
fi

#DATA=$(/usr/bin/date +%Y%m%d)
DATAORA=$(/usr/bin/date +%Y.%m.%d-%H:%M)

PATHOUT=$UTILITY_DIR/data

rm -f $PATHOUT/lista_sysbcp

ERRORI_PRESENTI=0
for tabella in `cat $UTILITY_DIR/sysbcp-tables`
do
   #echo $tabella
   bcp master..$tabella out $PATHOUT/$ASE_NAME-$tabella.bcp -c -P $SAPWD -S $ASE_NAME -U $SAUSER >/dev/null
   ERROREBCP=$?
   if [ $ERROREBCP -gt 0 ] ; then
      ERRORI_PRESENTI=1
   fi
   echo $PATHOUT/$ASE_NAME-$tabella.bcp >> $PATHOUT/lista_sysbcp
done

if [ $ERRORI_PRESENTI -eq 1 ] ; then
   echo Errore nel salvataggio delle tabelle di sistema
   echo Errore nel salvataggio delle tabelle di sistema > /nagios_reps/Errore_sysbcp_$DATAORA
   exit 1
fi

if [ `find $PATHOUT -name "sysbcp*tar*" | wc -l` -gt 30 ] ; then
   rm -f `ls -1t $PATHOUT/sysbcp*tar* | tail -1`
fi

if [ `find $PATHOUT -name "sysbcp*tar*" | wc -l` -gt 30 ] ; then
   rm -f `ls -1t $PATHOUT/sysbcp*tar* | tail -1`
fi

tar -cvf $PATHOUT/sysbcp.$DATAORA.tar -L $PATHOUT/lista_sysbcp $PATHOUT/lista_sysbcp >/dev/null
gzip -9 $PATHOUT/sysbcp.*.tar

exit 0
