#!/bin/bash

# Lectura del fichero de configuración
n_lines=$(cat $svc_cf | wc -l)

if [[ $n_lines -ne 2 ]] 
then
	perror "El fichero de perfil de servicio nis_client debe tener dos líneas"
	exit 51
fi

ssh -T $host >/dev/null << 'EOSSH'

perror() { echo -e "$@" 1>&2; }

svc_cf="conf"
read -r DOMAIN<$svc_cf
SERVER=`sed "2q;d" $svc_cf`

# Truco para acelerar la instalación
sudo mount --bind /bin/true /usr/sbin/invoke-rc.d

if [[ $? -ne 0 ]]  
then
	perror "Error en configuración previa a instalación de nis"
	exit 52
fi

# Instalación no interactiva del servicio
echo Instalando NIS
sudo DEBIAN_FRONTEND=noninteractive apt -y install nis

if [[ $? -ne 0 ]]  
then
	perror "Error en instalación de NIS"
	exit 53
fi

# Reestablecemos todo
umount /usr/sbin/invoke-rc.d

if [[ $? -ne 0 ]]  
then
   	perror "Error en restablecimiento tras instalación de NIS"
	exit 54
fi

# Modificación de /etc/defaultdomain
echo $DOMAIN > /etc/defaultdomain

# Información del maestro
echo Estableciendo nodo maestro
echo "domain $DOMAIN server $SERVER" >> /etc/yp.conf

# Al validar usuario se consulta el repositorio NIS
echo "passwd: compat nis" > /etc/nsswitch.conf
echo "shadow: compat nis" >> /etc/nsswitch.conf
echo "group: compat nis" >> /etc/nsswitch.conf
echo "netgroup: nis" >> /etc/nsswitch.conf
echo "hosts: files dns nis" >> /etc/nsswitch.conf

# Arranque del servicio
systemctl restart nis

if [[ $? -ne 0 ]]  
then
   	perror "Error en arranque del servicio NIS"
	exit 55
fi

EOSSH
