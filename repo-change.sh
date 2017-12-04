#!/bin/sh 
#

. /sis/SIS-AUX-Envsetting.Sybase.sh

Lista()
{

   perl $UTILITY_DIR/lista_dir.pl $1 
   #find $1/* -prune -mtime -150 -ls ! -type d

}

NEW=$UTILITY_DIR/out/repo-change.new
ACT=$UTILITY_DIR/out/repo-change
OLD=$UTILITY_DIR/out/repo-change.old
DIFF=$UTILITY_DIR/out/repo-change.diff

#echo $(/usr/bin/date +%Y%m%d-%H:%M)A 

echo $ASE_NAME `hostname` > $NEW
echo ======================  >> $NEW

echo Configurazione del server ASE >> $NEW
echo ======================  >> $NEW
cat $PATH_FILE_CFG >> $NEW

echo File interfaces >> $NEW
echo ======================  >> $NEW
cat $PATH_INTERFACES >> $NEW

echo Script di backup TSM >> $NEW
echo ======================  >> $NEW
cat $PATH_SCRIPT_TSM >> $NEW

# Script cluster   
if [ a$PATH_SCRIPT_CLUSTER != a ] ; then
   echo Script cluster >> $NEW
   echo ======================  >> $NEW
   Lista $PATH_SCRIPT_CLUSTER >> $NEW
fi

# crontab di sybase e di root
echo Crontab >> $NEW
echo ======================  >> $NEW
crontab -l >> $NEW
su - sybase -c "crontab -l" >> $NEW

echo Script di /sybase/utility >> $NEW
echo ======================  >> $NEW
Lista $UTILITY_DIR | egrep -v " out|thrlog|sysmondir|lock-sleep-finder-parameters|^total|tar.gz" >> $NEW

echo Dir sis >> $NEW
echo ======================  >> $NEW
Lista /sis | egrep -v "\.log|\.parms|\.pid" >> $NEW

echo Dir installazione script di run >> $NEW
echo ======================  >> $NEW
Lista $PATH_INSTALLDIR | grep -v log >> $NEW

echo Profile di sybase >> $NEW
echo ======================  >> $NEW
cat /home/sybase/.profile >> $NEW

if [ -s $ACT ] ; then
   diff $ACT $NEW > $DIFF
else
   cp $NEW $ACT
   exit 0
fi

if [ -s $DIFF ] ; then
   cp $ACT $OLD
   cp $NEW $ACT
   # Invio messaggio
   echo "Subject: [CHANGEMX] Cambiamenti file configurazione "`hostname`  >  /tmp/repo-change
   echo "To: dba@kyneste.com"  >> /tmp/repo-change
   echo "Questi cambiamenti di configurazione della macchina" >> /tmp/repo-change
   echo "vanno esaminati per vedere se vanno riportati su altre macchine." >> /tmp/repo-change
   echo "Per es. i cambiamenti su pridb vanno anche su secdb." >> /tmp/repo-change
   cat $DIFF >> /tmp/repo-change
   sh $UTILITY_DIR/centro_unificato_messaggi.sh CHANGE REPORT 0 0 0 /tmp/repo-change

   cp $DIFF $UTILITY_DIR/Dati/Change_history/repo-change-diff-$(date +%Y%m%d)   

   chown sybase:dba $UTILITY_DIR/Dati/Change_history/repo-change-diff-*

   rm -f /tmp/repo-change
fi

exit

