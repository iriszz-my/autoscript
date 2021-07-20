#!/bin/bash

# Check root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root!"
   exit 1
fi

if [ "$(systemd-detect-virt)" == "openvz" ]; then
   echo "OpenVZ is not supported"
   exit 1
fi

# Get domain
read -rp "Please enter your domain (eg: voidvpn.iriszz.xyz) : " domain

# Update & Upgrade
apt-get update
apt-get upgrade -y

# Remove unused dependencies
apt-get autoremove -y

# Disable IPv6
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
sysctl -w net.ipv6.conf.lo.disable_ipv6=1
echo "net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1" >> /etc/sysctl.conf

# Set timezone
ln -sf /usr/share/zoneinfo/Asia/Kuala_Lumpur /etc/localtime

# Initialize variable
ipAddress=$(wget -qO- ipv4.icanhazip.com)

# Go to root directory
cd

# Install dependencies
apt-get install -y net-tools vnstat

# Install screenfetch
wget -qO /usr/bin/screenfetch "https://raw.githubusercontent.com/iriszz-my/autoscript/main/FILES/screenfetch.sh"
chmod +x /usr/bin/screenfetch
echo "clear" >> .profile
echo "screenfetch" >> .profile
echo "echo" >> .profile

# Configure SSH
echo "AllowUsers root" >> /etc/ssh/sshd_config
wget -qO /etc/ssh_issue.net "https://raw.githubusercontent.com/iriszz-my/autoscript/main/FILES/ssh_issue.net"
sed -i "s|#Banner none|Banner /etc/ssh_issue.net|g" /etc/ssh/sshd_config
service ssh restart

# Install Dropbear
apt-get install -y dropbear
sed -i "s|NO_START=1|NO_START=0|g" /etc/default/dropbear
sed -i "s|DROPBEAR_PORT=22|DROPBEAR_PORT=85|g" /etc/default/dropbear
echo "/bin/false" >> /etc/shells
wget -qO /etc/issue.net "https://raw.githubusercontent.com/iriszz-my/autoscript/main/FILES/issue.net"
sed -i "s|DROPBEAR_BANNER=""|DROPBEAR_BANNER="/etc/issue.net"|g" /etc/default/dropbear
service dropbear restart

# Install Stunnel
apt install stunnel4 -y
sed -i "s|ENABLED=0|ENABLED=1|g" /etc/default/stunnel4
openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -sha256 -subj "/CN=Iriszz/emailAddress=aimanamir.work@outlook.com/O=Void VPN/OU=Void VPN Premium/C=MY" -keyout /etc/stunnel/stunnel.pem -out /etc/stunnel/stunnel.pem
wget -qO /etc/stunnel/stunnel.conf "https://raw.githubusercontent.com/iriszz-my/autoscript/main/FILES/stunnel.conf"
service stunnel4 restart

# Install Squid3
apt-get install -y squid3
wget -qO /etc/squid/squid.conf "https://raw.githubusercontent.com/iriszz-my/autoscript/main/FILES/squid.conf"
sed -i "s/xx/${domain}/g" /etc/squid/squid.conf
sed -i "s|ipAddress|$ipAddress|g" /etc/squid/squid.conf
service squid restart

# Install Webmin
wget -q http://www.webmin.com/jcameron-key.asc
apt-key add jcameron-key.asc
echo "deb http://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list
apt-get update
apt-get install -y webmin
sed -i "s|ssl=1|ssl=0|g" /etc/webmin/miniserv.conf
rm jcameron-key.asc
service webmin restart

# Install fail2ban
apt-get install -y fail2ban
service fail2ban restart

# Install DDoS Deflate
apt install dnsutils tcpdump dsniff grepcidr -y
wget -qO ddos.zip "https://raw.githubusercontent.com/iriszz-my/autoscript/main/FILES/ddos-deflate.zip"
unzip ddos.zip
cd ddos-deflate
./install.sh
cd
rm -rf ddos.zip ddos-deflate

# Install Xray
apt install -y lsb-release gnupg2 wget lsof tar unzip curl libpcre3 libpcre3-dev zlib1g-dev openssl libssl-dev jq nginx
curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh | bash -s -- install
echo $domain >/usr/local/etc/xray/domain
wget -O /usr/local/etc/xray/config.json https://raw.githubusercontent.com/iriszz-my/autoscript/main/FILES/xray/xray_tls_ws_mix-rprx-direct.json
[ -z "$UUID" ] && UUID=$(cat /proc/sys/kernel/random/uuid)
cat /usr/local/etc/xray/config.json | jq 'setpath(["inbounds",0,"settings","clients",0,"id"];"'${UUID}'")' >/usr/local/etc/xray/config_tmp.json
mv -f /usr/local/etc/xray/config_tmp.json /usr/local/etc/xray/config.json
cat /usr/local/etc/xray/config.json | jq 'setpath(["inbounds",1,"settings","clients",0,"id"];"'${UUID}'")' >/usr/local/etc/xray/config_tmp.json
mv -f /usr/local/etc/xray/config_tmp.json /usr/local/etc/xray/config.json
cat /usr/local/etc/xray/config.json | jq 'setpath(["inbounds",0,"port"];'443')' >/usr/local/etc/xray/config_tmp.json
mv -f /usr/local/etc/xray/config_tmp.json /usr/local/etc/xray/config.json
cat /usr/local/etc/xray/config.json | jq 'setpath(["inbounds",0,"settings","fallbacks",2,"path"];"'/xray/'")' >/usr/local/etc/xray/config_tmp.json
mv -f /usr/local/etc/xray/config_tmp.json /usr/local/etc/xray/config.json
cat /usr/local/etc/xray/config.json | jq 'setpath(["inbounds",1,"streamSettings","wsSettings","path"];"'/xray/'")' >/usr/local/etc/xray/config_tmp.json
mv -f /usr/local/etc/xray/config_tmp.json /usr/local/etc/xray/config.json
wget -O /etc/nginx/conf.d/${domain}.conf https://raw.githubusercontent.com/iriszz-my/autoscript/main/FILES/xray/web.conf
sed -i "s/xxx/${domain}/g" /etc/nginx/conf.d/${domain}.conf
systemctl restart nginx
mkdir -p /www/xray_web
wget -O web.tar.gz https://raw.githubusercontent.com/iriszz-my/autoscript/main/FILES/web.tar.gz
tar xzf web.tar.gz -C /www/xray_web
rm -rf /var/www/html/*
tar xzf web.tar.gz -C /var/www/html
rm -f web.tar.gz
signedcert=$(xray tls cert -domain="$ipAddress" -name="$ipAddress" -org="$ipAddress" -expire=87600h)
echo $signedcert | jq '.certificate[]' | sed 's/\"//g' | tee /usr/local/etc/xray/self_signed_cert.pem
echo $signedcert | jq '.key[]' | sed 's/\"//g' >/usr/local/etc/xray/self_signed_key.pem
openssl x509 -in /usr/local/etc/xray/self_signed_cert.pem -noout
chown nobody.nogroup /usr/local/etc/xray/self_signed_cert.pem
chown nobody.nogroup /usr/local/etc/xray/self_signed_key.pem
mkdir /ssl
cp -a /usr/local/etc/xray/self_signed_cert.pem /ssl/xray.crt
cp -a /usr/local/etc/xray/self_signed_key.pem /ssl/xray.key
curl -L get.acme.sh | bash
"$HOME"/.acme.sh/acme.sh --set-default-ca --server letsencrypt
sed -i "6s/^/#/" "/etc/nginx/conf.d/${domain}.conf"
sed -i "6a\\\troot /www/xray_web/;" "/etc/nginx/conf.d/${domain}.conf"
systemctl restart nginx
"$HOME"/.acme.sh/acme.sh --issue -d "${domain}" --webroot "/www/xray_web/" -k ec-256 --force
"$HOME"/.acme.sh/acme.sh --installcert -d "${domain}" --fullchainpath /ssl/xray.crt --keypath /ssl/xray.key --reloadcmd "systemctl restart xray" --ecc --force
sed -i "7d" /etc/nginx/conf.d/${domain}.conf
sed -i "6s/#//" /etc/nginx/conf.d/${domain}.conf
chown -R nobody.nogroup /ssl/*
mkdir /root/script
touch /root/script/xray-clients.txt
echo -e "default\t${UUID}\t3000-01-01" >> /root/script/xray-clients.txt
systemctl restart nginx
systemctl restart xray

# Install OpenVPN
apt-get install -y openvpn
wget -q https://raw.githubusercontent.com/iriszz-my/autoscript/main/FILES/openvpn/EasyRSA-3.0.8.tgz
tar xvf EasyRSA-3.0.8.tgz
rm EasyRSA-3.0.8.tgz
mv EasyRSA-3.0.8 /etc/openvpn/easy-rsa
cp /etc/openvpn/easy-rsa/vars.example /etc/openvpn/easy-rsa/vars
sed -i 's|#set_var EASYRSA_REQ_COUNTRY\t"US"|set_var EASYRSA_REQ_COUNTRY\t"MY"|g' /etc/openvpn/easy-rsa/vars
sed -i 's|#set_var EASYRSA_REQ_PROVINCE\t"California"|set_var EASYRSA_REQ_PROVINCE\t"Kedah"|g' /etc/openvpn/easy-rsa/vars
sed -i 's|#set_var EASYRSA_REQ_CITY\t"San Francisco"|set_var EASYRSA_REQ_CITY\t"Bandar Baharu"|g' /etc/openvpn/easy-rsa/vars
sed -i 's|#set_var EASYRSA_REQ_ORG\t"Copyleft Certificate Co"|set_var EASYRSA_REQ_ORG\t\t"Void VPN"|g' /etc/openvpn/easy-rsa/vars
sed -i 's|#set_var EASYRSA_REQ_EMAIL\t"me@example.net"|set_var EASYRSA_REQ_EMAIL\t"aimanamir.work@outlook.com"|g' /etc/openvpn/easy-rsa/vars
sed -i 's|#set_var EASYRSA_REQ_OU\t\t"My Organizational Unit"|set_var EASYRSA_REQ_OU\t\t"Void VPN Premium"|g' /etc/openvpn/easy-rsa/vars
sed -i 's|#set_var EASYRSA_CA_EXPIRE\t3650|set_var EASYRSA_CA_EXPIRE\t3650|g' /etc/openvpn/easy-rsa/vars
sed -i 's|#set_var EASYRSA_CERT_EXPIRE\t825|set_var EASYRSA_CERT_EXPIRE\t3650|g' /etc/openvpn/easy-rsa/vars
cd /etc/openvpn/easy-rsa
./easyrsa --batch init-pki
./easyrsa --batch build-ca nopass
./easyrsa gen-dh
./easyrsa build-server-full server nopass
cd
mkdir /etc/openvpn/key
cp /etc/openvpn/easy-rsa/pki/issued/server.crt /etc/openvpn/key/
cp /etc/openvpn/easy-rsa/pki/ca.crt /etc/openvpn/key/
cp /etc/openvpn/easy-rsa/pki/dh.pem /etc/openvpn/key/
cp /etc/openvpn/easy-rsa/pki/private/server.key /etc/openvpn/key/
wget -qO /etc/openvpn/server-udp.conf "https://raw.githubusercontent.com/iriszz-my/autoscript/main/FILES/openvpn/server-udp.conf"
wget -qO /etc/openvpn/server-tcp.conf "https://raw.githubusercontent.com/iriszz-my/autoscript/main/FILES/openvpn/server-tcp.conf"
sed -i "s|#AUTOSTART="all"|AUTOSTART="all"|g" /etc/default/openvpn
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
systemctl start openvpn@server-udp
systemctl start openvpn@server-tcp
systemctl enable openvpn@server-udp
systemctl enable openvpn@server-tcp

# Configure OpenVPN client configuration
mkdir /root/ovpn-config
wget -qO /root/ovpn-config/client-udp.ovpn "https://raw.githubusercontent.com/iriszz-my/autoscript/main/FILES/openvpn/client-udp.ovpn"
wget -qO /root/ovpn-config/client-tcp.ovpn "https://raw.githubusercontent.com/iriszz-my/autoscript/main/FILES/openvpn/client-tcp.ovpn"
sed -i "s|xxx.xxx.xxx.xxx|$ipAddress|g" /root/ovpn-config/client-udp.ovpn
sed -i "s|xxx.xxx.xxx.xxx|$ipAddress|g" /root/ovpn-config/client-tcp.ovpn
echo "" >> /root/ovpn-config/client-tcp.ovpn
echo "<ca>" >> /root/ovpn-config/client-tcp.ovpn
cat "/etc/openvpn/key/ca.crt" >> /root/ovpn-config/client-tcp.ovpn
echo "</ca>" >> /root/ovpn-config/client-tcp.ovpn
echo "" >> /root/ovpn-config/client-udp.ovpn
echo "<ca>" >> /root/ovpn-config/client-udp.ovpn
cat "/etc/openvpn/key/ca.crt" >> /root/ovpn-config/client-udp.ovpn
echo "</ca>" >> /root/ovpn-config/client-udp.ovpn

# Install WireGuard
apt-get install -y wireguard iptables resolvconf qrencode
mkdir /etc/wireguard >/dev/null 2>&1
chmod 600 -R /etc/wireguard/
SERVER_PRIV_KEY=$(wg genkey)
SERVER_PUB_KEY=$(echo "${SERVER_PRIV_KEY}" | wg pubkey)
echo "SERVER_PUB_IP=$ipAddress
SERVER_PUB_NIC=eth0
SERVER_WG_NIC=wg0
SERVER_WG_IPV4=10.66.66.1
SERVER_PORT=51820
SERVER_PRIV_KEY=${SERVER_PRIV_KEY}
SERVER_PUB_KEY=${SERVER_PUB_KEY}
CLIENT_DNS_1=8.8.8.8
CLIENT_DNS_2=8.8.4.4" >/etc/wireguard/params
source /etc/wireguard/params
echo "[Interface]
Address = ${SERVER_WG_IPV4}/24
ListenPort = ${SERVER_PORT}
PrivateKey = ${SERVER_PRIV_KEY}" >"/etc/wireguard/${SERVER_WG_NIC}.conf"
echo "PostUp = iptables -A FORWARD -i ${SERVER_PUB_NIC} -o ${SERVER_WG_NIC} -j ACCEPT; iptables -A FORWARD -i ${SERVER_WG_NIC} -j ACCEPT; iptables -t nat -A POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE
PostDown = iptables -D FORWARD -i ${SERVER_PUB_NIC} -o ${SERVER_WG_NIC} -j ACCEPT; iptables -D FORWARD -i ${SERVER_WG_NIC} -j ACCEPT; iptables -t nat -D POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE" >>"/etc/wireguard/${SERVER_WG_NIC}.conf"
echo "net.ipv4.ip_forward = 1" >/etc/sysctl.d/wg.conf
sysctl --system
systemctl start "wg-quick@${SERVER_WG_NIC}"
systemctl enable "wg-quick@${SERVER_WG_NIC}"
mkdir /root/wg-config

# Install BadVPN UDPGw
cd
apt-get install -y cmake
wget -q https://raw.githubusercontent.com/iriszz-my/autoscript/main/FILES/badvpn.zip
unzip badvpn.zip
cd badvpn-master
mkdir build-badvpn
cd build-badvpn
cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1
make install
cd
rm -r badvpn-master
rm badvpn.zip
screen -AmdS badvpn badvpn-udpgw --listen-addr 127.0.0.1:7300

# Install Speedtest cli
curl -s https://install.speedtest.net/app/cli/install.deb.sh | bash
apt-get install speedtest

# Configure UFW
apt-get install -y ufw
echo "" >> /etc/ufw/before.rules
echo "# START OPENVPN RULES" >> /etc/ufw/before.rules
echo "# NAT table rules" >> /etc/ufw/before.rules
echo "*nat" >> /etc/ufw/before.rules
echo ":POSTROUTING ACCEPT [0:0]" >> /etc/ufw/before.rules
echo "# Allow traffic from OpenVPN client to eth0" >> /etc/ufw/before.rules
echo "-I POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE" >> /etc/ufw/before.rules
echo "-I POSTROUTING -s 10.9.0.0/24 -o eth0 -j MASQUERADE" >> /etc/ufw/before.rules
echo "COMMIT" >> /etc/ufw/before.rules
echo "# END OPENVPN RULES" >> /etc/ufw/before.rules
sed -i 's|DEFAULT_FORWARD_POLICY="DROP"|DEFAULT_FORWARD_POLICY="ACCEPT"|g' /etc/default/ufw
sed -i "s|IPV6=yes|IPV6=no|g" /etc/default/ufw
ufw allow 22
ufw allow 1194
ufw allow 80
ufw allow 443
ufw allow 465
ufw allow 8080
ufw allow 51820
ufw allow 85
ufw allow 7300
ufw allow 10000
ufw disable
echo "y" | ufw enable
ufw reload

# Configure rc.local
wget -qO /etc/rc.local "https://raw.githubusercontent.com/iriszz-my/autoscript/main/FILES/rc.local"
chmod +x /etc/rc.local

# Configure script
wget -qO /usr/bin/menu "https://raw.githubusercontent.com/iriszz-my/autoscript/main/FILES/menu/menu.sh"
wget -qO /usr/bin/ssh-vpn-script "https://raw.githubusercontent.com/iriszz-my/autoscript/main/FILES/menu/ssh-vpn-script.sh"
wget -qO /usr/bin/wireguard-script "https://raw.githubusercontent.com/iriszz-my/autoscript/main/FILES/menu/wireguard-script.sh"
wget -qO /usr/bin/xray-script "https://raw.githubusercontent.com/iriszz-my/autoscript/main/FILES/menu/xray-script.sh"
wget -qO /usr/bin/other-script "https://raw.githubusercontent.com/iriszz-my/autoscript/main/FILES/menu/other-script.sh"
wget -qO /usr/bin/dropbear-user-limit "https://raw.githubusercontent.com/iriszz-my/autoscript/main/FILES/cron/dropbear-user-limit.sh"
wget -qO /usr/bin/ssh-vpn-delete-expired "https://raw.githubusercontent.com/iriszz-my/autoscript/main/FILES/cron/ssh-vpn-delete-expired.sh"
wget -qO /usr/bin/xray-delete-expired "https://raw.githubusercontent.com/iriszz-my/autoscript/main/FILES/cron/xray-delete-expired.sh"
chmod +x /usr/bin/{menu,ssh-vpn-script,wireguard-script,xray-script,other-script,dropbear-user-limit,ssh-vpn-delete-expired,xray-delete-expired}

# COnfigure lock Dropbear multi-login
wget -qO /etc/systemd/system/dropbear-user-limit.service "https://raw.githubusercontent.com/iriszz-my/autoscript/main/FILES/dropbear-user-limit.service"
systemctl daemon-reload
service dropbear-user-limit restart
systemctl enable dropbear-user-limit.service
touch /root/script/{multi-login.log,user-lock.log}

# Configure crontab
echo "0 0 * * * root reboot" >> /etc/crontab
echo "55 23 * * * root xray-delete-expired" >> /etc/crontab

# Print script info
clear
echo -e ""
echo -e "IPv6 : [OFF]"
echo -e "Timezone : [Asia/Kuala_Lumpur]"
echo -e "UFW : [ON]"
echo -e "Reboot : [12 AM]"
echo -e ""
echo -e "Port OpenSSH : [22]"
echo -e "Port Dropbear : [85]"
echo -e "Port Stunnel : [465]"
echo -e "Port Squid : [8080]"
echo -e "Port OpenVPN : [1194]"
echo -e "Port Xray : [443]"
echo -e "Port BadVPN-UDPGw : [7300]"
echo -e "Port Nginx : [80]"
echo -e "Port WireGuard : [5182]"
echo -e ""
echo -e "Webmin : http://$ipAddress:10000/"
echo -e ""

# Cleanup and reboot
read -n 1 -r -s -p $'Press enter to reboot...\n'
rm -f /root/autoscript.sh
cp /dev/null /root/.bash_history
reboot