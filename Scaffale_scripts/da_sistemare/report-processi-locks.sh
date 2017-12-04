#!/bin/sh -x
#


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

# proclock.sh   
# select \"NUMEROCONNESSIONI\",count(*) from sysprocesses where suid != 0

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 >/tmp/proclock.nconn <<EOF
set nocount on
go
sp_lock
go
select l.class,l.type,o.name from syslocks l, MLC_CAP_SVIL..sysobjects o where l.dbid=7 and l.id=o.id
go
select * from sysprocesses where dbid=7
go
quit
EOF

DATA=$(/usr/bin/date +%Y%m%d-%H%M)

echo $DATA >> $UTILITY_DIR/out/report-proc-lock
cat /tmp/proclock.nconn >> $UTILITY_DIR/out/report-proc-lock

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 >/tmp/proclock2.nconn <<EOF
set nocount on
go
select l.spid,l.class,l.type,o.name,l.context from syslocks l, MLC_CAP_SVIL..sysobjects o where l.dbid=7 and l.id=o.id
go
select spid,status,suid,program_name,cmd,cpu,blocked from sysprocesses where dbid=7
go
quit
EOF

echo $DATA >> $UTILITY_DIR/out/report-proc-lock-short
cat /tmp/proclock2.nconn >> $UTILITY_DIR/out/report-proc-lock-short


exit

