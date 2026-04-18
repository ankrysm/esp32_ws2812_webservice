#!/bin/bash
# check for led devices by checking a web service on a 'cfg/get' URL

# address range 
ADRMIN=1
ADRMAX=254

BASEADR=$( ip a | grep wlan0$ | awk '{gsub(/\.[0-9]+\/.*$/,".",$2); print $2}' )
ITSME=$( ip a | grep wlan0$ | awk '{gsub(/\/.*$/,"",$2); print $2}' )

check_ip() {
	ADDR=$(echo ${BASEADR}$1)
	if [[ $ADDR = $ITSME ]]
	then
		echo "$ADDR it's me"
		return
	fi
	#echo $ADDR

	STSCODE=$(curl  --connect-timeout 1 -s -w "%{http_code}" -o /tmp/response  $ADDR/cfg/get && echo)

	if [[ $STSCODE = "200" ]]
	then 
		echo "$ADDR FOUND"
		cat /tmp/response
	else 
		echo "$ADDR not a LED strip"
	fi 
}

for i in $(seq $ADRMIN $ADRMAX)
do
	check_ip $i
done
