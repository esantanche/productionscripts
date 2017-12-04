#!/bin/sh 
#
#DATA=$(/usr/bin/date +%Y%m%d)

. /sis/SIS-AUX-Envsetting.Sybase.sh
# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME

/usr/bin/su - sybase -c isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 >$UTILITY_DIR/out/lista_dei_db <<EOF
set nocount on
go
select name from sysdatabases order by name
go
quit
EOF

tail -n +3 $UTILITY_DIR/out/lista_dei_db | awk 'BEGIN { print "set nocount on"; print "go";}{ print "print \"",$1,"\""; print "go"; print "select segment,free_space,status,right(proc_name,20) as proced from ",$1,"..systhresholds" ; print "go" }' - >/tmp/thrlistscript
/usr/bin/su - sybase -c isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400 -i /tmp/thrlistscript >$UTILITY_DIR/out/thrlist

rm /tmp/thrlistscript
