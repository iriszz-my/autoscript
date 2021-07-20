#!/bin/bash

today="$(date +%Y-%m-%d)"

while read expired
do
	account="$(echo $expired | cut -d: -f1)"
	ID="$(echo $expired | grep -v nobody | cut -d: -f3)"
	exp="$(chage -l $account | grep "Account expires" | awk -F": " '{print $2}')"
	if [[ $ID -ge 1000 ]]; then
		read mon day year <<< $exp
		exp_date="$(date -d "$mon $day $year" "+%Y-%m-%d")"
		if [[ $exp_date < $today ]]; then
			userdel $account
		fi
	fi
done < /etc/passwd