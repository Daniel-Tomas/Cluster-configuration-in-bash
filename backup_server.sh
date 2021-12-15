#!/bin/bash

n_lines=$(cat $svc_cf | wc -l)

if [[ $n_lines -ne 1 ]] 
then
	perror "El fichero de perfil de servicio debe tener una linea"
	exit 81
fi

while read line; do
  n_words1=$(wc -w <<< $line) 
done < $svc_cf

if [[ $n_words1 -ne 1 ]]
then
	perror "El formato del fichero de perfil de servicio es incorrecto"
	exit 82
fi

ssh -T $host  >/dev/null << 'EOSSH' 

perror() { echo -e "$@" 1>&2; }

svc_cf="conf"
read -r backup_point<$svc_cf

echo $backup_point 
if [[ ! -d $backup_point ]] 
then
	mkdir -p $backup_point
	if [[ $? -ne 0 ]] ; 
	then
		perror "Imposible crear el punto de backup"
		exit 83
	fi
elif [ ! -z "$(ls -A $backup_point)" ]
then
   perror "No esta vacio el directorio destino del punto de backup"
	 exit 84
fi

EOSSH

exit $?
