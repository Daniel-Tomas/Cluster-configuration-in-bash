#!/bin/bash

n_lines=$(cat $svc_cf | wc -l) 
 
if [[ $n_lines -lt 1 ]]  
then 
  perror "El fichero de perfil de servicio debe tener una o mas lineas" 
  exit 61 
fi 

while read line; do
  n_words1=$(wc -w <<< $line) 
  if [[ $n_words1 -ne 1 ]] 
  then
		perror "El formato del fichero de perfil de servicio es incorrecto"
		exit 62
	fi
done < $svc_cf

ssh -T $host >/dev/null << 'EOSSH'

perror() { echo -e "$@" 1>&2; }

apt install -y nfs-kernel-server &>/dev/null

if [[ $? -ne 0 ]]  
then
  perror "Error en la instalacion de los paquetes necesarios"
	exit 63
fi

input=conf
while IFS= read -r line
do
  filename_pat='[[:alnum:]/_.-]+'
	pattern="^(${filename_pat})$"

  if [[ ! "$line" =~ $pattern ]] 
  then  
    perror "La siguiente linea no cumple con el formato correcto: \n$line"
    exit 64
	fi

	dir_to_export=$line

	if [[ ! -d $dir_to_export ]] 
	then
		perror "Directorio a exportar no existe o es un fichero de un tipo distinto a directorio"
		exit 65
	fi
	
	echo "$dir_to_export *(rw,sync)" >> /etc/exports
	
	echo -e "La siguiente linea ha sido procesada satisfactoriamente: \n$line"	

done < "$input"

exportfs -ra &>/dev/null

if [[ $? -ne 0 ]]  
then
	perror "Error en la exportacion de los directorios"
	exit 66
fi

EOSSH

exit $?
