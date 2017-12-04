#!/bin/sh
#

isql -Usa -Pcapdevpwd -SMX1_DEV_2 -e << EOF
shutdown SYB_BACKUP
go
shutdown
go
EOF

