#!/bin/bash

PORT=$(cat /usr/local/etc/xray/config.json | jq .inbounds[0].port)
FLOW=$(cat /usr/local/etc/xray/config.json | jq .inbounds[0].settings.clients[0].flow | tr -d '"')
WS_PATH=$(cat /usr/local/etc/xray/config.json | jq .inbounds[0].settings.fallbacks[2].path | tr -d '"')
WS_PATH_WITHOUT_SLASH=$(echo $WS_PATH | tr -d '/')
DOMAIN=$(cat /usr/local/etc/xray/domain)

function create-user() {
	clear
	echo -e ""
	read -p "Username : " user
	if grep -qw "$user" /root/script/xray-clients.txt; then
		echo -e ""
		echo -e "User '$user' already exist."
		echo -e ""
		exit 0
	fi
	read -p "Duration (day) : " expired

	UUID=$(uuidgen)
	exp=$(date -d "$expired days" +"%Y-%m-%d")
	exp_date="$(date -d"${exp}" "+%d %b %Y")"
	echo -e "${user}\t${UUID}\t${exp}" >> /root/script/xray-clients.txt

	cat /usr/local/etc/xray/config.json | jq '.inbounds[0].settings.clients += [{"id": "'${UUID}'","flow": "xtls-rprx-direct"}]' >/usr/local/etc/xray/config_tmp.json
	mv -f /usr/local/etc/xray/config_tmp.json /usr/local/etc/xray/config.json
	cat /usr/local/etc/xray/config.json | jq '.inbounds[1].settings.clients += [{"id": "'${UUID}'"}]' >/usr/local/etc/xray/config_tmp.json
	mv -f /usr/local/etc/xray/config_tmp.json /usr/local/etc/xray/config.json
	service xray restart

	clear
	echo -e ""
	echo -e "========================"
	echo -e "XRay Account Information"
	echo -e "------------------------"
	echo -e ""
	echo -e "Username     : $user "
	echo -e "Expired date : $exp_date"
	echo -e ""
	echo -e "========================"
	echo -e ""
}

function delete-user() {
	clear
	echo -e ""
	read -p "Username : " user
	echo -e ""
	if ! grep -qw "$user" /root/script/xray-clients.txt; then
		echo -e ""
		echo -e "User '$user' does not exist."
		echo -e ""
		exit 0
	fi
	UUID="$(cat /root/script/xray-clients.txt | grep -w "$user" | awk '{print $2}')"

	cat /usr/local/etc/xray/config.json | jq 'del(.inbounds[0].settings.clients[] | select(.id == "'${UUID}'"))' >/usr/local/etc/xray/config_tmp.json
	mv -f /usr/local/etc/xray/config_tmp.json /usr/local/etc/xray/config.json
	cat /usr/local/etc/xray/config.json | jq 'del(.inbounds[1].settings.clients[] | select(.id == "'${UUID}'"))' >/usr/local/etc/xray/config_tmp.json
	mv -f /usr/local/etc/xray/config_tmp.json /usr/local/etc/xray/config.json
	sed -i "/\b$user\b/d" /root/script/xray-clients.txt
	service xray restart

	echo -e "User '$user' deleted successfully."
	echo -e ""
}

function user-list() {
	clear
	echo -e ""
	echo -e "==============================="
	echo -e "Username          Exp. Date"
	echo -e "-------------------------------"
	while read expired
	do
		account="$(echo $expired | awk '{print $1}')"
		exp="$(echo $expired | awk '{print $3}')"
		exp_date="$(date -d"${exp}" "+%d %b %Y")"
		printf "%-17s %2s\n" "$account" "$exp_date"
	done < /root/script/xray-clients.txt
	total="$(wc -l /root/script/xray-clients.txt | awk '{print $1}')"
	echo -e "-------------------------------"
	echo -e "Total accounts: $total"
	echo -e "==============================="
	echo -e ""
}

function show-config() {
	echo -e ""
	read -p "Username : " user
	if ! grep -qw "$user" /root/script/xray-clients.txt; then
		echo -e ""
		echo -e "User '$user' does not exist."
		echo -e ""
		exit 0
	fi
	UUID="$(cat /root/script/xray-clients.txt | grep -w "$user" | awk '{print $2}')"

	clear
	echo -e ""
	echo -e "Xray Configuration for '$user'"
	echo -e "==============================="
	echo -e "( VLESS + WebSocket + TLS )"
	echo -e "Host: $DOMAIN"
	echo -e "Server Port: $PORT"
	echo -e "User ID: $UUID"
	echo -e "Security: none"
	echo -e "Network Type: ws"
	echo -e "WebSocket Path: $WS_PATH"
	echo -e "TLS: tls"
	echo -e ""
	echo -e "( VLESS + TLS / XTLS )"
	echo -e "Adress: $DOMAIN"
	echo -e "Port: $PORT"
	echo -e "ID: $UUID"
	echo -e "Flow: $FLOW"
	echo -e "Encryption: none"
	echo -e "Network: tcp"
	echo -e "Head Type: none"
	echo -e "TLS: tls / xtls"
	echo -e ""
	echo -e "Link:"
	echo -e "-----"
	echo -e "( VLESS + TCP + TLS )"
	echo -e "vless://$UUID@$DOMAIN:$PORT?security=tls#TLS-$DOMAIN"
	echo -e ""
	echo -e "( VLESS + TCP + XTLS )"
	echo -e "vless://$UUID@$DOMAIN:$PORT?security=xtls&flow=$FLOW#XTLS-$DOMAIN"
	echo -e ""
	echo -e "( VLESS + WebSocket + TLS )"
	echo -e "vless://$UUID@$DOMAIN:$PORT?type=ws&security=tls&path=%2f${WS_PATH_WITHOUT_SLASH}%2f#WS_TLS-$DOMAIN"
	echo -e ""
	echo -e "QR code:"
	echo -e "--------"
	echo -e "( VLESS + TCP + TLS )"
	echo -e "https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=vless://$UUID@$DOMAIN:$PORT?security=tls%23TLS-$DOMAIN"
	echo -e ""
	echo -e "( VLESS + TCP + XTLS )"
	echo -e "https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=vless://$UUID@$DOMAIN:$PORT?security=xtls%26flow=$FLOW%23XTLS-$DOMAIN"
	echo -e ""
	echo -e "( VLESS + WebSocket + TLS )"
	echo -e "https://api.qrserver.com/v1/create-qr-code/?size=400x400&data=vless://$UUID@$DOMAIN:$PORT?type=ws%26security=tls%26path=%2f${WS_PATH_WITHOUT_SLASH}%2f%23WS_TLS-$DOMAIN"
	echo -e ""
}

clear
echo -e ""
echo -e "[1]  Create Xray user"
echo -e "[2]  Delete Xray user"
echo -e "[3]  Xray user list"
echo -e "[4]  Show Xray configuration"
echo -e "[5]  Exit"
echo -e ""
until [[ ${MENU_OPTION} =~ ^[1-5]$ ]]; do
	read -rp "Select an option [1-5]: " MENU_OPTION
done
case "${MENU_OPTION}" in
1)
	create-user
	;;
2)
	delete-user
	;;
3)
	user-list
	;;
4)
	clear
	show-config
	;;
5)
	clear
	exit 0
	;;
esac
