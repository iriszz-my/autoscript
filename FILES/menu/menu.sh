#!/bin/bash

clear
echo -e ""
echo -e "[1]  SSH & VPN"
echo -e "[2]  Xray"
echo -e "[3]  WireGuard"
echo -e "[4]  Speedtest"
echo -e "[5]  Benchmark"
echo -e "[6]  Other"
echo -e "[7]  Exit"
echo -e ""
until [[ ${MENU_OPTION} =~ ^[1-7]$ ]]; do
	read -rp "Select an option [1-7]: " MENU_OPTION
done

case "${MENU_OPTION}" in
	1)
		ssh-vpn-script
		exit
		;;
	2)
		xray-script
		exit
		;;
	3)
		wireguard-script
		exit
		;;
	4)
		clear
		speedtest
		echo -e ""
		exit
		;;
	5)
		clear
		echo -e ""
		wget -qO- wget.racing/nench.sh | bash
		exit
		;;
	6)
		other-script
		exit
		;;
	7)
		clear
		exit 0
		;;
esac