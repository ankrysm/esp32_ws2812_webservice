# Raspberry Pi as control unit

## Summary

A Raspberry Pi 3B+ and a capacitive touch display (Waveshare 4.3 Inch DSI LCD) form a control unit.

The software is a usual [Raspberry Pi OS](https://www.raspberrypi.com/software/) (tested with trixie) installed with the Raspbery Pi Imager. It is the version with the graphical interface.

It is useful to setup ssh access while creating the operating system.

## Hardware

### Display

The waveshare display has sometimes problems with a Raspberry Pi 3B+ [see here](https://www.waveshare.com/wiki/4.3inch_DSI_LCD). There&apos;s a lot of flickr on the display. It works with this `/boot/firmware/config.txt`:

	# For more options and information see
	# http://rptl.io/configtxt
	# Some settings may impact device functionality. See link above for details
	
	# Uncomment some or all of these to enable the optional hardware interfaces
	#dtparam=i2c_arm=on
	#dtparam=i2s=on
	#dtparam=spi=on
	
	# Enable audio (loads snd_bcm2835)
	dtparam=audio=on
	
	# Additional overlays and parameters are documented
	# /boot/firmware/overlays/README
	
	# Automatically load overlays for detected cameras
	camera_auto_detect=1
	
	# Automatically load overlays for detected DSI displays
	#display_auto_detect=1
	display_auto_detect=0
	
	# Automatically load initramfs files, if found
	auto_initramfs=1
	
	# Enable DRM VC4 V3D driver
	dtoverlay=vc4-kms-v3d
	max_framebuffers=2
	
	# Don't have the firmware create an initial video= setting in cmdline.txt.
	# Use the kernel's default instead.
	disable_fw_kms_setup=1
	
	# Run in 64-bit mode
	arm_64bit=1
	
	# Disable compensation for displays with overscan
	disable_overscan=1
	
	# Run as fast as firmware / board allows
	arm_boost=1
	
	[cm4]
	# Enable host mode on the 2711 built-in XHCI USB controller.
	# This line should be removed if the legacy DWC2 controller is required
	# (e.g. for USB device mode) or if USB support is not required.
	otg_mode=1
	
	[cm5]
	dtoverlay=dwc2,dr_mode=host
	
	[all]
	dtoverlay=vc4-kms-dsi-waveshare-800x480
	dtoverlay=imx708,rotation=0
	

## Software

## Requirements

The OS is build as a graphical interface. It is operated via a web browser.

To make it run create the following directories in the home directory:
* *bin* - some scripts are placed here
* *etc* - some config files, the config file for the web server
* *.config/autostart* - to run VLC and the browser while start up

see the README in the relevant directory.
   
### Webserver

We use [lighttpd](https://www.lighttpd.net) installed with `sudo apt-get install lighttpd`

It is started through the system daemon and the doc root is `/var/www/html`

Set permissions to the doc root

	sudo chown www-data:www-data /var/www/html
	sudo chmod g+w /var/www/html
	
add the main user to www-data group:

	sudo usermod -a -G www-data rpiuser
	
To to handle the data for the LED-strips the webserver uses webDAV. A separate module is used

	sudo apt-get install lighttpd-mod-webdav 
	
Create and set permissions on additional www directories

	sudo mkdir /var/www/html/files /var/www/html/assets /var/www/html/db
	sudo chown www-data:www-data /var/www/html/files /var/www/html/assets /var/www/html/db

To create the configuration for the lighttpd (proxies an webdav) start 

	$HOME/bin/create_proxy_config.sh

To use it:

	cd /etc/lighttpd/conf-enabled
	sudo ln -s $HOME/etc/99-the-controler.conf .

**Hint:** *It's not the best way to create the webserver configuration.* 

The content depends from the actual network address. If the network connection changed the webserver configuration becomes invalid if the network parameter changed. So you have to run the script again.

Restart webservice:

	sudo systemctl restart lighttpd
	


Hint:

The create_proxy_config.sh needs an established network connection. 
If it is changed the configuration becomes invalid.
	
## Browser

The chromium browser will be used.

To start a browser automatically create a file `browser.desktop` in `~/.config/autostart`with the content

	[Desktop Entry]
	Version=1.0
	Type=Application
	Name=chromium
	Comment=chromium for LED controller
	Exec=sh -c "\\$HOME/bin/start_browser.sh"

(for error check of the autostart file use `desktop-file-validate <file.desktop>`)

To handle the browser from a ssh login: `DISPLAY=:0 ~/bin/start_browser.sh`

The browser will start `http://localhost/index.html` in a private sesson to prevent message about an unsafe shutdown.

## Audio playback

I had a lot of trouble with the planned mpd/mpc software. I couldn&apos;t get it to work. So I decided to use the already installed VLC media player. There&apos;s a web interface so you can control it from a browser.

The playback volume (here for the headphone jack) can be set by 

	amixer -c 1 set PCM playback 100%

Check the amixer-parameter by `amixer -c 1 scontrols`  

It uses the VLC command line `cvlc`

First start a VLC instance as a daemon (there&apos;s only a password and no user):

	cvlc -I http --daemon --http-host localhost --http-port 8081 --http-password 1234

To do it automatically yoe ca create a autostart file to start `cvlc`when the GUI comes up.

Create a file `rpi.desktop` in `$HOME/.config/autostart` withe the content:

	[Desktop Entry]
	Version=1.0
	Type=Application
	Name=cvlc server
	Comment=vlc as deamon
	Exec=sh -c "\\$HOME/bin/start_vlc.sh"
	Icon=vlc

Here&apos;s the content of `start_vlc.sh` im `$HOME/bin`:

	#!/bin/bash
	amixer -c 1 set PCM playback 100% > /tmp/rpi.desktop.log
	while true; do
		cvlc -I http --pidfile /tmp/cvlc.pid  --http-port 8081 --http-password 1234  >> /tmp/rpi.desktop.log 2>&1
	done
	
Then you can use `curl` to control the playback. The whole informations [see here](https://code.videolan.org/videolan/vlc/-/tree/master/share/lua/http/requests)

You can communicate with the VLC with a HTTP request. If you use the suffix .json you get a JSON answer, if you use .xml you get XML data. It&apos;s nessessary to use a authentication with a password not with a user. 

THe basic URLs are
* `requests/status.json`
* `requests/playlist.json`

You can add parameters to the URL with `command=<command>` `id=<Id>` `input=<Input specification`

The input specification for file is `file:///<absolute path to the file>`

Here are some commands

### using status.json

* clear play list with `command=pl_empty`
* pause playback with `command=pl_pause`
* stop playback with `command=pl_stop`
* play file direct with `command=in_play&input=<input>`
* play something with id from playlist with `command=pl_play&id=<ID>`
* add item to the playlist with `command=in_enqueue&input=<input>`

### using playlist.json

* get playlist content 

### Examples

Get the playlist content

	curl --user :1234 http://localhost:8081/requests/playlist.json

Get the playing status

	curl --user :1234 http://localhost:8081/requests/status.json
	 
Play a file

	curl --user :1234 'http://localhost:8081/requests/status.json?command=in_play&input=file:////home/rpiuser/Music/music.mp3'
	
Stop playing

	curl --user :1234 'http://localhost:8081/requests/status.json?command=pl_stop'

## The hotspot

### First Attempt, doesn&apos;t work: Make the raspberry Pi a accesspoint

check the interfaces with `iw list` an `ip a`.

Seup access point:

see [here](https://raspberrytips.com/access-point-setup-raspberry-pi/)

	sudo nmcli con add con-name hotspot ifname wlan0 type wifi ssid "RPIL"
	sudo nmcli con modify hotspot wifi-sec.key-mgmt wpa-psk
	sudo nmcli con modify hotspot wifi-sec.psk "IlikeKobe"
	sudo nmcli con modify hotspot 802-11-wireless.mode ap 802-11-wireless.band bg ipv4.method shared
	sudo nmcli con modify hotspot autoconnect yes
	sudo nmcli con up hotspot

to edit the connection use `sudo nmtui`.

in `/etc/NetworkManager/dnsmasq.d` add file `redirect.conf` with the content

in `/etc/NetworkManager/NetworkManager.conf` add in main section `dns=dnsmasq`

	address=/#/10.42.0.1

**THIS DOESN&apos;T WORK !! esp32 doesn&apos;t connect to the raspberry pi!! it comes to an error 211 ...**

### Second attempt: Use an ESP32 as a simple NAT router - works, but uncomfortable 

So I use a separate ESP32 as an access point. It&apos;&apos;s build from the examples with som additions.

The accesspoint will be reached by SSID *TheControllerNet* wit PW *OutOfControl#1501*

To reach the internet configure it  with `./mk.sh menuconfig`

The rapsberry Pi will anounce some values over mDNS. To check this mechanism use the `avahi-browse` utility (on Mac `dns-sd -t 1 -G v4 rpi3b.local`)

Install it with `sudo apt-get install dnsutils avahi-utils`

**This work&apos;s but you cannot change the host network settings without a new software build**

### Third attempt: Use software from github


Use a software from [github](https://github.com/martin-ger/esp32_nat_router.git) with some modifications in the build process.

Set target to the right chip:

	idf-py set-target esp32


The configured parameter for the private WiFi are:

SSID=&quot;TheControllerNet&quot;

PASSWORD=&quot;OutOfControl#1501&quot;

**be aware that this software has some lack of security: passwords are displayed in plain text and plain text is used for the URL to set new access data.**

## Some other hints:

* check the chip temperature of the rapberry pi with `vcgencmd measure_temp`

* Accesspoint: Build from the accesspoint directory. 

* use this access data: User **TheControllerNet** with **OutOfControl#1501**

## Bring up the LED stripes

Connect the stripe controler with an USB cable and build the software for the LED stripes with

	./mk.sh erase-flash flash monitor

and wait for those messages in the serial line log

	I (8338) ./main/main.c: app_main: ******* wifi status=0x  10([CONNECTION: WAIT FOR][AP: STARTED])
	
At this moment an access point is started. Connect to the provided network with SSID **esp32**, password is **esp32pwd**. 

A capture window comes up, look for the desired network (*TheControlerNet*) and put in the password. A success message appeared after a click on **Join** and **OK**. 

After a few seconds the window will be closed. 


Get the IP address from the serial logging. The line to look for is

	I (388618) ./main/wifi_connect.c: **** cb_connection_ok: status=0x13, IP=192.168.4.5
	
Open a browser with this address and you get a website. 

Got to the setting tab and set the following parameter:

* **name** set it to *deviceX* with X = 1,2,3,4
* **number of leds** set to *300* or how many LEDs are in the strip.
* **loglevel serial interface** to 0 because serial logging needs time and is useless while nobody reads it
* **cycle time** set it to *50*
* **URL for status file** to *http://rpi3b.local/files*
* **mDNS host list** set to *rpi3b*

## Open the main website

The main website is reached over the mDNS resolver. If the raspberry pi has the name **rpi3b** the URL is **http://rpi3b.local**

## music files

get the duration of a mp3 or m4a file:

	ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 music3.m4a
	

