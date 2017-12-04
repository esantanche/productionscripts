#!/bin/sh 
#

if [ $1a = a  ] ; then
   echo "Usage: dare come parametro il nome del db da rendere completamente misto dati/log"
   exit 0
fi

# Parametri da passare: nome del db 
NOMEDB=$1

if [ $USER != sybase ] ; then
   echo Eseguire come sybase
   exit 0
fi

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

#export UTILITY_DIR=/sybase/utility
#export SAUSER=sa
#export SAPWD=capdevpwd
#export NOTSAUSER=test
#export NOTSAPWD=test
#export ASE_NAME=MX1_DEV_2
#export HOME_OF_SYBASE=/home/sybase
#export PATH_ERRORLOG_ASESERVER=/sybase/ASE-12_5/install/MX1_DEV_2.log 
#export PATH_ERRORLOG_BACKUPSERVER=/sybase/ASE-12_5/install/MX1_DEV_2_back.log
#export SOGLIA_FS_DUMP_MB=1000
#export SOGLIA_FS_DB_MB=3000
#export PATH_INSTALLDIR=/sybase/ASE-12_5/install
#export PATH_SCRIPT_TSM=/usr/bin/backup_tsm*.sh
#export SOGLIA_FS_DUMP_MB=1000
#export SOGLIA_FS_DB_MB=3000
#export PATH_INSTALLDIR=/sybase/ASE-12_5/install
#export SUNDAYDIR=/sybased2/sunday_dir
#export PATH_DUMP_DIR=/sybased1/dump
#export PATH_DUMP_FS=/sybased1
#export SYBASE_VG_NAME=sybasevg

if [ $(lsvg -o | grep $SYBASE_VG_NAME | wc -l) -eq 0 ]
then 
        exit 0;
fi

DBESISTENTE=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF  | awk '/DBESISTENTE/ { print $2; }'
select "DBESISTENTE",count(*) from sysdatabases where name="$NOMEDB"
go
exit
EOF`

if [ $DBESISTENTE -eq 0 ] ; then
   echo "Il db " $NOMEDB " non esiste."
   exit 0
fi

UTENTISUDB=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF  | awk '/UTENTISUDB/ { print $2; }'
select "UTENTISUDB",count(*) from sysprocesses p, sysdatabases d where d.name="$NOMEDB"
       and p.dbid=d.dbid
go
exit
EOF`

if [ $UTENTISUDB -gt 0 ] ; then
   echo "Il database "$NOMEDB" e' in uso, impossibile eseguire il fix delle segmap"
   echo "Al database sono collegati "$UTENTISUDB" utenti"
   exit 0
fi


DB_IN_SINGLE_USER_MODE=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF | grep "single user" | wc -l
sp_helpdb $NOMEDB
go
quit
EOF`

echo Fix Segmap misto output db $NOMEDB > /tmp/fixsegmap_output

echo Db in single user mode $DB_IN_SINGLE_USER_MODE >> /tmp/fixsegmap_output

if [ $DB_IN_SINGLE_USER_MODE -eq 0 ] ; then

   isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF >> /tmp/fixsegmap_output
set nocount on
go
select 'db in single user mode'
go
sp_dboption $NOMEDB, single, true
go
use $NOMEDB
go
checkpoint
go
quit
EOF

fi

isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF >> /tmp/fixsegmap_output
set nocount on
go
select 'segmap a 7 per tutti i device'
go
update sysusages set u.segmap = u.segmap | 7 from sysusages u, sysdatabases d where d.name='$NOMEDB' and u.dbid=d.dbid     
go
select 'dbrepair findstranded'
go
DBCC TRACEON (3604)
go
dbcc dbrepair ('$NOMEDB', findstranded)
go
select 'dbrepair remap'
go
DBCC TRACEON (3604)
go
dbcc dbrepair ('$NOMEDB', remap)
go
select 'calcolo del lastchance che dovrebbe valere il 3 per cento del device log'
go
select 'last chance threshold in pagine',lct_admin("lastchance", db_id('$NOMEDB'))
go
use $NOMEDB
go
select 'checkpoint del db'
go
checkpoint
go
use master
go
select 'mappa segmap'
go
select d.name , u.segmap 
   from master.dbo.sysusages u, master.dbo.sysdevices d
   where u.vstart between d.low and d.high
         and u.dbid = db_id('$NOMEDB') 
         and (d.status & 2) = 2
   order by u.vstart
go
quit
EOF

if [ $DB_IN_SINGLE_USER_MODE -eq 0 ] ; then

   isql -U$SAUSER -P$SAPWD -S$ASE_NAME  <<  EOF >> /tmp/fixsegmap_output
set nocount on
go
select 'db in multi user mode'
go
sp_dboption $NOMEDB, single, false
go
use $NOMEDB
go
checkpoint
go
quit
EOF

fi

echo Db $NOMEDB == begin ======================
cat /tmp/fixsegmap_output | grep -v "DBCC execution completed" | grep -v "System Administrator"
echo Db $NOMEDB == end ========================

exit 0;


