#!/bin/bash

apt update
apt upgrade -y

today="$(date -d"+1 day" +%Y-%m-%d)"

while read expired
do
	user="$(echo $expired | awk '{print $1}')"
	UUID="$(echo $expired | awk '{print $2}')"
	exp="$(echo $expired | awk '{print $3}')"

	if [[ $exp < $today ]]; then
		cat /usr/local/etc/xray/config.json | jq 'del(.inbounds[0].settings.clients[] | select(.id == "'${UUID}'"))' >/usr/local/etc/xray/config_tmp.json
		mv -f /usr/local/etc/xray/config_tmp.json /usr/local/etc/xray/config.json
		cat /usr/local/etc/xray/config.json | jq 'del(.inbounds[1].settings.clients[] | select(.id == "'${UUID}'"))' >/usr/local/etc/xray/config_tmp.json
		mv -f /usr/local/etc/xray/config_tmp.json /usr/local/etc/xray/config.json
		sed -i "/\b$user\b/d" /root/script/xray-clients.txt
	fi
done < /root/script/xray-clients.txt