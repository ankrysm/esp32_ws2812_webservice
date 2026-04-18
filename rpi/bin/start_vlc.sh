#!/bin/bash
#amixer -c 1 set PCM playback 100% > /tmp/rpi.desktop.log
amixer sset Master 66% >/tmp/rpi.desktop.log
while true; do
	cvlc -I http --pidfile /tmp/cvlc.pid  --http-port 8081 --http-password 1234  >> /tmp/rpi.desktop.log 2>&1
done
