#!/bin/bash

n_lines=$(cat $svc_cf | wc -l)

if [[ $n_lines -lt 1 ]]
then
  perror "El fichero de perfil de servicio debe tener una o mas lineas"
  exit 71
fi

ssh -T $host >/dev/null << 'EOSSH'

perror() { echo -e "$@" 1>&2; }

apt install -y nfs-common &>/dev/null

if [[ $? -ne 0 ]]  
then
  perror "Error en la instalacion de los paquetes necesarios"
  exit 72
fi

input=conf
while IFS= read -r line
do
  filename_pat='[[:alnum:]/_.-]+'
	pattern="(^[0-9.]+)[[:blank:]]+(${filename_pat})[[:blank:]]+(${filename_pat}$)"

  if [[ ! "$line" =~ $pattern ]] 
  then  
    perror "La siguiente linea no cumple con el formato correcto: \n$line"
    exit 73
  fi

	server_host=${BASH_REMATCH[1]}
	dir_to_import=${BASH_REMATCH[2]}
	mount_point=${BASH_REMATCH[3]}
	
	if [[ ! -d $mount_point ]] 
	then
	  mkdir $mount_point
	  if [[ $? -ne 0 ]] ; 
	  then
			perror "Imposible crear el punto de montaje"
	    exit 74
	  fi
	
	# In this case the mount point dir exists
	elif [ ! -z "$(ls -A $mount_point)" ]
	then
	   perror "No esta vacio el directorio destino del punto de montaje"
	   exit 75
	fi
	
	mount -t nfs "${server_host}:$dir_to_import" $mount_point  
	# mount -a

	if [[ $? -ne 0 ]] ;  
	then 
	   perror "El propio mandato mount ha fallado" 
	   exit 76 
	fi 
	
	echo "${server_host}:$dir_to_import $mount_point nfs defaults 0 2" >> /etc/fstab 

	echo -e "La siguiente linea ha sido ejecutada satisfactoriamente: \n$line"

done < "$input"

EOSSH
