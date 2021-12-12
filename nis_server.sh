#!/bin/bash

# Lectura del fichero de configuración
n_lines=$(cat $svc_cf | wc -l)

if [[ $n_lines -ne 1 ]] 
then
	perror "El fichero de perfil de servicio nis_server debe tener una línea"
	exit 41
fi

ssh -T $host >/dev/null << 'EOSSH'

perror() { echo -e "$@" 1>&2; }

svc_cf="conf"
read DOMAIN<$svc_cf

# Truco para acelerar la instalación
sudo mount --bind /bin/true /usr/sbin/invoke-rc.d

if [[ $? -ne 0 ]]  
then
	perror "Error en configuración previa a instalación de NIS"
	exit 42
fi

# Instalación no interactiva del servicio
echo Instalando NIS 
sudo DEBIAN_FRONTEND=noninteractive apt -y install nis &> /dev/null

if [[ $? -ne 0 ]]  
then
	perror "Error en instalación de NIS"
	exit 43
fi

# Reestablecemos todo
umount /usr/sbin/invoke-rc.d

if [[ $? -ne 0 ]]  
then
   	perror "Error en restablecimiento tras instalación de NIS"
	exit 44
fi

# Modificación del nombre de dominio en /etc/defaultdomain
echo "Estableciendo $DOMAIN como nombre del dominio"
echo $DOMAIN > /etc/defaultdomain

# Configuración del nodo como maestro
echo Configurando nodo maestro
sed -i 's%NISSERVER=false%NISSERVER=master%' /etc/default/nis

# Por defecto cliente, por lo tanto indicamos que el servidor se ubica aquí mismo
echo "domain $DOMAIN server 127.0.1.1" >> /etc/yp.conf

# Modificación de /var/yp/Makefile
sed -i 's%MERGE_PASSWD=false%MERGE_PASSWD=true%' /var/yp/Makefile
sed -i 's%MERGE_GROUP=false%MERGE_GROUP=true%'  /var/yp/Makefile

# Arranque del servicio
echo Arrancando el servicio
systemctl restart nis &
process_id=$!
sleep 1
/usr/lib/yp/ypinit -m < /dev/null

wait $process_id

if [[ $? -ne 0 ]]  
then
	perror "Error en arranque del servicio NIS"
	exit 45
fi

rm conf

EOSSH

exit $?
