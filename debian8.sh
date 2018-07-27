#!/bin/bash
# R3V1V3R
# 1NT3RN3T
# L1VR3
export DEBIAN_FRONTEND=noninteractive
OS=`uname -m`;
MYIP=$(wget -qO- ipv4.icanhazip.com);
MYIP2="s/xxxxxxxxx/$MYIP/g";

# go to root
cd
cat /etc/[A-Za-z]*[_-][rv]e[lr]* ;
sleep 5

# disable ipv6
echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6
sed -i '$ i\echo 1 > /proc/sys/net/ipv6/conf/all/disable_ipv6' /etc/rc.local

# install wget and curl
apt-get update;apt-get -y install wget curl;

# set time GMT -3
ln -fs /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

# set locale
sed -i 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
service ssh restart

# set repo
wget -O /etc/apt/sources.list "https://raw.githubusercontent.com/redeviver/script/master/sources.list.debian8"
wget "http://www.dotdeb.org/dotdeb.gpg"
cat dotdeb.gpg | apt-key add -;rm dotdeb.gpg
sh -c 'echo "deb http://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list'
wget -qO - http://www.webmin.com/jcameron-key.asc | apt-key add -

# update
apt-get update

# install webserver
apt-get -y install nginx

# install essential package
apt-get -y install nano iptables dnsutils openvpn screen whois ngrep unzip unrar

# install neofetch
echo "deb http://dl.bintray.com/dawidd6/neofetch jessie main" | tee -a /etc/apt/sources.list
curl "https://bintray.com/user/downloadSubjectPublicKey?username=bintray"| apt-key add -
apt-get update
apt-get install neofetch

echo "deb http://dl.bintray.com/dawidd6/neofetch jessie main" | tee -a /etc/apt/sources.list
curl "https://bintray.com/user/downloadSubjectPublicKey?username=bintray"| apt-key add -
apt-get update
apt-get install neofetch
echo "clear" >> .bash_profile
echo "neofetch" >> .bash_profile

# install webserver
cd
rm /etc/nginx/sites-enabled/default
rm /etc/nginx/sites-available/default
wget -O /etc/nginx/nginx.conf "https://raw.githubusercontent.com/redeviver/script/master/nginx.conf"
mkdir -p /home/vps/public_html
echo "<pre>R3V1V3R 1NT3RN3T L1VR3</pre>" > /home/vps/public_html/index.html
wget -O /etc/nginx/conf.d/vps.conf "https://raw.githubusercontent.com/redeviver/script/master/vps.conf"
service nginx restart

# install openvpn
wget -O /etc/openvpn/openvpn.tar "https://raw.githubusercontent.com/redeviver/script/master/vpn.tar"
cd /etc/openvpn/
tar xf openvpn.tar
rm -f /etc/openvpn/openvpn.tar
wget -O /etc/openvpn/1194.conf "https://raw.githubusercontent.com/redeviver/script/master/1194.conf"
service openvpn restart
sysctl -w net.ipv4.ip_forward=1
sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
iptables -t nat -I POSTROUTING -s 192.168.100.0/24 -o eth0 -j MASQUERADE
iptables-save > /etc/iptables_set.conf
wget -O /etc/network/if-up.d/iptables "https://raw.githubusercontent.com/redeviver/script/master/iptables"
chmod +x /etc/network/if-up.d/iptables
service openvpn restart

# configuração openvpn
cd /etc/openvpn/
wget -O /etc/openvpn/r3v1v3r.ovpn "https://raw.githubusercontent.com/redeviver/script/master/client-1194.conf"
sed -i $MYIP2 /etc/openvpn/r3v1v3r.ovpn;
cp r3v1v3r.ovpn /home/vps/public_html/

# install badvpn
cd
wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/redeviver/script/master/badvpn-udpgw"
if [ "$OS" == "x86_64" ]; then
  wget -O /usr/bin/badvpn-udpgw "https://raw.githubusercontent.com/redeviver/script/master/badvpn-udpgw64"
fi
sed -i '$ i\screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300' /etc/rc.local
chmod +x /usr/bin/badvpn-udpgw
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300

# setting port ssh
cd
sed -i 's/Port 22/Port 22/g' /etc/ssh/sshd_config
sed -i '/Port 22/a Port 143' /etc/ssh/sshd_config
service ssh restart

# install sslh
apt-get -y install sslh
sed -i 's/RUN=no/RUN=yes/g' /etc/default/sslh
sed -i 's/DAEMON_OPTS="--user sslh --listen <change-me>:443 --ssh 127.0.0.1:22 --ssl 127.0.0.1:443 --pidfile /var/run/sslh/sslh.pid"/DAEMON_OPTS="-u sslh -p 0.0.0.0:443 --ssh 127.0.0.1:22 --openvpn 127.0.0.1:1194 --http 127.0.0.1:81 --ssl 127.0.0.1:444 -P /var/run/sslh/sslh.pid"/g' /etc/default/sslh
service sslh start

# install dropbear
apt-get -y install dropbear
sed -i 's/NO_START=1/NO_START=0/g' /etc/default/dropbear
sed -i 's/DROPBEAR_PORT=22/DROPBEAR_PORT=444/g' /etc/default/dropbear
sed -i 's/DROPBEAR_EXTRA_ARGS=/DROPBEAR_EXTRA_ARGS="-p 444 -p 443"/g' /etc/default/dropbear
echo "/bin/false" >> /etc/shells
echo "/usr/sbin/nologin" >> /etc/shells
service ssh restart
service dropbear restart

# install dropbear 2018
cd
wget https://matt.ucc.asn.au/dropbear/releases/dropbear-2018.76.tar.bz2 #https://raw.githubusercontent.com/redeviver/script/master/
apt-get install zlib1g-dev
bzip2 -cd dropbear-2018.76.tar.bz2  | tar xvf -
cd dropbear-2018.76
./configure
make && make install
mv /usr/sbin/dropbear /usr/sbin/dropbear1
ln /usr/local/sbin/dropbear /usr/sbin/dropbear
service dropbear restart
rm -f /root/dropbear-2018.76.tar.bz2

# install stunnel4
apt-get -y install stunnel4
wget -O /etc/stunnel/stunnel.pem "https://raw.githubusercontent.com/redeviver/stunnel4/master/stunnel.pem"
wget -O /etc/stunnel/stunnel.conf "https://raw.githubusercontent.com/redeviver/stunnel4/master/stunnel.conf"
sed -i $MYIP2 /etc/stunnel/stunnel.conf
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/stunnel4
service stunnel4 restart

# install fail2ban
apt-get -y install fail2ban;
service fail2ban restart

# install squid3
cd
apt-get -y install squid3
wget -O /etc/squid3/squid.conf "https://raw.githubusercontent.com/redeviver/script/master/squid3.conf"
sed -i $MYIP2 /etc/squid3/squid.conf;
service squid3 restart

# install webmin
cd
wget "http://prdownloads.sourceforge.net/webadmin/webmin_1.890_all.deb"
dpkg --install webmin_1.890_all.deb;
apt-get -y -f install;
rm /root/webmin_1.890_all.deb
sed -i 's/ssl=1/ssl=0/g' /etc/webmin/miniserv.conf
service webmin restart

# blockir torrent
iptables -A OUTPUT -p tcp --dport 6881:6889 -j DROP
iptables -A OUTPUT -p udp --dport 1024:65534 -j DROP
iptables -A FORWARD -m string --string "get_peers" --algo bm -j DROP
iptables -A FORWARD -m string --string "announce_peer" --algo bm -j DROP
iptables -A FORWARD -m string --string "find_node" --algo bm -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "BitTorrent protocol" -j DROP
iptables -A FORWARD -m string --algo bm --string "peer_id=" -j DROP
iptables -A FORWARD -m string --algo bm --string ".torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce.php?passkey=" -j DROP
iptables -A FORWARD -m string --algo bm --string "torrent" -j DROP
iptables -A FORWARD -m string --algo bm --string "announce" -j DROP
iptables -A FORWARD -m string --algo bm --string "info_hash" -j DROP

# install ddos deflate
cd
apt-get -y install dnsutils dsniff
wget https://raw.githubusercontent.com/redeviver/script/master/ddos-deflate-master.zip
unzip ddos-deflate-master.zip
cd ddos-deflate-master
./install.sh
rm -rf /root/ddos-deflate-master.zip

# setting banner
rm /etc/issue.net
wget -O /etc/issue.net "https://raw.githubusercontent.com/redeviver/script/master/issue.net"
sed -i 's@#Banner@Banner@g' /etc/ssh/sshd_config
sed -i 's@DROPBEAR_BANNER=""@DROPBEAR_BANNER="/etc/issue.net"@g' /etc/default/dropbear
service ssh restart
service dropbear restart

# download script
cd /usr/bin
wget -O menu "https://raw.githubusercontent.com/redeviver/script/master/menu.sh"
wget -O user-add "https://raw.githubusercontent.com/redeviver/script/master/user-add.sh"
wget -O trial "https://raw.githubusercontent.com/redeviver/script/master/trial.sh"
wget -O user-del "https://raw.githubusercontent.com/redeviver/script/master/hapus.sh"
wget -O user-login "https://raw.githubusercontent.com/redeviver/script/master/user-login.sh"
wget -O user-list "https://raw.githubusercontent.com/redeviver/script/master/user-list.sh"
wget -O expdel "https://raw.githubusercontent.com/redeviver/script/master/delexp.sh"
wget -O resvis "https://raw.githubusercontent.com/redeviver/script/master/resvis.sh"
wget -O speedtest "https://raw.githubusercontent.com/redeviver/script/master/speedtest_cli.py"
wget -O info "https://raw.githubusercontent.com/redeviver/script/master/info.sh"
wget -O about "https://raw.githubusercontent.com/redeviver/script/master/about.sh"

echo "0 0 * * * root /sbin/reboot" > /etc/cron.d/reboot

chmod +x menu
chmod +x user-add
chmod +x trial
chmod +x user-del
chmod +x user-login
chmod +x user-list
chmod +x resvis
chmod +x speedtest
chmod +x info
chmod +x expdel
chmod +x about

# finishing
cd
chown -R www-data:www-data /home/vps/public_html
service nginx start
service openvpn restart
service cron restart
service ssh restart
service sslh restart
service dropbear restart
service stunnel4 restart
service squid3 restart
service fail2ban restart
service webmin restart
rm -rf ~/.bash_history && history -c
echo "desfeito HISTFILE" >> /etc/profile
clear

# info
echo "R3V1V3R"
echo "Autoscript Include:" | tee log-install.txt
echo "===========================================" | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Service"  | tee -a log-install.txt
echo "-------"  | tee -a log-install.txt
echo "OpenSSH  : 22, 143"  | tee -a log-install.txt
echo "Dropbear : 80, 444"  | tee -a log-install.txt
echo "SSL      : 443"  | tee -a log-install.txt
echo "Squid3   : 8080, 3128 (limit to IP SSH)"  | tee -a log-install.txt
echo "OpenVPN  : TCP 1194 (client config : http://$MYIP:81/r3v1v3r.ovpn)"  | tee -a log-install.txt
echo "badvpn   : badvpn-udpgw port 7300"  | tee -a log-install.txt
echo "nginx    : 81"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Script"  | tee -a log-install.txt
echo "------"  | tee -a log-install.txt
echo "menu         (Exibe uma lista de comandos disponíveis)"  | tee -a log-install.txt
echo "user-add     (Criando uma conta SSH)"  | tee -a log-install.txt
echo "trial        (Criando uma conta Teste)"  | tee -a log-install.txt
echo "user-del     (Removendo Contas SSH)"  | tee -a log-install.txt
echo "user-login   (Verifique o login do usuário)"  | tee -a log-install.txt
echo "user-list    (Verificar membro SSH)"  | tee -a log-install.txt
echo "expdel       (Excluir usuário expirado)"  | tee -a log-install.txt
echo "resvis       (Reiniciar Service Dropbear, Webmin, Squid3, OpenVPN e SSH)"  | tee -a log-install.txt
echo "reboot       (Reiniciar VPS)"  | tee -a log-install.txt
echo "speedtest    (Speedtest VPS)"  | tee -a log-install.txt
echo "info         (Menampilkan Informasi Sistem)"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Fitur lain"  | tee -a log-install.txt
echo "----------"  | tee -a log-install.txt
echo "Webmin   : https://$MYIP:10000/"  | tee -a log-install.txt
echo "Timezone : America/Sao_Paulo (GMT -3)"  | tee -a log-install.txt
echo "IPv6     : [off]"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "Thanks To"  | tee -a log-install.txt
echo "---------"  | tee -a log-install.txt
echo "R3V1V3R 1NT3RN3T L1VR3"  | tee -a log-install.txt
echo "TheGrapevine "  | tee -a log-install.txt
echo "Google"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "----"  | tee -a log-install.txt
echo "https://t.me/tcpoverhttptunnel"  | tee -a log-install.txt
echo "@thegrapevine"  | tee -a log-install.txt
echo "K.A.G"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "VPS AUTO REBOOT SETIAP JAM 00.00 WIB"  | tee -a log-install.txt
echo "Log Installation --> /root/log-install.txt"  | tee -a log-install.txt
echo ""  | tee -a log-install.txt
echo "==========================================="  | tee -a log-install.txt
cd
rm -f /root/debian8.sh