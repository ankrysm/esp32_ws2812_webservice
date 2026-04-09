#set -x

CFG=/tmp/lightgttpd.conf
DOCROOT=$(pwd)/$(dirname $0)../html

#echo "DOCROOT=$DOCROOT"

# for WebDAV --------------------------------------------------
# needs: ./configure --with-webdav-props --with-webdav-locks
# get a file with curl -v  http://localhost:8081/dav/hallo.txt
# store file with curl -v -T /tmp/hallo.txt http://localhost:8081/dav/hallo2.txt 

# create config file
cat >$CFG  <<EOT
server.document-root = "$DOCROOT"
server.port = 8081

server.modules += (
	    "mod_indexfile",
	    "mod_webdav",
	    "mod_proxy",
        "mod_access",
        "mod_alias",
        "mod_setenv",
        "mod_redirect"
)


\$HTTP["url"] =^ "/files/" {
    alias.url = ("/files" => "$DOCROOT/files")
    dir-listing.activate = "enable" 
    webdav.activate = "enable" 
    #webdav.is-readonly = "disable" # (default)
    webdav.sqlite-db-name = "$DOCROOT/webdav.sqlite"
  }
  else \$HTTP["url"] == "/files" {
    url.redirect = ("" => "/files/")
    url.redirect-code = 308
  }
EOT

#nl -ba $CFG

LIGHTTPD=$HOME/git/lighttpd1.4/src/lighttpd

$LIGHTTPD -D -f $CFG