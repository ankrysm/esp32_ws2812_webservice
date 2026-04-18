#!/bin/bash

DIR=$(dirname $0)

# map the device adresses to the '/device/nnn' address
makeproxy() {
	
	# detect the network base address
	NETW=$( ip a | grep wlan0$ | awk '{gsub(/\.[0-9]+\/.*$/,".",$2); print $2}')
	
	typeset -i ADRMIN=1
	typeset -i ADRMAX=254
	
	echo '# for LED strips --------------------------------------------------'
	echo '$HTTP["url"] =~ "^/device/[0-9]+/" {'
	echo '    proxy.header = ('
    echo '      "map-urlpath" => ('
     
	for i in $(seq $ADRMIN $ADRMAX)
	do 
		echo '     	"/device/'$i'/" => "/",' 
	done
	echo '      ),'
	echo '   )'
 
    echo 'proxy.server = (' 
	
	for i in $(seq $ADRMIN $ADRMAX)
	do 
		echo '     	"/device/'$i'/" => (( "host" => "'${NETW}${i}'", "port" => "80" )),'
	done
    
    echo '   )'
  	echo '}'
	
}

CFG=$HOME/etc/99-the-controler.conf

echo "# created by create_proxy_config.sh at "$(date)  >$CFG
cat $HOME/etc/thecontroler_static.conf >>$CFG

makeproxy >>$CFG

exit 0

