#!/bin/bash
#
# 2017-06-06 DAF Version inicial, making magic
#
#

clear
echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] Starting...

START_TIME=`echo $(($(date +%s%N)/1000000))`
MAILDEST=dfeito@conexia.com
DIR=.
LOG=$DIR/pgmon-$(date +"%Y-%m-%d").log
PG_HOME=/usr/pgsql-9.6
THISHOST=$(hostname -f)
THISHOSTIP=$(hostname -A)
mypidfile=./pgmon.pid


function fc_accion {

    if [ "$vAccion" == "1" ]
    then # 1, descartar 
        echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] Accion de no hacer nada
    fi

    if [ "$vAccion" == "2" ]
    then # 2, enviar correo de alarma
        echo [$(date +"%Y-%m-%d %H:%M:%S")][WARN] Envio correo de alarma...
        echo "$vRta" | mutt -s "MONITOREO - Alarma detectada" $MAILDEST
        echo [$(date +"%Y-%m-%d %H:%M:%S")][WARN] Correo de alarma enviado
    fi

    if [ "$vAccion" == "3" ]
    then # 2, enviar correo de info
        echo [$(date +"%Y-%m-%d %H:%M:%S")][WARN] Envio correo de info...
        echo "$vRta" | mutt -s "MONITOREO - informacion" $MAILDEST
        echo [$(date +"%Y-%m-%d %H:%M:%S")][WARN] Correo de info enviado
    fi

}



if [ -e $mypidfile ]; then
  echo [$(date +"%Y-%m-%d %H:%M:%S")][ERROR] "El monitoreo ya esta ejecutando! $mypidfile detectado" 
  exit
else
  touch $mypidfile
fi


echo [$(date +"%Y-%m-%d %H:%M:%S")][LOG] LOG: $LOG
echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] Borrando archivos de log viejos...
find . -name \*.log -mtime +7 -exec rm -f {} \;

exec > >(tee -a $LOG) 2>&1

echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] Buscando servidores a monitorear...
psql -h localhost -p 5432 -U postgres -d db_monitoreo -A -t -c "select id, hostname, port from public.vservidores;" -o servidores.txt

cat servidores.txt | grep -v "^$" | while IFS='|' read jid jhostname jport # main loop
do {
    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] 
    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] ==============================================================
    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] 
    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO]     Host: $jhostname,$jport ID: $jid
    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] 
    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] ==============================================================
    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] 
   
    ./pgmonind.sh $jhostname $jport $jid &
    
     
} done # Fin main loop

rm $mypidfile

echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO]

END_TIME=`echo $(($(date +%s%N)/1000000))`
ELAPSED_TIME=$(($END_TIME - $START_TIME))

echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] Duracion: $ELAPSED_TIME
echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] Fin!


