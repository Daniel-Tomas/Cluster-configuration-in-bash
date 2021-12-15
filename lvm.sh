#!/bin/bash

n_lines=$(cat $svc_cf | wc -l)

if [[ $n_lines -lt 3 ]] 
then
	perror "El fichero de perfil de servicio debe tener al menos tres lineas"
	exit 31
fi

while read line; do
  n_words1=$(wc -w <<< $line) 
  read line2
  n_words2=$(wc -w <<< $line2)
  read line3
  n_words3=$(wc -w <<< $line3)
done < $svc_cf

if [[ $n_words1 -ne 1 ]] || [[ $n_words2 -ne 3 ]] || [[ $n_words3 -ne 2 ]]
then
    perror "El formato del fichero de perfil de servicio es incorrecto"
    exit 32
fi

ssh -T $host  >/dev/null << 'EOSSH' 

perror() { echo -e "$@" 1>&2; }
apt install -y lvm2 &>/dev/null
if [[ $? -ne 0 ]]  
then
  perror "Error en la instalacion de los paquetes necesarios"
  exit 33
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
			    exit 34
		    fi
            pvcreate $device
            if [[ $? -ne 0 ]]
            then
                perror "Error en la iniciación del volumen físico"
                exit 35
            fi
        done
        vgcreate $vgn $line
        if [[ $? -ne 0 ]]
        then
            perror "Error en la creación del grupo de volúmenes"
            exit 36
        fi
    else
        read -ra lvp <<< "$line"
        if [[ ${#lvp[@]} -ne 2 ]]
        then
            perror "El número de elementos en esta línea es incorrecto. Se esperaban 2"
            exit 37
        fi
        lvcreate -L ${lvp[1]} -n ${lvp[0]} $vgn
        if [[ $? -ne 0 ]]
        then
            perror "Error en la creación del volumen lógico"
            exit 38
        fi
    fi
done < "$svc_cf"

EOSSH

exit $?
