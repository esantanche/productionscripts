#!/bin/sh -x
#

SOGLIA_CONNESSIONI=$1

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

# connections-report.sh   

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 >/tmp/connections-report.nconn <<EOF
set nocount on
go
select \"NUMEROCONNESSIONI\",count(*) from sysprocesses where suid != 0       
go
quit
EOF

if [ `grep NUMEROCONNESSIONI /tmp/connections-report.nconn | wc -l` -eq 0 ] ; then
   echo connections-report.sh
   echo Server Sybase non attivo per riavvio domenicale oppure perche"'"
   echo si e"'" raggiunto il numero massimo di connessioni e questo script non
   echo riesce a loggarsi
   exit
fi

NUMCONNESSIONI=`grep NUMEROCONNESSIONI /tmp/connections-report.nconn | awk '{ print $2; }'`

#echo $NUMCONNESSIONI

if [ $NUMCONNESSIONI -gt $SOGLIA_CONNESSIONI ] ; then

   isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 >/tmp/connections-report.connxdb <<EOF
set nocount on
go
select \"CONNPERDB\",dbid,count(*) from sysprocesses where suid > 0 group by dbid order by dbid
go
sp_who
go
quit
EOF

   DATA=$(/usr/bin/date +%Y%m%d-%H%M)
   cat /tmp/connections-report.connxdb | grep CONNPERDB | awk -v dataora=$DATA -v totale=$NUMCONNESSIONI '{ np[$2]=$3; }  
                                                        END { printf "%13s %3d - %3d%3d%3d%3d%3d%3d%3d%3d%3d%3d\n",dataora,totale,
                                                                np[1],np[4],np[5],np[6],np[7],
                                                                np[8],np[9],np[10],np[11],np[12] ; } ' >> $UTILITY_DIR/out/connections-report

   cp /tmp/connections-report.connxdb $UTILITY_DIR/out/connections-report-detail.$DATA
   #cat $UTILITY_DIR/out/connections-report

   echo Raggiunta soglia di warning numero connessioni aperte > /nagios_reps/Superato_warning_connessioni.$DATA
   echo Mandare proattivo al cliente >> /nagios_reps/Superato_warning_connessioni.$DATA

fi

exit

