#!/bin/bash

n_lines=$(cat $svc_cf | wc -l)

if [[ $n_lines -ne 3 ]] 
then
	perror "El fichero de perfil de servicio debe tener tres lineas"
	exit 21
fi

cp $svc_cf conf
scp conf ${host}:/root &>/dev/null

ssh -T $host << 'EOSSH'

perror() { echo -e "$@" 1>&2; }

apt install -y mdadm &>/dev/null

if [[ $? -ne 0 ]]  
then
  perror "Error en la instalacion de los paquetes necesarios"
  exit 22
fi


new_raid=`awk 'NR == 1' conf`

n_words=`echo $new_raid | wc -w`
if [[ $n_words -ne 1 ]]
then
	perror "La primera linea del fichero de perfil de servicio solo debe tener una palabra"
	exit 23
fi

raid_level=`awk 'NR == 2' conf`

n_words=`echo $raid_level | wc -w`
if [[ $n_words -ne 1 ]]
then
	perror "La segunda linea del fichero de perfil de servicio solo debe tener una palabra"
	exit 24
fi

if [[ ! "$raid_level"  =~ ^(0|1|4|5|6|10)$ ]]
then
	perror "Nivel raid invalido"
	exit 25
fi

devices=`awk 'NR == 3' conf`

n_devices=`echo $devices | wc -w`
if [[ $n_devices -eq 0 ]]
then
	perror "La tercera linea del fichero de perfil de servicio debe tener una o mas palabras"
	exit 26
fi

for device in $devices
	do
		if [[ ! -b $device ]]
	  then
	  	perror "El siguiente dispositivo no existe o no es un dispositivo de bloque: \n$device"
			exit 27
		fi
done


yes | mdadm --create --auto=yes --force $new_raid --level=$raid_level --raid-devices=$n_devices $devices

if [[ $? -ne 0 ]]
then
   perror "El propio mandato mdadm ha fallado"
	 exit 28
fi


mdadm --detail --scan | tee -a /etc/mdadm/mdadm.conf

if [[ $? -ne 0 ]]
then
   perror "No se ha podido completar la configuracion persistente"
	 exit 29
fi


rm conf

EOSSH