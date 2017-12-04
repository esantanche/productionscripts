#!/bin/sh

# Questo script amplia un database
# serve il nome del db e quello del device

. /home/sybase/.profile

. /sis/SIS-AUX-Envsetting.Sybase.sh

rm -f /tmp/db-ampliamento-dati-*

# Un controllo che esistano i volume group sybase. Non fa mai male
if [ $(lsvg -o | grep sybase | wc -l) -eq 0 ]
then
        exit 0;
fi

if [ $1a = a -o $2a = a -o $3a = a ] ; then
   echo "Usage: dare come parametri il nome del db da ampliare, il nome del device e la size di ampliamento in MB"
   exit 0
fi

NOMEDB=$1
NOMEDEVICE=$2
SIZE=$3

if [ $4a = crontaba ] ; then
   CRONTAB=1
else 
   CRONTAB=0 
fi

# Verifico che il db esista
DBESISTENTE=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF  | awk '/DBESISTENTE/ { print $2; }'
select "DBESISTENTE",count(*) from sysdatabases where name="$NOMEDB"
go
exit
EOF`

#echo $DBESISTENTE

if [ $DBESISTENTE -eq 0 ] ; then
   echo "Il db " $NOMEDB " non esiste."
   exit 0
fi

# Verifico che il device esista
DEVICEESISTENTE=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF  | awk '/DEVICEESISTENTE/ { print $2; }'
select "DEVICEESISTENTE",count(*) from sysdevices where name="$NOMEDEVICE"
go
exit
EOF`

if [ $DEVICEESISTENTE -eq 0 ] ; then
   echo "Il device " $DEVICEESISTENTE " non esiste."
   exit 0
fi

PATH_FISICO_DEVICE=`isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF  | awk '/DEVICEESISTENTE/ { print $2; }'
select "DEVICEESISTENTE",phyname from sysdevices where name="$NOMEDEVICE"
go
exit
EOF`

if [ $CRONTAB -eq 0 ] ; then

   clear
   echo " "
   echo "Questo script ampliera' il db " $NOMEDB " di " $SIZE " MB "
   echo "Verra' ampliato con una disk resize il device "$NOMEDEVICE
   echo "il cui path e' "$PATH_FISICO_DEVICE
   echo " "
   echo "ATTENZIONE!!! USARE SOLO PER AMPLIARE DEVICE DATI !!!!"
   echo "PER I DEVICE LOG NON FUNZIONA"
   echo " "
   echo "Controllare bene in particolare la size dell'ampliamento poi"
   echo "dare S poi invio per avviare l'operazione o N e invio per non proseguire"
   read risposta
   if [ $risposta != "S" ] ; then
      exit 0;
   fi
   echo " "
   echo " "

fi

echo "============================================================="
echo "DB - $NOMEDB  DEVICE - $NOMEDEVICE  SIZE - $SIZE"
echo " "

echo "============================================================="
echo "Eseguo il resize..."
echo "  "

# Calcolo la size attuale del device perche' dovro' ottenere la size finale,
# ampliamento compreso, del device

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF > /tmp/db-ampliamento-dati-lowhigh
declare @low int, @high int
select @low = 0
select @high = 0
select @low = low, @high = high from sysdevices where name = '$NOMEDEVICE'
if @@error != 0 select 'ERRORELH'
select 'LOWHIGH',@low,@high
if @@error != 0 select 'ERRORELH'
if @high = 0 select 'ERRORELH'
go
exit
EOF

ERRORE_LOW_HIGH=`grep ERRORELH /tmp/db-ampliamento-dati-lowhigh | wc -l`

#echo $ERRORE_LOW_HIGH

if [ $ERRORE_LOW_HIGH -gt 0 ] ; then
   echo Errore nella query per la determinazione della size attuale del device
   rm -f /tmp/db-ampliamento-dati-*
   exit 1;
fi

SIZE_ATTUALE_DEVICE=`grep LOWHIGH /tmp/db-ampliamento-dati-lowhigh | awk '{ print ($3 - $2 + 1)*2048/1048576; }'`

echo "Size attuale device: " $SIZE_ATTUALE_DEVICE "MB"

# La size attuale piu' la size dell'ampliamento fanno la size finale del device
SIZE_FINALE_DEVICE=`echo $SIZE_ATTUALE_DEVICE $SIZE | awk '{ print ($1 + $2); }'`

echo "Size finale device: " $SIZE_FINALE_DEVICE "MB"

# Eseguo il resize del device e l'alter database per ampliarlo

isql -U$SAUSER -P$SAPWD -S$ASE_NAME -w400  <<  EOF > /tmp/db-ampliamento-dati-resize
disk resize name = "$NOMEDEVICE", size ="${SIZE}M"
if @@error != 0 select 'ERRORERESIZE'
go
alter database $NOMEDB on $NOMEDEVICE = "${SIZE_FINALE_DEVICE}M"
if @@error != 0 select 'ERRORERESIZE'
go
exit
EOF

ERRORE_RESIZE=`grep ERRORERESIZE /tmp/db-ampliamento-dati-resize | wc -l`

#cat /tmp/db-ampliamento-dati-resize

if [ $ERRORE_RESIZE -gt 0 ] ; then
   echo "Errore nel resize o nell'alter del db" 
   rm -f /tmp/db-ampliamento-dati-*
   exit 1;
fi

echo " "
echo Operazione effettuata
echo Ampliamento eseguito di $SIZE MB
echo " "

rm -f /tmp/db-ampliamento-dati-*

exit


