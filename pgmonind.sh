#!/bin/bash
#
# 2017-06-06 DAF Version inicial, making magic
#
#

clear
echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] Starting...

jhostname=$1
jport=$2
jid=$3


START_TIME=`echo $(($(date +%s%N)/1000000))`
MAILDEST=dfeito@conexia.com
DIR=.
LOG=$DIR/pgmon-$(date +"%Y-%m-%d")-$jhostname-$jport.log
PG_HOME=/usr/pgsql-9.6
THISHOST=$(hostname -f)
THISHOSTIP=$(hostname -A)
mypidfile=./pgmon-$jhostname-$jport.pid


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

exec > >(tee -a $LOG) 2>&1

    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] 
    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] ==============================================================
    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] 
    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO]     Host: $jhostname,$jport ID: $jid
    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] 
    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] ==============================================================
    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] 
   
    nc -4 -w 10 $jhostname $jport </dev/null;
    if [ "$?" -ne 0 ]
    then
        echo [$(date +"%Y-%m-%d %H:%M:%S")][ERROR] No se puede acceder al servidor $jhostname $jport
        echo [$(date +"%Y-%m-%d %H:%M:%S")][ERROR] No se puede acceder al servidor $jhostname $jport | mutt -s "MONITOREO - Fallo ping" $MAILDEST
    else

        echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] Revisando tener las credenciales para conectarme a "$jhostname:$jport"...
        if grep -Fq "$jhostname:$jport" ~/.pgpass
        then
            echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] Credenciales encontradas! 
            echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] Recuperando version de postgres...

            varVersion=`psql -h $jhostname -p $jport -U postgres -A -t -c "SHOW server_version;"`
            echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] Version: $varVersion
            
            vcounter=0
            
            # Primero ejecuto solo las cosas que van sobre la base postgres....
            
            echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] Recuperando consultas a ejecutar sobre base postgres... 
            psql -h localhost -p 5432 -U postgres  -A -t -d db_monitoreo -c "select id, consulta  from public.consultar($jid, '$varVersion', 'postgres');" | (while IFS='|' read -a Record ; do
                
                (( vcounter++ ))

                echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] QueryID: ${Record[0]}
                echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] QueryText: ${Record[1]}

                vRta=`psql -h $jhostname -p $jport -U postgres -A -t -c "${Record[1]}"`

                vRta=${vRta//\'/\'\'}

                echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] QueryRta: $vRta
                psql -h localhost -p 5432 -U postgres -A -t -d db_monitoreo -c "select * from public.guardar($jid, ${Record[0]}, 'postgres', '$vRta');" | while IFS='|' read -a rsAccion ; do

                    vAccion=${rsAccion[1]}
                    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] Se recibio accion: $vAccion
                    fc_accion $vAccion $vRta
                    
                done

            done
            
            echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] "No hay mas consultas para la base postgres, busco para las demas bases: $vcounter"
            echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] 
            echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] ------------------------------------------------------------------------------------
            echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] 


            if [ "$vcounter" == "0" ]; then
                
                echo [$(date +"%Y-%m-%d %H:%M:%S")][ERROR] No hay consultas para "select id, consulta  from public.consultar($jid, '$varVersion', 'postgres');" 
                echo [$(date +"%Y-%m-%d %H:%M:%S")][ERROR] No hay consultas para "select id, consulta  from public.consultar($jid, '$varVersion', 'postgres');" | mutt -s "MONITOREO - Fallo por falta de comandos" $MAILDEST
               
            fi
            
            )
            vcounter2=0
            
            # Ahora ejecuto las cosas que van sobre las bases....
            
            echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] Recuperando consultas a ejecutar sobre bases..: "select id, base, consulta  from public.consultar2($jid, '$varVersion', '');"
            psql -h localhost -p 5432 -U postgres  -A -t -d db_monitoreo -c "select id, base, consulta  from public.consultar2($jid, '$varVersion', '');" | ( while IFS='|' read -a Record ; do
                
                (( vcounter2++ ))

                echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] QueryID: ${Record[0]}
                echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] QueryDB: ${Record[1]}
                echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] QueryText: ${Record[2]}


                vRta=`psql -h $jhostname -p $jport -U postgres -d ${Record[1]} -A -t -c "${Record[2]}"`

                vRta=${vRta//\'/\'\'}

                echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] QueryRta: $vRta
                psql -h localhost -p 5432 -U postgres -A -t -d db_monitoreo -c "select * from public.guardar($jid, ${Record[0]}, '${Record[1]}', '$vRta');" | while IFS='|' read -a rsAccion ; do

                    vAccion=${rsAccion[1]}
                    echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] Se recibio accion: $vAccion
                    fc_accion $vAccion $vRta
                    
                done

            done
            
            echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] "No hay mas consultas para las bases: $vcounter2"

            echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] 
            echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] ------------------------------------------------------------------------------------
            echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] 

            if [ "$vcounter2" == "0" ]; then
                
                echo [$(date +"%Y-%m-%d %H:%M:%S")][ERROR] No hay consultas para "select id, consulta  from public.consultar($jid, '$varVersion', 'postgres');" 
                echo [$(date +"%Y-%m-%d %H:%M:%S")][ERROR] No hay consultas para "select id, consulta  from public.consultar($jid, '$varVersion', 'postgres');" | mutt -s "MONITOREO - Fallo por falta de comandos" $MAILDEST
               
            fi

            )

        else
            echo [$(date +"%Y-%m-%d %H:%M:%S")][ERROR] No se encontraron las credenciales de conexion al $jhostname,$port ID $jid
            echo [$(date +"%Y-%m-%d %H:%M:%S")][ERROR] No se encontraron las credenciales de conexion al $jhostname,$port ID $jid | mutt -s "MONITOREO - Fallo por falta de credenciales" $MAILDEST
        fi

    fi 

wait     
rm $mypidfile

echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO]

END_TIME=`echo $(($(date +%s%N)/1000000))`
ELAPSED_TIME=$(($END_TIME - $START_TIME))

echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] Duracion: $ELAPSED_TIME
echo [$(date +"%Y-%m-%d %H:%M:%S")][INFO] Fin!


