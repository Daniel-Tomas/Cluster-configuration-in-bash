#!/bin/bash



n_lines=$(cat $svc_cf | wc -l)

if [[ $n_lines -ne 4 ]] 
then
	perror "El fichero de perfil de servicio debe tener cuatro lineas"
	exit 81
fi

ssh -T $host  >/dev/null << 'EOSSH' 

perror() { echo -e "$@" 1>&2; }

ipvalid()
{
  local ip=${1:-1.2.3.4}
  local IFS=.; local -a a=($ip)
  [[ $ip =~ ^[0-9]+(\.[0-9]+){3}$ ]] || return 1
  local quad
  for quad in {0..3}; do
    [[ "${a[$quad]}" -gt 255 ]] && return 1
  done
  return 0
}

svc_cf="conf"
mapfile -t content<${svc_cf} 

local_dir=${content[0]}
remote_ip=${content[1]}
remote_dir=${content[2]}
hours=${content[3]}

if [[ ! -d $local_dir ]] 
then
    perror "El directorio del que hacer backup no existe o hay más de un valor por línea"
	exit 82 
fi

if [[ $hours -gt 23 ]] || [[ $hours -lt 1 ]]
then
	perror "El valor introducido de horas no es correcto"
	exit 83 
fi

if ! ipvalid "$remote_ip" 
then
	perror "La IP a la que conectar no es válida o hay más de un valor por línea"
	exit 84 
fi

if ! ping -c 1 "$remote_ip" >/dev/null
then
	perror "No se puede establecer conexión con la IP provista"
	exit 85 
fi

ssh-keyscan -H $remote_ip 2>/dev/null >> ~/.ssh/known_hosts 

if ssh $remote_ip "[ -d $remote_dir ]"
then
	(crontab -l 2>/dev/null; echo "* */$hours * * * rsync --recursive $local_dir $remote_ip:$remote_dir") | crontab -
	if [[ $? -ne 0 ]]  
	then
		perror "No se puedo añadir el cronjob"
		exit 86
	fi
else
	perror "El directorio remoto no existe"
	exit 87 
fi

EOSSH
