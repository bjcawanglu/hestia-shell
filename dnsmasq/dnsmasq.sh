#! /bin/bash

###
# TODO: The introduction of this shell.
# Author: rmfish@163.com
# Date: 20150811
# Version: 1
###

USER=`whoami`
BASH_NAME=$(basename $BASH_SOURCE)
APP_TARGET=/home/admin/work/www/dnsmasq-api
DNSMASQ_API_REPO=git://github.com/bpaquet/dnsmasq-rest-api.git
NGINX_APP_CONF=/usr/local/nginx/conf/apps

_current_path() {
    SOURCE=${BASH_SOURCE[0]}
    DIR=$( dirname "$SOURCE" )
    while [ -h "$SOURCE" ]
    do
        SOURCE=$(readlink "$SOURCE")
        [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
        DIR=$( cd -P "$( dirname "$SOURCE"  )" && pwd )
    done
    DIR=$( cd -P "$( dirname "$SOURCE" )" && pwd )
    echo $DIR
}

BASH_DIR=$(_current_path)

if [ $USER != "root" ];then
	echo -e '\033[31m This command shoud run as administrator (user "root"), use "sudo '${BASH_NAME}'" please! \033[0m'
    exit
fi

DNSMASQ_ZONES_DIR=awk -F= '{print $2}' $BASH_DIR/conf/dnsmasq-d.conf

mkdir -p $DNSMASQ_ZONES_DIR
chown -R admin $DNSMASQ_ZONES_DIR

echo "Installing dnsmasq-rest-api to $APP_TARGET."

[ -d $APP_TARGET  ] || git clone git://github.com/bpaquet/dnsmasq-rest-api.git $APP_TARGET

echo "Configuring dnsmasq."

cp $BASH_DIR/conf/dnsmasq-d.conf /etc/dnsmasq.d/dnsmasq-api.conf
service dnsmasq restart

echo "Allow dnsmasq-rest-api to send signal to dnsmasq"

cp $BASH_DIR/conf/dnsmasq-sudoers /etc/sudoers.d/dnsmasq
chmod 0440 /etc/sudoers.d/dnsmasq

echo "Configuring nginx"

cp $BASH_DIR/conf/dnsmasq-nginx.conf $NGINX_APP_CONF/dnsmasq-api.conf
service nginx restart
