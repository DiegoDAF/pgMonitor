#!/bin/bash
# - / u s r / b i n / e n v   b a s h -- Alter Version
#
# 2017-07-10 DAF Version inicial, making magic in paralelo
#
#

# ejecuta add_next_job cuando recibe una se�al de fin de un child
#trap add_next_job CHLD 

#clear
echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] Starting...

START_TIME=$(echo $(($(date +%s%N)/1000000)))
MAILDEST=dba@conexia.com
DIR=/home/bases_postgres/scripts/pgMonitor
LOG=$DIR/logs/pgproc-$(date +"%Y-%m-%d").log
PG_HOME=/usr/pgsql-9.6
THISHOST=$(hostname -f)
THISHOSTIP=$(hostname -A)
mypidfile=$DIR/pgproc.pid
LOCALPORT=6543


if [ -e $mypidfile ]; then
  echo [$(date +"%Y-%m-%d %H:%M:%S")][ERROR] "El proceso ya esta ejecutando! $mypidfile detectado" 
  #echo [$(date +"%Y-%m-%d %H:%M:%S")][ERROR] "El proceso ya esta ejecutando! $mypidfile detectado" | mutt -s "MONITOREO - Procesador Ejecutando..." $MAILDEST
  echo [$(date +"%Y-%m-%d %H:%M:%S")][ERROR] "El proceso ya esta ejecutando! $mypidfile detectado" | mutt -s "MONITOREO - Procesador Ejecutando..." -- dfeito@conexia.com
  rm -f $mypidfile
  exit
else
  touch $mypidfile
fi

echo [$(date +"%Y-%m-%d %H:%M:%S")][LOG] LOG: $LOG
echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] Borrando archivos de log viejos...
find . -name \*.log -mtime +7 -exec rm -f {} \;

#exec > >(tee -a $LOG) 2>&1

psql -h localhost -p $LOCALPORT -U postgres -d db_monitoreo -A -t -c "SELECT r.consulta_id, r.id as idd, r.server_id, r.base, replace( replace(r.resultado, '|', chr(9)), chr(10), '\\\n') resultado FROM public.resultados r where r.estado = 'AA' and r.consulta_id <> 8 order by r.id" | while IFS='|' read jconsulta_id jidd jserver_id jbase jresultado  # main loop

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
        START_LAP_TIME=$(echo $(($(date +%s%N)/1000000)))
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [UNO] Start

        nohup psql -h localhost -p $LOCALPORT -U postgres -d db_monitoreo -A -t -c "insert into resdetalle(server_id, valor, detalle_id) values ( $jserver_id , '$jresultado', (select d.id from detalles d where d.codigo = 'PV')  ) ON CONFLICT ( server_id, detalle_id ) DO UPDATE SET valor = EXCLUDED.valor, fecha_update = clock_timestamp(), version = EXCLUDED.version + 1 ;" > /dev/null 2>&1 &

        END_LAP_TIME=$(echo $(($(date +%s%N)/1000000)))
        ELAPSED_LAP_TIME=$(($END_LAP_TIME - $START_LAP_TIME))
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [UNO] End Duracion: $ELAPSED_LAP_TIME
        ;;
        2)
        START_LAP_TIME=$(echo $(($(date +%s%N)/1000000)))
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [DOS] Start

        END_LAP_TIME=$(echo $(($(date +%s%N)/1000000)))
        ELAPSED_LAP_TIME=$(($END_LAP_TIME - $START_LAP_TIME))
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [DOS] End Duracion: $ELAPSED_LAP_TIME
        ;;
        3)
        START_LAP_TIME=$(echo $(($(date +%s%N)/1000000)))
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [TRES] Start

        nohup psql -h localhost -p $LOCALPORT -U postgres -d db_monitoreo -A -t -c "update ressize set fecha_delete = clock_timestamp(), fecha_update = clock_timestamp() where server_id  = $jserver_id and detalle_id = (select d.id from detalles d where d.codigo = 'SZ') and database_id= coalesce( (select max(b.id) from bases b where b.nombre = '$jbase' and b.server_id = $jserver_id group by b.nombre, b.server_id ), 0) and fecha_delete is null;" -c "insert into ressize(server_id, valor, detalle_id, database_id) values ( $jserver_id, '$jresultado', (select d.id from detalles d where d.codigo = 'SZ'), coalesce( (select max(b.id) from bases b where b.nombre = '$jbase' and b.server_id = $jserver_id group by b.nombre, b.server_id ), 0) );" > /dev/null 2>&1 & 

        END_LAP_TIME=$(echo $(($(date +%s%N)/1000000)))
        ELAPSED_LAP_TIME=$(($END_LAP_TIME - $START_LAP_TIME))
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [TRES] End Duracion: $ELAPSED_LAP_TIME
        ;;
        4)
        START_LAP_TIME=$(echo $(($(date +%s%N)/1000000)))
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [CUATRO] Start

        nohup psql -h localhost -p $LOCALPORT -U postgres -d db_monitoreo -A -t -c "select * from public.procchildfour($jidd, $jserver_id, $jconsulta_id );" > /dev/null 2>&1 &

        END_LAP_TIME=$(echo $(($(date +%s%N)/1000000)))
        ELAPSED_LAP_TIME=$(($END_LAP_TIME - $START_LAP_TIME))
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [CUATRO] End Duracion: $ELAPSED_LAP_TIME
        ;;
        5)
        START_LAP_TIME=$(echo $(($(date +%s%N)/1000000)))
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [CINCO] Start

        nohup psql -h localhost -p $LOCALPORT -U postgres -d db_monitoreo -A -t -c "update resconn set fecha_delete = clock_timestamp(), fecha_update = clock_timestamp(), version = version + 1 where server_id  = $jserver_id and detalle_id = (select d.id from detalles d where d.codigo = 'CN') and database_id= coalesce( (select max(b.id) from bases b where b.nombre = '$jbase' and b.server_id = $jserver_id group by b.nombre, b.server_id ), 0) and fecha_delete is null;" > /dev/null 2>&1 & 

        nohup psql -h localhost -p $LOCALPORT -U postgres -d db_monitoreo -A -t -c "insert into resconn(server_id, valor, detalle_id, database_id) values ( $jserver_id, '$jresultado', (select d.id from detalles d where d.codigo = 'CN'), coalesce( (select max(b.id) from bases b where b.nombre = '$jbase' and b.server_id = $jserver_id group by b.nombre, b.server_id ), 0)  );" > /dev/null 2>&1 &

        END_LAP_TIME=$(echo $(($(date +%s%N)/1000000)))
        ELAPSED_LAP_TIME=$(($END_LAP_TIME - $START_LAP_TIME))
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [CINCO] End Duracion: $ELAPSED_LAP_TIME
        ;;
        6)
        START_LAP_TIME=$(echo $(($(date +%s%N)/1000000)))
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [SEIS] Start

        END_LAP_TIME=$(echo $(($(date +%s%N)/1000000)))
        ELAPSED_LAP_TIME=$(($END_LAP_TIME - $START_LAP_TIME))
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [SEIS] End Duracion: $ELAPSED_LAP_TIME
        ;;
        7)
        START_LAP_TIME=$(echo $(($(date +%s%N)/1000000)))
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [SIETE] Start

        END_LAP_TIME=$(echo $(($(date +%s%N)/1000000)))
        ELAPSED_LAP_TIME=$(($END_LAP_TIME - $START_LAP_TIME))
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [SIETE] End Duracion: $ELAPSED_LAP_TIME
        ;;
        8)
        START_LAP_TIME=$(echo $(($(date +%s%N)/1000000)))
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [OCHO] Start

        #nohup psql -h localhost -p $LOCALPORT -U postgres -d db_monitoreo -A -t -c "select * from public.procchildeight($jidd);" > /dev/null 2>&1 &

        END_LAP_TIME=$(echo $(($(date +%s%N)/1000000)))
        ELAPSED_LAP_TIME=$(($END_LAP_TIME - $START_LAP_TIME))
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [OCHO] End Duracion: $ELAPSED_LAP_TIME
        ;;
        9)
        START_LAP_TIME=$(echo $(($(date +%s%N)/1000000)))
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [NUEVE] Start

        END_LAP_TIME=$(echo $(($(date +%s%N)/1000000)))
        ELAPSED_LAP_TIME=$(($END_LAP_TIME - $START_LAP_TIME))
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [NUEVE] End Duracion: $ELAPSED_LAP_TIME
        ;;
        10)
        START_LAP_TIME=$(echo $(($(date +%s%N)/1000000)))
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [DIEZ] Start

        END_LAP_TIME=$(echo $(($(date +%s%N)/1000000)))
        ELAPSED_LAP_TIME=$(($END_LAP_TIME - $START_LAP_TIME))
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [DIEZ] End Duracion: $ELAPSED_LAP_TIME
        ;;
        11)
        START_LAP_TIME=$(echo $(($(date +%s%N)/1000000)))
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [ONCE] Start

        END_LAP_TIME=$(echo $(($(date +%s%N)/1000000)))
        ELAPSED_LAP_TIME=$(($END_LAP_TIME - $START_LAP_TIME))
        echo [$(date +"%Y-%m-%d %H:%M:%S")] [ONCE] End Duracion: $ELAPSED_LAP_TIME
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

    nohup psql -h localhost -p $LOCALPORT -U postgres -d db_monitoreo -A -t -c "update public.resultados set estado = 'AZ' where resultados.id = $jidd;" > /dev/null 2>&1 &


} done # Fin main loop

rm -f $mypidfile

echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO]

END_TIME=$(echo $(($(date +%s%N)/1000000)))
ELAPSED_TIME=$(($END_TIME - $START_TIME))

echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] Duracion: $ELAPSED_TIME
echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] Fin!


