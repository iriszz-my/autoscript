#!/bin/bash

while true; do
	data=(`ps aux | grep -i dropbear | awk '{print $2}'`);

	rm -f /tmp/dropbear-limit.txt
	touch /tmp/dropbear-limit.txt

	for PID in "${data[@]}"; do
		NUM=`cat /var/log/auth.log | grep -i dropbear | grep -i "Password auth succeeded" | grep "dropbear\[$PID\]" | wc -l`
		USER=`cat /var/log/auth.log | grep -i dropbear | grep -i "Password auth succeeded" | grep "dropbear\[$PID\]" | awk '{print $10}'`
		if [ $NUM -eq 1 ]; then
			echo -e "$USER\t$PID" | xargs >> /tmp/dropbear-limit.txt
		fi
	done

	cat /tmp/dropbear-limit.txt | awk '{print $1}' | sort | uniq -c > /tmp/user-list.txt

	while read login; do
		user=$(echo $login | awk '{print $2}')
		total=$(echo $login | awk '{print $1}')
		PID=$(cat /tmp/dropbear-limit.txt | grep -i $user | awk '{print $2}')

		if [[ $total -gt 1 ]]; then
			for (( c=1; c<$total; c++ )); do
				PID_kill=$(echo $PID | cut -d " " -f $c)
				kill $PID_kill
				echo -e "$(date +'%d/%m/%Y %T')\t${user}\t${PID_kill}" >> /root/script/multi-login.log
			done
		fi
	done < /tmp/user-list.txt

	sleep 10

	data=(`ps aux | grep -i dropbear | awk '{print $2}'`);

	rm -f /tmp/dropbear-limit.txt
	touch /tmp/dropbear-limit.txt

	for PID in "${data[@]}"; do
		NUM=`cat /var/log/auth.log | grep -i dropbear | grep -i "Password auth succeeded" | grep "dropbear\[$PID\]" | wc -l`
		USER=`cat /var/log/auth.log | grep -i dropbear | grep -i "Password auth succeeded" | grep "dropbear\[$PID\]" | awk '{print $10}'`
		if [ $NUM -eq 1 ]; then
			echo -e "$USER\t$PID" | xargs >> /tmp/dropbear-limit.txt
		fi
	done

	cat /tmp/dropbear-limit.txt | awk '{print $1}' | sort | uniq -c > /tmp/user-list.txt

	while read login; do
		user=$(echo $login | awk '{print $2}')
		total=$(echo $login | awk '{print $1}')
		PID=$(cat /tmp/dropbear-limit.txt | grep -i $user | awk '{print $2}')

		if [[ $total -gt 1 ]]; then
			passwd -l $user
			for (( c=1; c<=$total; c++ )); do
				PID_kill=$(echo $PID | cut -d " " -f $c)
				kill $PID_kill
				echo -e "$(date +'%d/%m/%Y %T')\t${user}\t${PID_kill}" >> /root/script/multi-login.log
			done
			echo -e "$(date +'%d/%m/%Y %T')\t${user}" >> /root/script/user-lock.log
		fi
	done < /tmp/user-list.txt

	sleep 60
done