#!/bin/bash
# - / u s r / b i n / e n v   b a s h -- Alter Version
#
# 2017-07-10 DAF Version inicial, making magic in paralelo
#
#

# ejecuta add_next_job cuando recibe una señal de fin de un child
#trap add_next_job CHLD 

#clear
echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] Starting...

START_TIME=`echo $(($(date +%s%N)/1000000))`
MAILDEST=dba@conexia.com
DIR=/home/bases_postgres/scripts/pgMonitor
LOG=$DIR/logs/pgprocdaily-$(date +"%Y-%m-%d").log
PG_HOME=/usr/pgsql-9.6
THISHOST=$(hostname -f)
THISHOSTIP=$(hostname -A)
mypidfile=$DIR/pgprocdaily.pid
LOCALPORT=6543


if [ -e $mypidfile ]; then
  echo [$(date +"%Y-%m-%d %H:%M:%S")][ERROR] "El proceso ya esta ejecutando! $mypidfile detectado" 
  echo [$(date +"%Y-%m-%d %H:%M:%S")][ERROR] "El proceso ya esta ejecutando! $mypidfile detectado" | mutt -s "MONITOREO - Procesador Ejecutando..." $MAILDEST
  exit
else
  touch $mypidfile
fi

echo [$(date +"%Y-%m-%d %H:%M:%S")][LOG] LOG: $LOG
echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] Borrando archivos de log viejos...
find . -name \*.log -mtime +7 -exec rm -f {} \;

# exec > >(tee -a $LOG) 2>&1

psql -h localhost -p $LOCALPORT -U postgres -d db_monitoreo -A -t -c "SELECT r.consulta_id, r.id as idd, r.server_id, r.base, replace( replace(r.resultado, '|', chr(9)), chr(10), '\\\n') resultado FROM public.resultados r where r.id in ( select max(rx.id) id FROM public.resultados rx where rx.estado = 'AA' group by rx.server_id ) order by r.id;" | while IFS='|' read jconsulta_id jidd jserver_id jbase jresultado  # main loop

do {

    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] 
    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] ==============================================================
    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] 
    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO]     CONSULTA_ID: $jconsulta_id 
    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO]             IID: $jidd 
    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO]       SERVER_ID: $jserver_id 
    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO]            BASE: $jbase 
    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO]       RESULTADO: $jresultado
    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] 
    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] ==============================================================
    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] 
    
    case $jconsulta_id in
        1)
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [UNO] Start

        #nohup psql -h localhost -p $LOCALPORT -U postgres -d db_monitoreo -A -t -c "insert into resdetalle(server_id, valor, detalle_id) values ( $jserver_id , '$jresultado', (select d.id from detalles d where d.codigo = 'PV')  ) ON CONFLICT ( server_id, detalle_id ) DO UPDATE SET valor = EXCLUDED.valor, fecha_update = clock_timestamp(), version = EXCLUDED.version + 1 ;" > /dev/null 2>&1 &

        echo [$(date +"%Y-%m-%d %H:%M:%S")] [UNO] End
        ;;
        2)
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [DOS] Start

        echo [$(date +"%Y-%m-%d %H:%M:%S")] [DOS] End
        ;;
        3)
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [TRES] Start

        #nohup psql -h localhost -p $LOCALPORT -U postgres -d db_monitoreo -A -t -c "update ressize set fecha_delete = clock_timestamp(), fecha_update = clock_timestamp() where server_id  = $jserver_id and detalle_id = (select d.id from detalles d where d.codigo = 'SZ') and database_id= coalesce( (select max(b.id) from bases b where b.nombre = '$jbase' and b.server_id = $jserver_id group by b.nombre, b.server_id ), 0) and fecha_delete is null;" > /dev/null 2>&1 & 

        #nohup psql -h localhost -p $LOCALPORT -U postgres -d db_monitoreo -A -t -c "insert into ressize(server_id, valor, detalle_id, database_id) values ( $jserver_id, '$jresultado', (select d.id from detalles d where d.codigo = 'SZ'), coalesce( (select max(b.id) from bases b where b.nombre = '$jbase' and b.server_id = $jserver_id group by b.nombre, b.server_id ), 0) );" > /dev/null 2>&1 &

        echo [$(date +"%Y-%m-%d %H:%M:%S")] [TRES] End
        ;;
        4)
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [CUATRO] Start

        #nohup psql -h localhost -p $LOCALPORT -U postgres -d db_monitoreo -A -t -c "select * from public.procchildfour($jidd);" > /dev/null 2>&1 &

        echo [$(date +"%Y-%m-%d %H:%M:%S")] [CUATRO] End
        ;;
        5)
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [CINCO] Start

        #nohup psql -h localhost -p $LOCALPORT -U postgres -d db_monitoreo -A -t -c "update resconn set fecha_delete = clock_timestamp(), fecha_update = clock_timestamp() where server_id  = $jserver_id and detalle_id = (select d.id from detalles d where d.codigo = 'CN') and database_id= coalesce( (select max(b.id) from bases b where b.nombre = '$jbase' and b.server_id = $jserver_id group by b.nombre, b.server_id ), 0) and fecha_delete is null;" > /dev/null 2>&1 & 

        #nohup psql -h localhost -p $LOCALPORT -U postgres -d db_monitoreo -A -t -c "insert into resconn(server_id, valor, detalle_id, database_id) values ( $jserver_id, '$jresultado', (select d.id from detalles d where d.codigo = 'CN'), coalesce( (select max(b.id) from bases b where b.nombre = '$jbase' and b.server_id = $jserver_id group by b.nombre, b.server_id ), 0)  );" > /dev/null 2>&1 &

        echo [$(date +"%Y-%m-%d %H:%M:%S")] [CINCO] End
        ;;
        6)
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [SEIS] Start

        echo [$(date +"%Y-%m-%d %H:%M:%S")] [SEIS] End
        ;;
        7)
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [SIETE] Start

        echo [$(date +"%Y-%m-%d %H:%M:%S")] [SIETE] End
        ;;
        8)
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [OCHO] Start

        nohup psql -h localhost -p $LOCALPORT -U postgres -d db_monitoreo -A -t -c "select * from public.procchildeight($jidd, $jserver_id, $jconsulta_id );" > /dev/null 2>&1 &

        echo [$(date +"%Y-%m-%d %H:%M:%S")] [OCHO] Fin
        ;;
        9)
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [NUEVE] Start

        echo [$(date +"%Y-%m-%d %H:%M:%S")] [NUEVE] End
        ;;
        10)
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [DIEZ] Start

        nohup psql -h localhost -p $LOCALPORT -U postgres -d db_monitoreo -A -t -c "select * from public.procchildten($jidd);" > /dev/null 2>&1 &

        echo [$(date +"%Y-%m-%d %H:%M:%S")] [DIEZ] End
        ;;
        11)
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [ONCE] Start

        echo [$(date +"%Y-%m-%d %H:%M:%S")] [ONCE] End
        ;;
        12)
        START_LAP_TIME=$(echo $(($(date +%s%N)/1000000)))
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [DOCE] Start

        END_LAP_TIME=$(echo $(($(date +%s%N)/1000000)))
        ELAPSED_LAP_TIME=$(($END_LAP_TIME - $START_LAP_TIME))
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [DOCE] End Duracion: $ELAPSED_LAP_TIME
        ;;
        *)
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [ERROR] Salio por comando desconocido
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [ERROR] "Comando desconocido detectado resultado id: $jidd"| mutt -s "MONITOREO - Comando desconocido..." $MAILDEST
        ;;
    esac


    nohup psql -h localhost -p $LOCALPORT -U postgres -d db_monitoreo -A -t -c "update public.resultados set estado = 'AZ' where resultados.server_id = $jserver_id and resultados.consulta_id = $jconsulta_id and estado = 'AA';" > /dev/null 2>&1 &


} done # Fin main loop

nohup psql -h localhost -p $LOCALPORT -U postgres -d db_monitoreo -A -t -c "delete FROM public.resultados where estado = 'AZ' and fecha < (clock_timestamp() - INTERVAL '7 days') ;" > /dev/null 2>&1 &
nohup psql -h localhost -p $LOCALPORT -U postgres -d db_monitoreo -A -t -c "delete FROM public.resconn where fecha_insert < (clock_timestamp() - INTERVAL '60 days') ;" > /dev/null 2>&1 &

rm $mypidfile

echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO]

END_TIME=`echo $(($(date +%s%N)/1000000))`
ELAPSED_TIME=$(($END_TIME - $START_TIME))

echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] Duracion: $ELAPSED_TIME
echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] Fin!


