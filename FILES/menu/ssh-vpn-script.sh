#!/bin/bash

function create-user() {
	clear
	echo -e ""
	read -p "Username : " login
	if getent passwd $login > /dev/null 2>&1; then
		echo ""
		echo "User '$login' already exist."
		echo ""
		exit 0
	fi
	read -p "Password : " pass
	read -p "Duration (day) : " expired
	useradd -e `date -d "$expired days" +"%Y-%m-%d"` -s /bin/false -M $login

	IP=$(wget -qO- ipv4.icanhazip.com)
	exp=$(date -d "$expired days" +"%d %b %Y")

	clear
	echo -e "$pass\n$pass\n"|passwd $login &> /dev/null
	echo -e ""
	echo -e "============================="
	echo -e "SSH & VPN Account Information"
	echo -e "-----------------------------"
	echo -e "Host: $IP"
	echo -e "Port Dropbear: 85"
	echo -e "Port Stunnel: 465"
	echo -e "Port Squid: 8080"
	echo -e "Port BadVPN-UDPGw: 7300"
	echo -e ""
	echo -e "Username: $login "
	echo -e "Password: $pass"
	echo -e "-----------------------------"
	echo -e "Expired date: $exp"
	echo -e "============================="
	echo -e ""
}

function delete-user() {
	clear
	echo -e ""
	read -p "Username : " login
	echo -e ""
	if getent passwd $login > /dev/null 2>&1; then
		userdel $login
		echo -e "User '$login' deleted successfully."
		echo -e ""
	else
		echo -e "User '$login' does not exist."
		echo -e ""
	fi
}

function user-monitor() {
	data=(`ps aux | grep -i dropbear | awk '{print $2}'`)
	clear
	echo -e ""
	echo -e "==========================="
	echo -e "Dropbear Login Monitor"
	echo -e "---------------------------"
	for PID in "${data[@]}"
	do
		NUM=`cat /var/log/auth.log | grep -i dropbear | grep -i "Password auth succeeded" | grep "dropbear\[$PID\]" | wc -l`
		USER=`cat /var/log/auth.log | grep -i dropbear | grep -i "Password auth succeeded" | grep "dropbear\[$PID\]" | awk '{print $10}'`
		IP=`cat /var/log/auth.log | grep -i dropbear | grep -i "Password auth succeeded" | grep "dropbear\[$PID\]" | awk '{print $12}'`
		if [ $NUM -eq 1 ]; then
			echo -e "$PID - $USER - $IP"
		fi
	done
	echo -e "==========================="
	echo -e ""
}

function user-list() {
	clear
	echo -e ""
	echo -e "==============================="
	echo -e "Username          Exp. Date"
	echo -e "-------------------------------"
	while read expired; do
		account=$(echo $expired | cut -d: -f1)
		ID=$(echo $expired | grep -v nobody | cut -d: -f3)
		exp=$(chage -l $account | grep "Account expires" | awk -F": " '{print $2}')
		read mon day year <<< $exp

		if [[ $ID -ge 1000 ]]; then
			exp_date=$(date -d "$mon $day $year" "+%d %b %Y")
			printf "%-17s %2s\n" "$account" "$exp_date"
		fi
	done < /etc/passwd
	total="$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd | wc -l)"
	echo -e "-------------------------------"
	echo -e "Total accounts : $total"
	echo -e "==============================="
	echo -e ""
}

function ovpn-config() {
	clear
	echo -e ""
	echo -e "[1]  Config TCP"
	echo -e "[2]  Config UDP"
	echo -e "[3]  Exit"
	echo -e ""
	until [[ ${MENU_OPTION} =~ ^[1-3]$ ]]; do
		read -rp "Select an option [1-3]: " MENU_OPTION
	done

	case "${MENU_OPTION}" in
	1)
		clear
		cat /root/ovpn-config/client-tcp.ovpn
		echo -e ""
		exit
		;;
	2)
		clear
		cat /root/ovpn-config/client-udp.ovpn
		echo -e ""
		exit
		;;
	3)
		clear
		exit 0
		;;
	esac
}

clear
echo -e ""
echo -e "[1]  Create user"
echo -e "[2]  Delete user"
echo -e "[3]  User monitor"
echo -e "[4]  User list"
echo -e "[5]  OVPN config"
echo -e "[6]  Exit"
echo -e ""
until [[ ${MENU_OPTION} =~ ^[1-6]$ ]]; do
	read -rp "Select an option [1-6]: " MENU_OPTION
done

case "${MENU_OPTION}" in
	1)
		create-user
		exit
		;;
	2)
		delete-user
		exit
		;;
	3)
		user-monitor
		exit
		;;
	4)
		user-list
		exit
		;;
	5)
		ovpn-config
		exit
		;;
	6)
		clear
		exit 0
		;;
esac