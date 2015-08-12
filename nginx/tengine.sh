#! /bin/bash

###
# TODO: The introduction of this shell.
# Author: rmfish@163.com
# Date: 20150811
# Version: 1
###

USER=`whoami`
BASH_NAME=$(basename $BASH_SOURCE)

echo "This is a template shell, created by rmfish."

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

echo  -e '\033[32m CurrentShell is: '$BASH_DIR/$BASH_NAME' \033[0m'

if [ $USER != "root" ];then
        echo -e '\033[31m This command shoud run as administrator (user "root"), use "sudo '${BASH_NAME}'" please! \033[0m'
    exit
fi

echo -e "\033[32m Install the required libs. \033[0m"
echo -e "\033[32m Update source. \033[0m"
#apt-get -qq update
for packages in gcc g++ make wget libpcre3 libpcre3-dev libpcrecpp0 openssl libcurl4-openssl-dev;
do 
	echo -e "\033[32m Install $packages. \033[0m"
	apt-get install -qq -y  $packages --force-yes;
	#apt-get -fy -qq instaddll;
	#apt-get -y -qq autoremove;
done
#apt-get -y -q install gcc g++ make wget libpcre3 libpcre3-dev libpcrecpp0 openssl libcurl4-openssl-dev


INSTALLER_DIR=/opt/installer
TENGINE_NAME=tengine
TENGINE_VERSION=2.1.0
TENGINE_FILE=${TENGINE_NAME}-${TENGINE_VERSION}
TENGINE_TGZ=${TENGINE_FILE}.tar.gz
TENGINE_URL=http://tengine.taobao.org/download/${TENGINE_TGZ}
TENGINE_PREFIX_DIR=/usr/local/nginx

# the tengine is installed.
echo -e "\033[32m Install the tengine[$TENGINE_VERSION]. \033[0m"
if [ ! -d $TENGINE_PREFIX_DIR ]; then
	# the tengine dir is not exist.
	if [ ! -d $INSTALLER_DIR/$TENGINE_FILE ]; then
		# the tengine tgz file is not exist
		if [ ! -f $INSTALLER_DIR/$TENGINE_TGZ ]; then
			echo "Download tengine from ${TENGINE_URL}:"
			wget -O $INSTALLER_DIR/$TENGINE_TGZ $TENGINE_URL;
		fi
		tar zxf $INSTALLER_DIR/$TENGINE_TGZ -C $INSTALLER_DIR
	fi

	cd $INSTALLER_DIR/$TENGINE_FILE

	echo -e "\033[33m Install tengine: \033[0m"
	./configure --prefix=${TENGINE_PREFIX_DIR} \
	--user=admin \
	--group=admin \
	--with-http_stub_status_module \
	--without-http-cache \
	--with-http_ssl_module \
	--with-http_gzip_static_module \
	--with-http_concat_module 
		
	CPU_NUM=$(cat /proc/cpuinfo | grep processor | wc -l)
		
	if [ $CPU_NUM -gt 1 ];then
		make -j$CPU_NUM
	else
		make
	fi
	
	make install

	echo -e "\033[32m Copy the tengine configs. \033[0m"
	cp -R $BASH_DIR/conf/* ${TENGINE_PREFIX_DIR}/conf/
else
	echo -e "\033[33m  The tengine has installed on $TENGINE_PREFIX_DIR \033[0m"
fi


#install tengine service
NGINX_SERVICE_FILE=nginx.sh
NGINX_SERVICE=/etc/init.d/nginx

echo -e "\033[32m Install the nginx service. \033[0m"
if [ ! -f $INSTALLER_DIR/$NGINX_SERVICE_FILE ]; then
    wget https://raw.github.com/JasonGiedymin/nginx-init-ubuntu/master/nginx -O $INSTALLER_DIR/$NGINX_SERVICE_FILE	
fi

if [ -f $INSTALLER_DIR/$NGINX_SERVICE_FILE ]; then
	if [ ! -f $NGINX_SERVICE ]; then
	    cp $INSTALLER_DIR/$NGINX_SERVICE_FILE $NGINX_SERVICE
		chmod +x $NGINX_SERVICE
	fi
	echo -e "\033[33m  Check the nginx status. \033[0m"
	service nginx status
	echo -e "\033[32m Set the nginx autostart at the system bootup && shutdown. \033[0m"
    update-rc.d -f nginx defaults
fi



