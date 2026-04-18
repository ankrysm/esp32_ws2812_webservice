# Scripts for application start


## cleanup_data.sh

Removes the device-status files from the webdav directory. 

The devices will create new files if they are coming up.

The script is called when the browser starts

## create_proxy_config.sh

It creates a config file `$HOME/etc/99-the-controler.conf` to use it as a configuration for the **lighttpd** server. 

The script must be executed at first start or when the network parameters changed.
	
## thecontroler_static.conf

This file will be included into the webserver configuration when `create_proxy_config.sh` is run.
	
## start_browser.sh

This scripts starts a chromium browser with the main website in a private tab.

It is called when the graphical desktop is initialized.

## start_vlc.sh

The script 
* set the volume of the output with an `amixer` call. 
* starts a VLC player with a web interface and keeps it running with a loop

It is called when the graphical desktop is initialized.

## findstrips.sh

Utility for finding LED devices by checking an URL.

