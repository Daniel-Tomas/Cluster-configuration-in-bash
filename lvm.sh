#!/bin/bash

n_lines=$(cat $svc_cf | wc -l)

if [[ $n_lines -lt 3 ]] 
then
	perror "El fichero de perfil de servicio debe tener al menos tres lineas"
	exit 31
fi

cp $svc_cf conf
ssh-keyscan -H ${host} 2>/dev/null >> ~/.ssh/known_hosts 
scp conf ${host}:/root &>/dev/null

ssh -T $host  >/dev/null << 'EOSSH' 

perror() { echo -e "$@" 1>&2; }

apt install -y lvm2 &>/dev/null

if [[ $? -ne 0 ]]  
then
  perror "Error en la instalacion de los paquetes necesarios"
  exit 32
fi

svc_cf="conf"
i=0
while ((i++)); IFS= read -r line
do
    if [[ $i -eq 1 ]]
    then
        vgn=$line
    elif [[ $i -eq 2 ]]
    then
        read -ra devices <<< "$line"
        for device in "${devices[@]}"
        do
            if [[ ! -b $device ]]
	        then
	  	        perror "El siguiente dispositivo no existe o no es un dispositivo de bloque: \n$device"
			    exit 35
		    fi
            pvcreate $device
            if [[ $? -ne 0 ]]
            then
                perror "Error en la iniciación del volumen físico"
                exit 36
            fi
        done
        vgcreate $vgn $line
        if [[ $? -ne 0 ]]
        then
            perror "Error en la creación del grupo de volúmenes"
            exit 37
        fi
    else
        read -ra lvp <<< "$line"
        if [[ ${#lvp[@]} -ne 2 ]]
        then
            perror "El número de elementos en esta línea es incorrecto. Se esperaban 2"
            exit 38
        fi
        lvcreate -L ${lvp[1]} -n ${lvp[0]} $vgn
        if [[ $? -ne 0 ]]
        then
            perror "Error en la creación del volumen lógico"
            exit 39
        fi
    fi

done < "$svc_cf"

EOSSH