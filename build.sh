#!/bin/bash

declare -r NGINX_VERSION="1.13.9"
declare -r NGINX_URL="http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"

set -e
[[ $DEBUG ]] && set -x

ngx_tar=.cache/$(basename ${NGINX_URL})
ngx_dir=nginx-${NGINX_VERSION}

build_ngx_http_fetch_spiffe_certs_module() {
	mkdir -p /go/src/github.com/spiffe/ngx_http_fetch_spiffe_certs_module
	cp -R /opt/nginx-dev/ngx_http_fetch_spiffe_certs_module /go/src/github.com/spiffe/
	cd /go/src/github.com/spiffe/ngx_http_fetch_spiffe_certs_module
	make all
	mkdir -p /usr/local/nginx/logs
	cd /opt/nginx-dev
}

setup_nginx() {
	build_ngx_http_fetch_spiffe_certs_module
	mkdir -p /usr/local/nginx/html
	cp spiffe-support/index.html /usr/local/nginx/html

	mkdir -p .cache
	if [[ ! -r ${ngx_tar} ]]; then
		curl --progress-bar --location --output ${ngx_tar} ${NGINX_URL}
	fi
	if [[ ! -d ${ngx_dir} ]]; then
		tar -xzf ${ngx_tar}
	fi
	cp -rvp spiffe-support/* ${ngx_dir}
}

case $1 in
	configure)
		setup_nginx
		cd ${ngx_dir}
		set -x
		./configure $_config \
			--with-debug \
			--add-module=/go/src/github.com/spiffe/ngx_http_fetch_spiffe_certs_module \
			--with-http_ssl_module
		set +x
		;;
	make)
		set -x
		setup_nginx
		cd ${ngx_dir}
		make
		cp objs/nginx ..
		set +x
		;;
	clean)
		rm -rf ${ngx_dir}
		setup_nginx
		;;
esac
