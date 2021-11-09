#!/bin/bash

perror() { echo -e "$@" 1>&2; }

input=$1
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
		exit 1
	fi


	host=${BASH_REMATCH[1]}
	svc=${BASH_REMATCH[2]}
	svc_cf=${BASH_REMATCH[3]}
	
	case $svc in
		mount | nfs_server | nfs_client)
			if [[ ! -f $svc_cf ]] || [[ ! -r $svc_cf ]] 
			then
				perror "El siguiente fichero de configuracion de servicio no existe o no se puede leer: \n$svc_cf"
	    			exit 2
			fi
			
			# ssh -T $host : &> /dev/null
			# echo $?
			source ${svc}.sh
			
			if [[ $? -ne 0 ]] 
			then
      	exit $? 
			fi
			;;
		*)
		perror "El siguiente servicio no se ofrece: \n$svc"
	    exit 3
  	  ;;
	esac
	

done < "$input"

