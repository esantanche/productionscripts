#!/bin/sh

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

if [ $1a = a ] ; then
   echo "Usage: dare come parametro il nome del db"
   exit 0
fi

nomedb=$1

echo "Per il database "$nomedb

SEGMAP=3

isql -Utest -Ptestpwd -S$ASE_NAME -w400 << EOF | grep "LIBERO_MB" | awk '{ printf "Liberi parte dati %6.0f MB\n",$2; }'
begin
declare @id_del_db smallint
declare @Spazio_libero_Mb dec
set nocount on
select @id_del_db = dbid from sysdatabases where name like \"$nomedb\"
select @Spazio_libero_Mb = sum((curunreservedpgs(@id_del_db, lstart, unreservedpgs)/256)) from sysusages where dbid=@id_del_db and segmap & $SEGMAP = $SEGMAP
select \"LIBERO_MB\",@Spazio_libero_Mb
end
go
quit
EOF

SEGMAP=4

isql -Utest -Ptestpwd -S$ASE_NAME -w400 << EOF | grep "LIBERO_MB" | awk '{ printf "Liberi parte log  %6.0f MB\n",$2; }'
begin
declare @id_del_db smallint
declare @Spazio_libero_Mb dec
set nocount on
select @id_del_db = dbid from sysdatabases where name like \"$nomedb\"
select @Spazio_libero_Mb = sum((curunreservedpgs(@id_del_db, lstart, unreservedpgs)/256)) from sysusages where dbid=@id_del_db and segmap & $SEGMAP = $SEGMAP
select \"LIBERO_MB\",@Spazio_libero_Mb
end
go
quit
EOF

