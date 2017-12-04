#!/usr/bin/ksh
# ---------------------------------------------------------------------------------------------------
# SKELETON: Script che rimuove sul tempdb le tabelle relative a sessioni terminate ma non cancellate
#----------------------------------------------------------------------------------------------------

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

#. /opt/sybase/oc12.0-EBF10732/.profile

#export SYBASE=${SYBASE:-/opt/sybase/oc12.0-EBF10732}
#export LIBPATH=LIBPATH=$SYBASE/OCS-12_0/lib:$LIBPATH
#export PATH=/opt/sybase/oc12.0-EBF10732/OCS-12_0/bin:/opt/sybase/oc12.0-EBF10732/OCS-12_0/lib/:$PATH
#export ISQL=$SYBASE/OCS-12_0/bin/isql
export OUT_FIL=/tmp/drop_old_tables.out
export IN_FIL=/tmp/drop_old_tables.in

# --------------------------------------------------------------------------------------------------
# --- Configurare SERVER_NAME e USER_PASSWD a secondo dell'instanza Sybase  in cui si opera
# --------------------------------------------------------------------------------------------------
#export SERVER_NAME="MX_PROD_DB"
export SERVER_NAME=$ASE_NAME
#export USER_NAME="sa"
export USER_NAME=$SAUSER
#export USER_PASSWD="SybMxProd"
export USER_PASSWD=$SAPWD

# --------------------------------------------------------------------------------------------------
# ----  Definisce l'arco di tempo in termini di giorni a partire dalla data odierna per i quali si
# ----  vuole cancellare le tabelle sul tempdb (0=oggi, 1=Ieri, 2=ieri l'altro, ....)
# --------------------------------------------------------------------------------------------------
export NB_DAYS=0    

# --------------------------------------------------------------------------------------------------
# Radice HostName che compone i primi 10 caratteri del nome tabella
# --------------------------------------------------------------------------------------------------
#export HST=`hostname | cut -c1-10| sed "s/-/_/g"`
export HST=`hostname | cut -c1-9| sed "s/-/_/g"`

echo HST=$HST

#echo "This script deletes all tables from tempdb in your Sybase Server,  older than a specified number of days"

#echo "Script ad uso del gruppo dba"
#echo "Script versione 2 pulizia tempdb su host" `hostname`

# ----------------------------------------
# -- Determina tutte le tabelle sul tempdb
# ----------------------------------------

echo "" > $OUT_FIL
echo "" > $IN_FIL
echo "use tempdb">$IN_FIL
echo "go">>$IN_FIL
echo "set nocount on">>$IN_FIL
echo "go">>$IN_FIL
echo "select name from sysobjects where type=\"U\" and crdate < dateadd(dd,-$NB_DAYS,getdate()) ">>$IN_FIL
echo "and name like \"${HST}%\" order by name" >>$IN_FIL
echo "go">>$IN_FIL
#echo $ISQL
echo Determino tabelle su tempdb 
isql -U$SAUSER -P$SAPWD -S$SERVER_NAME -w400 -i $IN_FIL -o $OUT_FIL  

cat $OUT_FIL

#------------------------------------------------------------------------------
# Crea il file di input da passare all'isql, scrivendovi le tabelle
# per le quali il PID del processo associato alla stessa non sia piu' attivo
# che devono essere cancellate
#------------------------------------------------------------------------------

echo "" > $IN_FIL
NUMTABELLE=0
for i in `cat $OUT_FIL| grep "#"`
do
	 PID=`echo $i|awk -F"#" '{printf $1 "\n" }'| sed "s/${HST}//g"`
	 rrc=`UNIX95=1 ps -eo pid| grep $PID | grep -v grep | wc -l`
	 if [[ "${rrc}" -eq "0" ]]
	 then
        	echo "drop table tempdb.guest.$i"  >> $IN_FIL
        	echo "go"  >> $IN_FIL
                NUMTABELLE=`expr $NUMTABELLE + 1`
                echo tabella $i pid $PID processo inattivo
         else
                echo tabella $i pid $PID processo attivo
	 fi

done

# --------------------------------------------
# Cancellazione fisica   tabelle sul tempdb
# --------------------------------------------
##  Scommentare lo statement ##<!!> per lanciare la cancellazione
cat $IN_FIL 
echo $NUMTABELLE tabelle da cancellare
#isql -U$USER_NAME -P$USER_PASSWD -S$SERVER_NAME -Dtempdb -i $IN_FIL -w400 1>/tmp/drop_old_tables.dropout 2>/tmp/drop_old_tables.droperr
#echo "Errori trovati nell'esecuzione:"
#echo ==========================================================
#cat /tmp/drop_old_tables.dropout
#cat /tmp/drop_old_tables.droperr
#echo prova >> /tmp/drop_old_tables.droperr
if [ -s /tmp/drop_old_tables.droperr -o -s /tmp/drop_old_tables.dropout ] ; then
   echo Subject: ERRORI nel drop delle tabelle su tempdb `hostname` > /tmp/drop_old_tables.mail
   echo Errori o output nel drop delle tabelle >> /tmp/drop_old_tables.mail
   echo Script drop_tabelle_murex.sh >> /tmp/drop_old_tables.mail
   echo Hostname `hostname` >> /tmp/drop_old_tables.mail
   cat /tmp/drop_old_tables.dropout >> /tmp/drop_old_tables.mail
   cat /tmp/drop_old_tables.droperr >> /tmp/drop_old_tables.mail
   sendmail -f droptempdberr@kyneste.com dba@kyneste.com < /tmp/drop_old_tables.mail 
else
   echo Subject: Pulizia tempdb prod da `hostname` - drop di $NUMTABELLE tabelle riuscito > /tmp/drop_old_tables.mail
   echo Cancellate $NUMTABELLE tabelle per la pulizia del tempdb >> /tmp/drop_old_tables.mail
   sendmail -f droptempdbok@kyneste.com dba@kyneste.com < /tmp/drop_old_tables.mail 
fi
#rm $IN_FIL
#rm $OUT_FIL

exit 

