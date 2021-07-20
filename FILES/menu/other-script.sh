#!/bin/bash

ipAddress=$(wget -qO- ipv4.icanhazip.com)

function multi-login() {
	clear
	cat /root/script/multi-login.log
	echo ""
}

function locked-user() {
	clear
	cat /root/script/user-lock.log
	echo ""
}

function clear-log() {
	rm -f /root/script/{multi-login.log,user-lock.log}
	touch /root/script/{multi-login.log,user-lock.log}
	clear
	echo ""
	echo "Log cleared."
	echo ""
}

function xray-log() {
	clear
	tail -f /var/log/xray/access.log
}

function renew-stunnel() {
	clear
	openssl req -new -newkey rsa:2048 -days 3650 -nodes -x509 -sha256 -subj "/CN=Iriszz/emailAddress=aimanamir.work@outlook.com/O=Void VPN/OU=Void VPN Premium/C=MY" -keyout /etc/stunnel/stunnel.pem -out /etc/stunnel/stunnel.pem
	clear
	echo -e ""
	echo -e "Stunnel4 certificate has been renewed successfully."
	echo -e ""
}

function renew-openvpn() {
	clear
	wget -q https://raw.githubusercontent.com/iriszz-my/autoscript/main/FILES/openvpn/EasyRSA-3.0.8.tgz
	tar xvf EasyRSA-3.0.8.tgz
	rm EasyRSA-3.0.8.tgz
	rm -rf /etc/openvpn/easy-rsa && mv EasyRSA-3.0.8 /etc/openvpn/easy-rsa
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
	rm -rf /etc/openvpn/key && mkdir /etc/openvpn/key
	cp /etc/openvpn/easy-rsa/pki/issued/server.crt /etc/openvpn/key/
	cp /etc/openvpn/easy-rsa/pki/ca.crt /etc/openvpn/key/
	cp /etc/openvpn/easy-rsa/pki/dh.pem /etc/openvpn/key/
	cp /etc/openvpn/easy-rsa/pki/private/server.key /etc/openvpn/key/
	rm -f /root/ovpn-config/{client-udp.ovpn,client-tcp.ovpn}
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
	systemctl restart openvpn@server-udp
	systemctl restart openvpn@server-tcp
	clear
	echo -e ""
	echo -e "OpenVPN certificate has been renewed successfully."
	echo -e ""
}

function renew-xray() {
	clear
	signedcert=$(xray tls cert -domain="$ipAddress" -name="$ipAddress" -org="$ipAddress" -expire=87600h)
	echo $signedcert | jq '.certificate[]' | sed 's/\"//g' | tee /usr/local/etc/xray/self_signed_cert.pem
	echo $signedcert | jq '.key[]' | sed 's/\"//g' >/usr/local/etc/xray/self_signed_key.pem
	openssl x509 -in /usr/local/etc/xray/self_signed_cert.pem -noout
	"/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh"
	systemctl restart nginx
	systemctl restart xray
	clear
	echo -e ""
	echo -e "Xray certificate has been renewed successfully."
	echo -e ""
}

function info-script() {
	clear
	echo -e ""
	echo -e "This script is written by Iriszz."
	echo -e "Please report any encountered bug to me in Telegram, @iriszz."
	echo -e ""
}

clear
echo -e ""
echo -e "[1]  Dropbear multi-login log"
echo -e "[2]  Dropbear locked user log"
echo -e "[3]  Clear Dropbear user limit log"
echo -e "[4]  Show Xray real-time access log"
echo -e "[5]  Renew Stunnel4 certificate"
echo -e "[6]  Renew OpenVPN certificate"
echo -e "[7]  Renew Xray certificate (SSL)"
echo -e "[8]  Script info"
echo -e "[9]  Exit"
echo -e ""
until [[ ${MENU_OPTION} =~ ^[1-9]$ ]]; do
	read -rp "Select an option [1-9]: " MENU_OPTION
done

case "${MENU_OPTION}" in
	1)
		multi-login
		exit
		;;
	2)
		locked-user
		exit
		;;
	3)
		clear-log
		exit
		;;
	4)
		xray-log
		exit
		;;
	5)
		renew-stunnel
		exit
		;;
	6)
		renew-openvpn
		exit
		;;
	7)
		renew-xray
		exit
		;;
	8)
		script-info
		exit
		;;
	9)
		clear
		exit 0
		;;
esac