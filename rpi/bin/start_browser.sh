#!/bin/bash
DIR=$(dirname $0)
$DIR/cleanup_data.sh  >>/tmp/start_browser.log 2>&1

chromium --incognito http://localhost >>/tmp/start_browser.log 2>&1

#chromium --start-fullscreen --disable-session-crashed-bubble http://localhost
#chromium  --disable-session-crashed-bubble http://localhost
#chromium  --incognito http://localhost
#chromium  --kiosk --incognito http://localhost
#chromium --start-fullscreen --incognito http://localhost >>/tmp/start_browser.log 2>&1

