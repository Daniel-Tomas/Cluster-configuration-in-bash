#!/bin/bash

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
		echo -e "La siguiente linea no cumple con el formato correcto: \n$line"
		exit 1
	fi


	host=${BASH_REMATCH[1]}
	svc=${BASH_REMATCH[2]}
	svc_cf=${BASH_REMATCH[3]}
	
	case $svc in
		mount | raid)
			if [[ ! -f $svc_cf ]] || [[ ! -r $svc_cf ]] 
			then
				echo -e "El siguiente fichero de configuracion de servicio no existe o no se puede leer: \n$svc_cf"
	    			exit 2
			fi

			source ${svc}.sh
			
			if [[ $? -ne 0 ]] 
			then
      	exit $? 
			fi
			;;
		*)
		echo -e "El siguiente servicio no se ofrece: \n$svc"
	    exit 3
  	  ;;
	esac
	

done < "$input"

