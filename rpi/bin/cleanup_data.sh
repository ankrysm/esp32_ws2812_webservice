#!/bin/bash
# removes the device-status files from the webdav directory.
# The devices will create new files if they are coming up
set -x
rm -f /var/www/html/files/device*

