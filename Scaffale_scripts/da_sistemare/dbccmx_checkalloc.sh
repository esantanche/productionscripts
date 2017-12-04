#!/bin/sh

isql -Usa -Pcapdevpwd  -SMX1_DEV_2  <<  EOF > /tmp/dbccmx_checkalloc
dbcc checkalloc (MLC_CAP_TEST)
go
quit
EOF
