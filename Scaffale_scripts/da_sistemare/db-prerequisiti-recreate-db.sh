#!/bin/sh -x
#

. /home/sybase/.profile

DATA=$(/usr/bin/date +%Y%m%d)

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

# Il parametro su linea comando e' il nome del db
NOMEDB=$1
#$UTILITY_DIR/out/lista_dei_db 

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 >/tmp/db-prerequisiti-recreate-db-$NOMEDB <<EOF
set nocount on
go
print "  "
go
print "DATABASE DA RICREARE: $NOMEDB"
go
print "  "
go
print "sp_helpdb del database"
go
print "================================------------------------------------------"
go
sp_helpdb $NOMEDB
go
print "  "
go
print "login con db di def il db in esame"
go
print "================================------------------------------------------"
go
select name,dbname from syslogins where dbname like '$NOMEDB'
go
print "  "
go
print "riga di sysdatabases"
go
print "================================------------------------------------------"
go
select * from sysdatabases where name like '$NOMEDB'
go
print "  "
go
print "sp_spaceused"
go
print "================================------------------------------------------"
go
use $NOMEDB
go
sp_spaceused
go
print "  "
go
print "refs & cols"
go
print "================================------------------------------------------"
go
create table #lista_db
      (
         dbid   smallint null,
         dbname varchar(30) null
      )
go
insert into #lista_db (dbid, dbname) select dbid, name from master.dbo.sysdatabases
go
create table #lista_db_results
      (
         dbname varchar(30) null,
         refs   int         null,
         cols   int         null
      )
go
declare @cur_db_name varchar(30)
declare @refs int
declare @cols int
while (select count(*) from #lista_db) > 0 
begin
    select @cur_db_name = min(dbname) from #lista_db
    use @cur_db_name
    checkpoint
    select @refs=count(*) from sysreferences where frgndbname is not null or pmrydbname is not null
    select @cols=count(*) from syscolumns where xdbid is not null
    insert into #lista_db_results (dbname, refs, cols) values (@cur_db_name,@refs,@cols)
    delete from #lista_db where dbname = @cur_db_name
end
go
select * from #lista_db_results
go
quit
EOF

echo " " >> /tmp/db-prerequisiti-recreate-db-$NOMEDB
echo Check list per ricostruzione >> /tmp/db-prerequisiti-recreate-db-$NOMEDB
echo "- impostare le dboptions" >> /tmp/db-prerequisiti-recreate-db-$NOMEDB

cp /tmp/db-prerequisiti-recreate-db-$NOMEDB $UTILITY_DIR/out/db-prerequisiti-recreate-db-$NOMEDB

cat $UTILITY_DIR/out/db-prerequisiti-recreate-db-$NOMEDB

rm /tmp/db-prerequisiti-recreate-db-$NOMEDB
