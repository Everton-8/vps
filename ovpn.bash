#!/bin/bash
if readlink /proc/$$/exe | grep -qs "dash"; then
	echo "This script needs to be run with bash, not sh"
	exit 1
fi

if [[ "$EUID" -ne 0 ]]; then
	echo "Sorry, you need to run this as root"
	exit 2
fi

if [[ ! -e /dev/net/tun ]]; then
if [ -z "$(command grep '^tun$' '/etc/modules')" ]; then
  command echo '# Needed by OpenVPN
tun' >> '/etc/modules'
fi
if [ ! -e '/dev/net/tun' ]; then
  command mkdir --parent '/dev/net'
  command mknod '/dev/net/tun' c 10 200
fi
	echo "TUN is not available"
	exit 3
fi

if grep -qs "CentOS release 5" "/etc/redhat-release"; then
	echo "CentOS 5 is too old and not supported"
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
	echo "Looks like you aren't running this installer on a Debian, Ubuntu or CentOS system"
	exit 5
fi

#cores#
_cor0="\033[0m"
#COLORS BASH
preto="\033[01;30m"
vermelho="\033[01;31m"
verde="\033[01;32m"
amarelo="\033[01;33m"
azul="\033[01;34m"
magenta="\033[01;35m"
ciano="\033[01;36m"
branco="\033[01;37m"
#FUNDOS BASH
pretof="\033[01;40m"
vermelhof="\033[01;41m"
verdef="\033[01;42m"
amarelof="\033[01;43m"
azulf="\033[01;44m"
magentaf="\033[01;45m"
cianof="\033[01;46m"
brancof="\033[01;47m"
#END-COLORS BASH

newclient () {
	# Generates the custom client.ovpn
	cp /etc/openvpn/client-common.txt ~/$1.ovpn
	echo "<ca>" >> ~/$1.ovpn
	cat /etc/openvpn/easy-rsa/pki/ca.crt >> ~/$1.ovpn
	echo "</ca>" >> ~/$1.ovpn
	echo "<cert>" >> ~/$1.ovpn
	cat /etc/openvpn/easy-rsa/pki/issued/$1.crt >> ~/$1.ovpn
	echo "</cert>" >> ~/$1.ovpn
	echo "<key>" >> ~/$1.ovpn
	cat /etc/openvpn/easy-rsa/pki/private/$1.key >> ~/$1.ovpn
	echo "</key>" >> ~/$1.ovpn
	echo "<tls-auth>" >> ~/$1.ovpn
	cat /etc/openvpn/ta.key >> ~/$1.ovpn
	echo "</tls-auth>" >> ~/$1.ovpn
}

# Try to get our IP from the system and fallback to the Internet.
# I do this to make the script compatible with NATed servers (lowendspirit.com)
# and to avoid getting an IPv6.
IP=$(ip addr | grep 'inet' | grep -v inet6 | grep -vE '127\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | grep -o -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | head -1)

if [[ -e /etc/openvpn/server.conf ]]; then
	while :
	do
	clear
if [ $(id -u) -eq 0 ]
then
	clear
else
	if echo $(id) |grep sudo > /dev/null
	then
	clear
	echo "Voce n�o � root"
	echo "Seu usuario esta no grupo sudo"
	echo -e "Para virar root execute \033[1;31msudo su\033[0m"
	exit
	else
	clear
	echo -e "Vc nao esta como usuario root, nem com seus direitos (sudo)\nPara virar root execute \033[1;31msu\033[0m e digite sua senha root"
	exit
	fi
fi

clear
echo -e "\033[36;37m PAINEL DE GERENCIAMENTO DO OPENVPN, OS ARQUIVOS SER�O SALVOS NA PASTA ROOT\033[0m"
echo -e "\033[01;31m BY @e8th4eve, @Fenix_linuxr"
echo -e "\033[01;31m Modifica��es e adapta��es por Kingsman"
echo -e "\033[0;35m------------------------------------------------------------\033[0m"
echo -e "\033[1;36m[\033[1;31m1\033[1;36m] CRIAR USU�RIO \033[1;30m(CRIA USU�RIOS)\033[1;36m
[\033[1;31m2\033[1;36m] REMOVER USU�RIO \033[1;30m(REMOVE UM USU�RIO)\033[1;36m
[\033[1;31m3\033[1;36m] REMOVER TODOS OS USU�RIOS \033[1;30m(REMOVE TODOS OS USU�RIOS)\033[1;36m
[\033[1;31m4\033[1;36m] REMOVER OPENVPN \033[1;30m(DESINSTALA O OPENVPN)\033[1;36m
[\033[1;31m5\033[1;36m] ELIMINAR VENCIDOS \033[1;30m(ELIMINA TODOS OS USU�RIOS VENCIDOS)\033[1;36m
[\033[1;31m6\033[1;36m] MUDAR DATA DE UM USU�RIO \033[1;30m(ALTERA A DATA DE VENCIMENTO DE UM USU�RIO)\033[1;36m
[\033[1;31m7\033[1;36m] EDITAR USU�RIO \033[1;30m(MUDA A CONFIGURA��O DE UM CLIENTE GERADO)\033[1;36m
[\033[1;31m8\033[1;36m] MONITOR DE USU�RIOS OPENVPN \033[1;30m(MONITORA OS CLIENTES GERADOS)\033[1;36m
[\033[1;31m9\033[1;36m] REINICIAR OPENVPN\033[1;30m(REINICIA OS SERVI�OS OPENVPN)\033[1;36m
[\033[1;31m0\033[1;36m] VOLTAR \033[1;30m(RETORNA AO MENU PRINCIPAL)\033[0m"
echo -e "\033[0;35m------------------------------------------------------------\033[0m"
echo -e "\033[1;36mO QU� DESEJA FAZER?\033[0m"
read -p ": " opcao

case $opcao in
  1) 
echo -e "\033[1;33m"
echo "NOME DO NOVO USU�RIO?"
echo -e "\033[1;31mUse somente o nome sem caracteres especiais | Este usu�rio tamb�m pode ser usado para SSH!\033[0m"
read -p "Nome do usu�rio: " CLIENT
awk -F : ' { print $1 }' /etc/passwd > /tmp/users
if grep -Fxq "$CLIENT" /tmp/users
then
echo -e "\033[1;31mUsu�rio ja existente em seu servidor!\033[0m"
sleep 5s
ovpn
exit
fi
rm -rf /tmp/users
echo -e "\033[1;31mDIGITE A SENHA\033[0m"
read -p "senha: " senha
cd /etc/openvpn/easy-rsa/
./easyrsa build-client-full $CLIENT nopass
newclient "$CLIENT"
echo ""
echo "Client $CLIENT KEY DISPON�VEL" ~/"$CLIENT.ovpn"
#####Sistema datagem
echo -e "\033[1;31mDefinir tempo de validade(em dias)? 
[s/n]\033[0m"
read -p ": " simounao
if [ "$simounao" = "s" ]
then
echo -e "\033[1;32mQuantos dias usu�rio $CLIENT deve durar:\033[0;37m"
read -p " " daysrnf
echo -e "\033[0m"
valid=$(date '+%C%y-%m-%d' -d " +$daysrnf days")
datexp=$(date "+%d/%m/%Y" -d "+ $daysrnf days")
useradd -M -s /bin/false -d /home/ovpn/ $CLIENT -e $valid
usermod -p $(openssl passwd -1 $senha) $CLIENT
touch /etc/VpsPackdir/senha/$CLIENT
touch /etc/VpsPackdir/limite/$CLIENT
echo -e "$senha" > /etc/VpsPackdir/senha/$CLIENT
echo -e "OPENVPN" > /etc/VpsPackdir/limite/$CLIENT
echo -e "\033[1;36mCRIADO COM SUCESSO \033[0m"
echo -e "\033[1;36mPara encontrar o arquivo v� no menu do ADM>2>8 \033[0m"
sleep 4s
ovpn
exit
  else
useradd -M -s /bin/false -d /home/ovpn/ $CLIENT
usermod -p $(openssl passwd -1 $senha) $CLIENT
touch /etc/VpsPackdir/senha/$CLIENT
touch /etc/VpsPackdir/limite/$CLIENT
echo -e "$senha" > /etc/VpsPackdir/senha/$CLIENT
echo -e "OPENVPN" > /etc/VpsPackdir/limite/$CLIENT
echo -e "\033[1;36mCRIADO COM SUCESSO \033[0m"
echo -e "\033[1;36mPara encontrar o arquivo v� no menu do ADM>2>8 \033[0m"
ovpn
exit
fi
;;
  2)
echo -e "\033[1;33m"
NUMBEROFCLIENTS=$(tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep -c "^V")
if [[ "$NUMBEROFCLIENTS" = '0' ]]; then
echo ""
echo "N�O H� USU�RIOS AINDA"
echo -e "\033[0m"
ovpn
exit
	fi
echo -e "\033[1;36m"
echo "Selecione um usu�rio para remover"
tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep "^V" | cut -d '=' -f 2 | nl -s ') '
if [[ "$NUMBEROFCLIENTS" = '1' ]]; then
read -p "Selecione um usu�rio [1]: " CLIENTNUMBER
else
read -p "Selecione um usu�rio [1-$NUMBEROFCLIENTS]: " CLIENTNUMBER
fi
if [ "$CLIENTNUMBER" = "" ]
then
echo -e "\033[1;31m"
echo "NENHUM USU�RIO FOI SELECIONADO"
echo -e "\033[0m"
sleep 4s
ovpn
exit
fi
CLIENT=$(tail -n +2 /etc/openvpn/easy-rsa/pki/index.txt | grep "^V" | cut -d '=' -f 2 | sed -n "$CLIENTNUMBER"p)
cd /etc/openvpn/easy-rsa/
./easyrsa --batch revoke $CLIENT
./easyrsa gen-crl
rm -rf pki/reqs/$CLIENT.req
rm -rf pki/private/$CLIENT.key
rm -rf pki/issued/$CLIENT.crt
rm -rf /etc/openvpn/crl.pem
cp /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/crl.pem
chown nobody:$GROUPNAME /etc/openvpn/crl.pem
echo ""
userdel --force $CLIENT
rm -rf /etc/VpsPackdir/senha/$CLIENT
rm -rf /etc/VpsPackdir/limite/$CLIENT
echo -e "\033[1;31m"
echo "REMOVIDO"
echo -e "\033[0m"
sleep 6s
ovpn
exit;;
  3)
echo -e "\033[1;33m"
touch /tmp/ovpn
touch /tmp/ovpn2
cat /etc/passwd |grep ovpn > /tmp/ovpn
awk -F: '{print $1}' /tmp/ovpn > /tmp/ovpn2
for userss in $(cat /tmp/ovpn2)
do
echo -e "\033[1;31m------------------------------------------------------------\033[0m"
sleep 2s
cd /etc/openvpn/easy-rsa/
./easyrsa --batch revoke $userss
./easyrsa gen-crl
rm -rf pki/reqs/$userss.req
rm -rf pki/private/$userss.key
rm -rf pki/issued/$userss.crt
rm -rf /etc/openvpn/crl.pem
cp /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/crl.pem
chown nobody:$GROUPNAME /etc/openvpn/crl.pem
echo ""
userdel --force $userss
rm -rf /etc/VpsPackdir/senha/$userss
rm -rf /etc/VpsPackdir/limite/$userss
done
echo -e "\033[1;31m------------------------------------------------------------\033[0m"
echo "REMOVIDOS"
rm -rf /tmp/ovpn
rm -rf > /tmp/ovpn2
sleep 4s
echo -e "\033[0m"
ovpn
exit;;
  4) 
			echo ""
read -p "Voc� realmente deseja remover o OpenVPN? [y/n]: " -e -i n REMOVE
if [[ "$REMOVE" = 'y' ]]; then
PORT=$(grep '^port ' /etc/openvpn/server.conf | cut -d " " -f 2)
PROTOCOL=$(grep '^proto ' /etc/openvpn/server.conf | cut -d " " -f 2)
IP=$(grep 'iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j SNAT --to ' $RCLOCAL | cut -d " " -f 11)
if pgrep firewalld; then
					# Using both permanent and not permanent rules to avoid a firewalld reload.
firewall-cmd --zone=public --remove-port=$PORT/$PROTOCOL
firewall-cmd --zone=trusted --remove-source=10.8.0.0/24
firewall-cmd --permanent --zone=public --remove-port=$PORT/$PROTOCOL
firewall-cmd --permanent --zone=trusted --remove-source=10.8.0.0/24
fi
if iptables -L -n | grep -qE 'REJECT|DROP|ACCEPT'; then
iptables -D INPUT -p $PROTOCOL --dport $PORT -j ACCEPT
iptables -D FORWARD -s 10.8.0.0/24 -j ACCEPT
iptables -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
sed -i "/iptables -I INPUT -p $PROTOCOL --dport $PORT -j ACCEPT/d" $RCLOCAL
sed -i "/iptables -I FORWARD -s 10.8.0.0\/24 -j ACCEPT/d" $RCLOCAL
sed -i "/iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT/d" $RCLOCAL
fi
iptables -t nat -D POSTROUTING -s 10.8.0.0/24 -j SNAT --to $IP
sed -i '/iptables -t nat -A POSTROUTING -s 10.8.0.0\/24 -j SNAT --to /d' $RCLOCAL
if hash sestatus 2>/dev/null; then
if sestatus | grep "Current mode" | grep -qs "enforcing"; then
if [[ "$PORT" != '1194' || "$PROTOCOL" = 'tcp' ]]; then
semanage port -d -t openvpn_port_t -p $PROTOCOL $PORT
	fi
 fi
fi
if [[ "$OS" = 'debian' ]]; then
apt-get remove --purge -y openvpn openvpn-blacklist
else
yum remove openvpn -y
fi
rm -rf /etc/openvpn
rm -rf /usr/share/doc/openvpn*
echo ""
echo "OpenVPN removido!"
adm
exit
else
echo ""
echo "Remo��o abordada!"
fi
adm
exit;;
 0)
FILE=/bin/adm
if [ -e "$FILE" ]; then
adm
else
exit
fi
exit;;
 5)
cat /etc/passwd |grep ovpn > /tmp/ovpn
datenow=$(date +%s)
tput setaf 7 ; tput setab 2 ; tput bold ; printf '%45s%-10s%-5s\n' "Removedor de contas expiradas" ""
printf '%-20s%-25s%-20s\n' "Usu�rio" "Data de expira��o" "Estado/A��o" ; echo "" ; tput sgr0
for user in $(awk -F: '{print $1}' /tmp/ovpn); do
	expdate=$(chage -l $user|awk -F: '/Account expires/{print $2}')
	echo $expdate|grep -q never && continue
	datanormal=$(date -d"$expdate" '+%d/%m/%Y')
	tput setaf 3 ; tput bold ; printf '%-20s%-21s%s' $user $datanormal ; tput sgr0
	expsec=$(date +%s --date="$expdate")
	diff=$(echo $datenow - $expsec|bc -l)
	tput setaf 2 ; tput bold
	echo $diff|grep -q ^\- && echo "Ativo (N�o removido)" && continue
	tput setaf 1 ; tput bold
echo "Expirado (Removido)"
cd /etc/openvpn/easy-rsa/
./easyrsa --batch revoke $user
./easyrsa gen-crl
rm -rf pki/reqs/$user.req
rm -rf pki/private/$user.key
rm -rf pki/issued/$user.crt
rm -rf /etc/openvpn/crl.pem
cp /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn/crl.pem
chown nobody:$GROUPNAME /etc/openvpn/crl.pem
userdel --force $user
rm -rf /etc/VpsPackdir/senha/$user
rm -rf /etc/VpsPackdir/limite/$user
sleep 1s
done 
tput sgr0 
sleep 2s
cd /root/
rm  -rf /tmp/ovpn
ovpn
exit
;;
6)
cat /etc/passwd |grep ovpn > /tmp/ovpn
echo -e "\033[1;33mUSU�RIOS"
SDK=$(awk -F: '{print $1}' /tmp/ovpn)
if [ "$SDK" = "" ]
then
echo -e "\033[1;31mVOCE N�O TEM USU�RIOS PARA MUDAR A DATA!\033[0m"
ovpn
exit
 else
echo -e "\033[1;31m_____________________________"
awk -F: '{print $1}' /tmp/ovpn
echo -e "\033[1;31m_____________________________"
echo -e "\033[1;36mNOME DO USU�RIO\033[0m"
read -p ": " namer
echo -e "\033[1;36mDIGITE A NOVA DATA EM N�MEROS\033[0m"
echo -e "\033[1;36mDIA?\033[0m"
read -p ": " dia
echo -e "\033[1;36mM�S?\033[0m"
read -p ": " mes
echo -e "\033[1;36mANO?\033[0m"
read -p ": " ano
date="$ano/$mes/$dia"
chage -E $date $namer 2> /dev/null
echo -e "\033[1;31mUsuario $namer Date: $date\033[0m"
sleep 1s
ovpn
exit
fi
;;
7)
clear
echo -e "\033[1;33m
1 \033[1;31mDigite o valor a ser alterado, tem que estar igual ao do arquivo.\033[1;33m

2 \033[1;31mDigite o novo valor."
sleep 6s
echo -e "\033[1;33m__________________________________________\033[1;32m"
cat /etc/openvpn/client-common.txt
echo -e "\033[1;33m__________________________________________\033[0m"
echo -e "\033[1;33mVALOR A ALTERAR!"
read -p ": " valor1
if [ "$valor1" = "" ]; then
echo -e "\033[1;31mN�o digitou nada!!!"
ovpn
exit
fi
echo -e "\033[1;33mNOVO VALOR!"
read -p ": " valor2
sed -i "s/$valor1/$valor2/g" /etc/openvpn/client-common.txt
testt=$(cat /etc/openvpn/client-common.txt |egrep -o $valor2)
if [ "$testt" = "" ]; then
echo -e "\033[1;31mNAO ALTERADO VOC� DIGITOU ERRADO O VALOR A ALTERAR!"
sleep 5s
else
echo -e "\033[1;36mSUCESSO, VALOR ALTERADO!"
sleep 3s
fi
ovpn
exit
;;
8)
echo -e "\033[1;33m"
touch /tmp/ovpn
touch /tmp/ovpn2
usuario=$(printf '%-18s' "USUARIO")
conexao=$(printf '%-10s' "ONLINE")
echo -e "\033[01;32m-------------------------"
echo -e "\033[01;31m$usuario $conexao\033[00;37m"
echo -e "\033[01;32m-------------------------"
cat /etc/passwd |grep ovpn > /tmp/ovpn
awk -F: '{print $1}' /tmp/ovpn > /tmp/ovpn2
for us1 in $(cat /tmp/ovpn2)
do
us=$(cat /etc/openvpn/openvpn-status.log |grep $us1 |wc -l)
if [ "$us" = "0" ]; then
on="0"
else 
on="1"
fi
usr=$(printf '%-18s' "$us1")
cnx=$(printf '%-10s' "$on")
echo -e "\033[01;33m$usr $cnx\033[0m"
echo -e "\033[01;32m-------------------------"
done
read -p "Enter, para retornar "
rm -rf /tmp/ovpn
rm -rf /tmp/ovpn2
ovpn
exit
;;
9)
chmod 777 /etc/init.d/openvpn
/etc/init.d/openvpn stop
/etc/init.d/openvpn start
;;
 *)
tput setaf 7 ; tput setab 4 ; tput bold ; printf '%44s%s%-20s\n' "OP��O INV�LIDA..." ; tput sgr0
sleep 1
exit;;
esac
	done
else
	clear
echo -e "\033[1;33m"
echo 'OPENVPN N�O EST� INSTALADO, DESEJA CONTINUAR?'
echo -e "\033[0m[s/n]"
read -p ": " sni
case $sni in
(n|N)
echo -e "\033[1;31mABORTANDO INSTALA��O\033[0m"
sleep 4s
exit
exit
;;
(s|S)
mkdir /etc/VpsPackdir
mkdir /etc/adm
mkdir /etc/VpsPackdir/limite
mkdir /etc/VpsPackdir/senha
mkdir /etc/adm/modulo
clear
;;
*)
echo -e "\033[1;31mABORTANDO INSTALA��O\033[0m"
sleep 4s
exit
exit
;;
esac
 echo -e "\033[1;31m"
	echo "Responda �s perguntas para iniciar a instala��o"
	echo "Responda corretamente"
	echo ""
echo -e "\033[1;33mPrimeiro precisaremos do ip de sua m�quina,este ip est� correto?\033[0m"
	read -p "Endere�o IP: " -e -i $IP IP
	echo ""
echo -e "\033[1;31mQual protocolo voc� deseja usar para �s conex�es OPENVPN?"
echo -e "\033[1;33m   1) UDP"
echo -e "   2) TCP (Recomendado)"
echo -e "\033[0m"
	read -p "Protocol [1-2]: " PROTOCOL
	case $PROTOCOL in
		1) 
		PROTOCOL=udp
		;;
		2) 
		PROTOCOL=tcp
		;;
     *)
     PROTOCOL=tcp
     ;;
	esac
	echo ""
echo -e "\033[1;33mQual porta voce deseja usar ?\033[0m"
	read -p "Port: " -e -i 1194 pt
	echo ""
echo -e "\033[1;31mO SCRIPT VAI VERIFICAR SE A PORTA\033[1;33m $pt\033[1;31m EST� SENDO USADA, PARA EVITAR PROBLEMAS!\033[0m"
sleep 3s
if [[ -e /etc/ssh/sshd_config ]]; then
var1=$(cat /etc/ssh/sshd_config |egrep -o "Port $pt" |wc -l)
 if [ "$var1" = "0" ]; then
echo -e "\033[1;33mSSH OK!\033[0m"
sleep 3s
else
echo -e "\033[1;33mPORTA $pt USADA PELO SSH\033[0m"
sleep 3s
menu
exit
 fi
fi
if [[ -e /etc/default/dropbear ]]; then
var2=$(cat /etc/default/dropbear |egrep -o "$pt" |wc -l)
 if [ "$var2" = "0" ]; then
echo -e "\033[1;33mDROPBEAR OK!\033[0m"
sleep 3s
else
echo -e "\033[1;33mPORTA $pt USADA PELO DROPBEAR\033[0m"
sleep 3s
menu
exit
 fi
fi
if [[ -e /etc/squid/squid.conf ]]; then
var3=$(cat /etc/squid/squid.conf |egrep -o "http_port $pt" |wc -l)
 if [ "$var3" = "0" ]; then
echo -e "\033[1;33mSQUID OK!\033[0m"
sleep 3s
else
echo -e "\033[1;33mPORTA $pt USADA PELO SQUID\033[0m"
sleep 3s
menu
exit
 fi
fi
if [[ -e /etc/squid3/squid.conf ]]; then
var4=$(cat /etc/squid3/squid.conf |egrep -o "http_port $pt" |wc -l)
 if [ "$var4" = "0" ]; then
echo -e "\033[1;33mSQUID OK!\033[0m"
sleep 3s
else
echo -e "\033[1;33mPORTA $pt USADA PELO SQUID\033[0m"
sleep 3s
menu
exit
 fi
fi
PORT="$pt"
echo -e "\033[1;33m
Qual DNS voc� deseja usar?
\033[1;31m  1)\033[1;33m Sistema(Recomendado)
\033[1;31m  2)\033[1;33m Google
\033[1;31m  3)\033[1;33m OpenDNS
\033[1;31m  4)\033[1;33m NTT
\033[1;31m  5)\033[1;33m Level 3
\033[1;31m  6)\033[1;33m Verisign\033[0m"
read -p "DNS [1-6]: " denesi
if [ "$denesi" = "1" ]; then
DNS="1"
 else
 if [ "$denesi" = "2" ]; then
DNS="2"
  else
  if [ "$denesi" = "3" ]; then
DNS="3"
   else
   if [ "$denesi" = "4" ]; then
DNS="4"
    else
    if [ "$denesi" = "5" ]; then
DNS="5"
    else
     if [ "$denesi" = "6" ]; then
DNS="6"
     else
DNS="1"
     fi
    fi
   fi
  fi
 fi
fi
echo ""
	echo "Agora o openvpn est� pronto para ser executado "
	read -n1 -r -p "Pressione qualquer tecla para continuar..."
	if [[ "$OS" = 'debian' ]]; then
		apt-get upgrade
		apt-get install openvpn iptables openssl ca-certificates -y
	else
		# Else, the distro is CentOS
		yum install epel-release -y
		yum install openvpn iptables openssl wget ca-certificates -y
	fi
	# An old version of easy-rsa was available by default in some openvpn packages
	if [[ -d /etc/openvpn/easy-rsa/ ]]; then
		rm -rf /etc/openvpn/easy-rsa/
	fi
	# Adquirindo easy-rsa
	wget -O ~/EasyRSA-3.0.1.tgz "https://www.dropbox.com/home/net-8?preview=EasyRSA-3.0.1.tgz"
	tar xzf ~/EasyRSA-3.0.1.tgz -C ~/
	mv ~/EasyRSA-3.0.1/ /etc/openvpn/
	mv /etc/openvpn/EasyRSA-3.0.1/ /etc/openvpn/easy-rsa/
	chown -R root:root /etc/openvpn/easy-rsa/
	rm -rf ~/EasyRSA-3.0.1.tgz
	cd /etc/openvpn/easy-rsa/
	# Create the PKI, set up the CA, the DH params and the server + client certificates
	./easyrsa init-pki
	./easyrsa --batch build-ca nopass
	./easyrsa gen-dh
	./easyrsa build-server-full server nopass
	./easyrsa build-client-full admpro nopass
	./easyrsa gen-crl
	# Move the stuff we need
	cp pki/ca.crt pki/private/ca.key pki/dh.pem pki/issued/server.crt pki/private/server.key /etc/openvpn/easy-rsa/pki/crl.pem /etc/openvpn
	# CRL is read with each client connection, when OpenVPN is dropped to nobody
	chown nobody:$GROUPNAME /etc/openvpn/crl.pem
	# Generando key for tls-auth
	openvpn --genkey --secret /etc/openvpn/ta.key
  # Generando server.conf
echo "port $PORT
proto $PROTOCOL
dev tun
sndbuf 0
rcvbuf 0
ca ca.crt
cert server.crt
key server.key
dh dh.pem
tls-auth ta.key 0
topology subnet
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt" > /etc/openvpn/server.conf
 echo 'tun' >> /etc/modules
 echo 'push "redirect-gateway def1 bypass-dhcp"' >> /etc/openvpn/server.conf
	# DNS
	case $DNS in
		1) 
		# Obtain the resolvers from resolv.conf and use them for OpenVPN
		grep -v '#' /etc/resolv.conf | grep 'nameserver' | grep -E -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | while read line; do
			echo "push \"dhcp-option DNS $line\"" >> /etc/openvpn/server.conf
		done
		;;
		2) 
		echo 'push "dhcp-option DNS 8.8.8.8"' >> /etc/openvpn/server.conf
		echo 'push "dhcp-option DNS 8.8.4.4"' >> /etc/openvpn/server.conf
		;;
		3)
		echo 'push "dhcp-option DNS 208.67.222.222"' >> /etc/openvpn/server.conf
		echo 'push "dhcp-option DNS 208.67.220.220"' >> /etc/openvpn/server.conf
		;;
		4) 
		echo 'push "dhcp-option DNS 129.250.35.250"' >> /etc/openvpn/server.conf
		echo 'push "dhcp-option DNS 129.250.35.251"' >> /etc/openvpn/server.conf
		;;
		5) 
		echo 'push "dhcp-option DNS 209.244.0.4"' >> /etc/openvpn/server.conf
		echo 'push "dhcp-option DNS 209.244.0.3"' >> /etc/openvpn/server.conf
		;;
		6) 
		echo 'push "dhcp-option DNS 64.6.64.6"' >> /etc/openvpn/server.conf
		echo 'push "dhcp-option DNS 64.6.65.6"' >> /etc/openvpn/server.conf
		;;
	esac
#################################
echo "keepalive 10 120
cipher AES-256-CBC
comp-lzo
user nobody
group $GROUPNAME
persist-key
persist-tun
status openvpn-status.log
verb 3
crl-verify crl.pem
client-to-client
client-cert-not-required
username-as-common-name
plugin /usr/lib/openvpn/openvpn-plugin-auth-pam.so login" >> /etc/openvpn/server.conf
#################################
	# Enable net.ipv4.ip_forward for the system
	sed -i '/\<net.ipv4.ip_forward\>/c\net.ipv4.ip_forward=1' /etc/sysctl.conf
	if ! grep -q "\<net.ipv4.ip_forward\>" /etc/sysctl.conf; then
		echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf
	fi
	# Avoid an unneeded reboot
	echo 1 > /proc/sys/net/ipv4/ip_forward
	# Needed to use rc.local with some systemd distros
	if [[ "$OS" = 'debian' && ! -e $RCLOCAL ]]; then
		echo '#!/bin/sh -e
exit 0' > $RCLOCAL
	fi
	chmod +x $RCLOCAL
	# Set NAT for the VPN subnet
	iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j SNAT --to $IP
	sed -i "1 a\iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -j SNAT --to $IP" $RCLOCAL
	if pgrep firewalld; then
		# We don't use --add-service=openvpn because that would only work with
		# the default port and protocol. Using both permanent and not permanent
		# rules to avoid a firewalld reload.
		firewall-cmd --zone=public --add-port=$PORT/$PROTOCOL
		firewall-cmd --zone=trusted --add-source=10.8.0.0/24
		firewall-cmd --permanent --zone=public --add-port=$PORT/$PROTOCOL
		firewall-cmd --permanent --zone=trusted --add-source=10.8.0.0/24
	fi
	if iptables -L -n | grep -qE 'REJECT|DROP'; then
		# If iptables has at least one REJECT rule, we asume this is needed.
		# Not the best approach but I can't think of other and this shouldn't
		# cause problems.
		iptables -I INPUT -p $PROTOCOL --dport $PORT -j ACCEPT
		iptables -I FORWARD -s 10.8.0.0/24 -j ACCEPT
          iptables -F
		iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
		sed -i "1 a\iptables -I INPUT -p $PROTOCOL --dport $PORT -j ACCEPT" $RCLOCAL
		sed -i "1 a\iptables -I FORWARD -s 10.8.0.0/24 -j ACCEPT" $RCLOCAL
		sed -i "1 a\iptables -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT" $RCLOCAL
	fi
	# If SELinux is enabled and a custom port or TCP was selected, we need this
	if hash sestatus 2>/dev/null; then
		if sestatus | grep "Current mode" | grep -qs "enforcing"; then
			if [[ "$PORT" != '1194' || "$PROTOCOL" = 'tcp' ]]; then
				# semanage isn't available in CentOS 6 by default
				if ! hash semanage 2>/dev/null; then
					yum install policycoreutils-python -y
				fi
				semanage port -a -t openvpn_port_t -p $PROTOCOL $PORT
			fi
		fi
	fi
	# And finally, restart OpenVPN
	if [[ "$OS" = 'debian' ]]; then
		# Little hack to check for systemd
		if pgrep systemd-journal; then
			systemctl restart openvpn@server.service
		else
			/etc/init.d/openvpn restart
		fi
	else
		if pgrep systemd-journal; then
			systemctl restart openvpn@server.service
			systemctl enable openvpn@server.service
		else
			service openvpn restart
			chkconfig openvpn on
		fi
	fi
	# Try to detect a NATed connection and ask about it to potential LowEndSpirit users
	EXTERNALIP=$(wget -4qO- "http://whatismyip.akamai.com/")
	if [[ "$IP" != "$EXTERNALIP" ]]; then
		echo ""
		echo "Looks like your server is behind a NAT!"
		echo ""
		echo "If your server is NATed (e.g. LowEndSpirit), I need to know the external IP"
		echo "If that's not the case, just ignore this and leave the next field blank"
		read -p "External IP: " -e USEREXTERNALIP
		if [[ "$USEREXTERNALIP" != "" ]]; then
			IP=$USEREXTERNALIP
		fi
	fi
echo -e "\033[1;31mTERMINANDO"
if [[ -e /etc/squid/squid.conf ]]; then
enec="1"
else
 if [[ -e /etc/squid3/squid.conf ]]; then
enec="1"
else
enec="2"
 fi
fi
case $enec in
1)
echo -e "\033[1;31m�S CONFIGURA��ES GERADAS AUTOMATICAMENTE USAR�O O \033[1;33mPROXY $IP NA PORTA 80\033[1;31m DESEJA ALTERAR A PORTA?\033[0m"
read -p "[s/n] 
" portass
if [ "$portass" = "s" ]; then
echo -e "\033[1;31mQUAL PORTA?\033[0m"
read -p ": " xyz
proxxy="$IP"
 if [ "$xyz" = "" ]; then
xyz="80"
 fi
 else
xyz="80"
proxxy="$IP"
fi
;;
2)
echo -e "\033[1;31mN�O FOI IDENTIFICADO PROXY SQUID EM SUA VPS, DESEJA INSTAL�-LO?\033[0m"
read -p "[s/n] 
" squiid
if [ "$squiid" = "s" ]; then
wget  -O /bin/sq3 -o /dev/null https://raw.githubusercontent.com/Darkbot345/OVPN/master/sq3
chmod +x /bin/sq3
sleep 1
sq3
proxxy="$IP"
else
echo -e "\033[1;31mOK, o openvpn precisa de um PROXY para a configura��o padr�o, qual ser� o proxy?\033[0m"
read -p "Digite o PROXY: " proxxy
fi
echo -e "\033[1;31m�S CONFIGURA��ES GERADAS AUTOMATICAMENTE USAR�O O \033[1;33mPROXY $proxxy NA PORTA 80\033[1;31m DESEJA ALTERAR A PORTA?\033[0m"
read -p "[s/n] 
" portass
if [ "$portass" = "s" ]; then
echo -e "\033[1;31mQUAL A PORTA?\033[0m"
read -p ": " xyz
 if [ "$xyz" = "" ]; then
xyz="80"
 fi
 else
xyz="80"
fi
;;
esac
echo -e "\033[1;31mO HOST DO ARQUIVO PADR�O � \033[1;33mm.facebook.com\033[1;31m DESEJA ALTERAR?\033[0m"
read -p "[s/n]
" sinounot
if [ "$sinounot" = "s" ]; then
echo -e "\033[1;31mDIGITE O NOVO HOST\033[0m"
echo -e "\033[1;31m� necess�rio que ele comece com um .\033[0m"
echo -e "\033[1;31mExemplo: .claromusica.com/\033[0m"
read -p "Digite o Host: " hostx
 else
hostx="m.facebook.com"
sleep 2s
fi
################################
echo "client
dev tun
proto $PROTOCOL
sndbuf 0
rcvbuf 0
setenv opt method GET
remote portalrecarga.vivo.com.br/recarga/home $PORT
http-proxy $proxxy $xyz
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
comp-lzo
setenv opt block-outside-dns
key-direction 1
verb 3
auth-user-pass" > /etc/openvpn/client-common.txt
#################################
   echo -e "\033[0m"
	echo ""
chmod 777 /etc/init.d/openvpn
touch /etc/adm/modulo/ovpn
echo -e "\033[1;31mOPENVPN INSTALADO COM SUCESSO!"
echo -e "\033[01;32m ( UTILIZE O COMANDO \033[01;33m ovpn \033[01;32m para abrir o menu"
read -p "[aperte enter] entendi..." enter
sleep 3s
echo -e "\033[0m"
exit
fi