#!/bin/sh 
#

# Questo script salva un elenco dei processi in corso sul server ASE
# Viene utilizzato per vedere quali processi ci sono attivi prima di 
# dello shutdown del server ASE
# E.Santanche 27 ottobre 2004

. /sis/SIS-AUX-Envsetting.Sybase.sh

# Parametri ritornati da SIS-AUX-Envsetting.Sybase.sh
# UTILITY_DIR
# SAUSER
# SAPWD
# NOTSAUSER
# NOTSAPWD
# ASE_NAME

# Un controllo che esistano i volume group sybase. Non fa mai male
if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then 
        exit 0;
fi

sleep 180

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w1000 << EOF > $UTILITY_DIR/out/lista_processi_prima_dello_shutdown
sp_who
go
select * from sysprocesses
go
quit
EOF


