#!/bin/bash -e

FILES="index.html *.js *.css"
INDIR="./"

init() {
	cd $(dirname $0)
	trap 'echo -e "\npublish failed for $CURL_FTP_URL" >&2' ERR
	check_create_config || exit 0
}

check_create_config() {
	[ -f config ] && return 0
	cp config.sample config
	echo "created config from sample.  please edit."
	return 1
}

STEP() { printf "\r%-30s" "$1"; }

init

STEP "reading config"
source ./config

STEP "checking server"
if ! curl $CURL_FTP_URL/ &> /dev/null; then
	STEP "creating directories"
	echo -n | curl -s -T - --ftp-create-dirs $CURL_FTP_URL/.htaccess
fi

STEP "installing webapp"
( cd $INDIR
for f in $FILES; do
	STEP "installing $f"
	curl -s -T $f $CURL_FTP_URL/
done
)

STEP "installing manifest"
( cat << EOF 
CACHE MANIFEST
# $(date +'%F %T')
$(cd $INDIR; for f in $FILES; do echo $f; done)
NETWORK:
data/
*
EOF
) | curl -s -T - $CURL_FTP_URL/manifest.mf

STEP "installing .htaccess"
( cat << EOF 
ErrorDocument 404 "<html><script>location.replace('./')</script></html>"
AddDefaultCharset UTF-8
AddType text/cache-manifest .mf
EOF
) | curl -s -T - $CURL_FTP_URL/.htaccess

STEP "publishing done"
echo
