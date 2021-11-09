#!/bin/bash

n_lines=$(cat $svc_cf | wc -l)

if [[ $n_lines -ne 2 ]] 
then
	perror "El fichero de perfil de servicio debe tener dos lineas"
	exit 11
fi

scp $svc_cf ${host}:/root

ssh -T $host << 'EOSSH'

perror() { echo -e "$@" 1>&2; }

# parse AQUI, LAS VARIABLES NO SE EXPANDEN

dev="/dev/sdb"
mount_point="/dir2"

# Checks if device exists and is a block device
if [[ ! -b $dev ]] ; 
then
	perror "El dispositivo a montar no existe o no es un dispositivo de bloque"
	exit 12
fi

if [[ ! -d $mount_point ]] 
then
	mkdir $mount_point
	if [[ $? -ne 0 ]] ; 
	then
		exit 13
	fi

# In this case the mount point dir exists
elif [ ! -z "$(ls -A $mount_point)" ]
then
   perror "No esta vacio el directorio destino del punto de montaje"
	 exit 14
fi

echo "$dev $mount_point ext4 defaults 0 2" >> /etc/fstab
mount -t ext4 $dev $mount_point

if [[ $? -ne 0 ]] ; 
then
   perror "El propio mandato del servicio ha fallado"
	 exit 15
fi
EOSSH
