#!/bin/bash

perror() { echo -e "$@" 1>&2; }

input=$1

if [ "$#" -ne 1 ]
then
	perror "El servicio requiere solo un argumento"
	exit 1
fi

if [ ! -f $input ] || [ ! -r $svc_cf ]
then
    perror "El archivo de configuración no existe"
	exit 2
fi

valid=0
while IFS= read -r line
do
  # Skip empty and commented lines
  if [[ "$line" == '' ]] || [[ "$line" == \#* ]]  
	then
    continue
  fi

	filename_pat='[[:alnum:]/_.-]+'
	pattern="(^[0-9.]+)[[:blank:]]+(${filename_pat})[[:blank:]]+(${filename_pat}$)"

	#pattern='(^[0-9.]+)[[:blank:]]+'"(${filename_pat})"'[[:blank:]]+'"(${filename_pat}$)"

	if [[ ! "$line" =~ $pattern ]] 
	then  
		perror "La siguiente linea no cumple con el formato correcto: \n$line"
		exit 3
	fi


	host=${BASH_REMATCH[1]}
	host="$host"
	svc=${BASH_REMATCH[2]}
	svc_cf=${BASH_REMATCH[3]}
	
	valid=1
	case $svc in
		mount | raid | lvm | nis_server | nis_client | nfs_server | nfs_client | backup_server | backup_client)
			if [[ ! -f $svc_cf ]] || [[ ! -r $svc_cf ]] 
			then
				perror "El siguiente fichero de configuracion de servicio no existe o no se puede leer: \n$svc_cf"
	    			exit 4
			fi

			echo -e "-------- $svc iniciando -------\n"
			
			cp $svc_cf conf
			ssh-keyscan -H ${host} 2>/dev/null >> ~/.ssh/known_hosts 
			scp conf ${host}:/root &>/dev/null

			source ${svc}.sh
			
			if [[ $? -ne 0 ]] 
			then
				echo -e "-------- $svc ha fallado -------\n"
      			exit $? 
			fi
			rm conf
			echo -e "-------- $svc completado satisfactoriamente -------\n"
			;;
		*)
		perror "El siguiente servicio no se ofrece: \n$svc"
	    exit 5
  	  ;;
	esac

done < "$input"

if [[ valid -ne 1 ]]
then
	perror "El fichero de configuración debe contar con al menos una línea válida"
	exit 6
fi
