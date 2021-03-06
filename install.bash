#!/bin/bash
if readlink /proc/$$/exe | grep -qs "dash"; then
	echo "Esse script precisa ser executado com bash, não com sh"
	exit 1
fi

if [[ "$EUID" -ne 0 ]]; then
	echo -e "\033[01;31m Desculpe, é necessário executar esse script como usuário root"
	exit 2
fi

if [[ ! -e /dev/net/tun ]]; then
	echo "o dispositivo TUN não está disponpivel.
por favor, ative o TUN no cloud para usar esta instalação"
	exit 3
fi

if grep -qs "CentOS release 5" "/etc/redhat-release"; then
	echo "CentOS 5 e anteriores não são suportados"
	exit 4
fi
if [[ -e /etc/debian_version ]]; then
	OS=debian
	GROUPNAME=nogroup
	RCLOCAL='/etc/rc.local'
elif [[ -e /etc/centos-release || -e /etc/redhat-release ]]; then
	OS=centos
	GROUPNAME=nobody
	RCLOCAL='/etc/rc.d/rc.local'
else
	echo "Parece que você não está executando isso no Debian, Ubuntu ou CentOS"
	exit 5
fi
clear
echo -e "\033[01;31m "
echo "PRIMEIRO SERÁ INSTALADO O PAINEL DE GERENCIAMETO DO OPENVPN,"
echo "NET-8 VENHA SER LIVRE!"
sleep 6
clear
read -p "DESEJA INICIAR A INSTALAÇÃO DO OPENVPN? (s|n): " solo
if [ "$solo" = "s" ]; then
clear
rm /bin/ovpn/ &>/dev/null
wget -O /bin/ovpn -o /dev/null https://raw.githubusercontent.com/Everton-8/OVPN/master/ovpn
chmod +x /bin/ovpn
clear
sleep 1
echo -e "\033[01;32m INICIANDO....."
sleep 1
ovpn
fi
if [ "$solo" = "n" ]; then
clear
echo -e "\033[01;31m ABORTADO....."
sleep 2
clear
fi
exit 0
