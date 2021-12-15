#!/bin/bash

n_lines=$(cat $svc_cf | wc -l)

if [[ $n_lines -ne 2 ]] 
then
	perror "El fichero de perfil de servicio debe tener dos lineas"
	exit 11
fi

while read line; do
  n_words1=$(wc -w <<< $line) 
  read line2
  n_words2=$(wc -w <<< $line2)
done < $svc_cf

if [[ $n_words1 -ne 1 ]] || [[ $n_words2 -ne 1 ]]
then
	perror "El formato del fichero de perfil de servicio es incorrecto"
	exit 12
fi

ssh -T $host >/dev/null << 'EOSSH'

perror() { echo -e "$@" 1>&2; }

svc_cf="conf"
read -r dev<$svc_cf
mount_point=`sed "2q;d" $svc_cf`

# Checks if device exists and is a block device
if [[ ! -b $dev ]] ; 
then
	perror "El dispositivo a montar no existe o no es un dispositivo de bloque"
	exit 13
fi

if [[ ! -d $mount_point ]] 
then
	mkdir -p $mount_point
	if [[ $? -ne 0 ]] ; 
	then
		perror "Imposible crear el punto de montaje"
		exit 14
	fi

# In this case the mount point dir exists
elif [ ! -z "$(ls -A $mount_point)" ]
then
   perror "No esta vacio el directorio destino del punto de montaje"
	 exit 15
fi

mount ext4 $dev $mount_point

# Check whether the mount instruction is already present in fstab and was mounted correctly
if [[ $? -eq 0 ]] && [ ! $(grep -q $dev /etc/fstab) ]
then
	echo "$dev $mount_point auto defaults 0 2" >> /etc/fstab
fi

if [[ $? -ne 0 ]]  
then
   perror "El propio mandato mount ha fallado"
	 exit 16
fi

EOSSH

exit $?
