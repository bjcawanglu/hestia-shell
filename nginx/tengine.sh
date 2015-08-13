#! /bin/bash

###
# Install the nginx and config it.
# Author: rmfish@163.com
# Date: 20150811
# Version: 1
###

USER=`whoami`
BASH_NAME=$(basename $BASH_SOURCE)
BASH_DIR=`bashdir`

if [ $USER != "root" ];then
	msg="This command shoud run as administrator (user \"root\"), use \"sudo ${BASH_NAME}\" please!";
	danger $msg;
	exit
fi

echo.info "Install the required libs."
echo.info "Update apt source."
#apt-get -qq update
for packages in gcc g++ make wget libpcre3 libpcre3-dev libpcrecpp0 openssl libcurl4-openssl-dev;
do 
	echo.info "Install ${packages}."
	apt-get install -qq -y  $packages --force-yes;
	#apt-get -fy -qq install;
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
TENGINE_RUNNER_USER=admin
TENGINE_RUNNER_GROUP=admin
TENGINE_WWW="$(eval echo ~"$TENGINE_RUNNER_USER")"/work/www

# the tengine is installed.
echo -e "\033[32m Install the tengine[$TENGINE_VERSION]. \033[0m"
if [ ! -d $TENGINE_PREFIX_DIR ]; then
	# the tengine dir is not exist.
	if [ ! -d $INSTALLER_DIR/$TENGINE_FILE ]; then
		require $INSTALLER_DIR/$TENGINE_TGZ $TENGINE_URL
		# the tengine tgz file is not exist
		if [ -f $INSTALLER_DIR/$TENGINE_TGZ ]; then
			tar zxf $INSTALLER_DIR/$TENGINE_TGZ -C $INSTALLER_DIR
		fi
	fi

	cd $INSTALLER_DIR/$TENGINE_FILE

	echo.info "Install tengine:"

	./configure --prefix=${TENGINE_PREFIX_DIR} \
	--user=${TENGINE_RUNNER_USER} \
	--group=${TENGINE_RUNNER_GROUP} \
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

	echo.info " Copy the tengine configs."
	cp -R $BASH_DIR/conf/nginx.conf $BASH_DIR/conf/apps ${TENGINE_PREFIX_DIR}/conf/
else
	echo.warning "  The tengine has installed on $TENGINE_PREFIX_DIR"
fi


# Set tengine runner to run nginx service without sudo passwd.
echo.info "set '${TENGINE_RUNNER_USER}' nopasswd run nginx service"
NGINX_SUDOER=/etc/sudoers.d/adminnginx
cat >$NGINX_SUDOER<<EOF
${TENGINE_RUNNER_USER} ALL=(ALL) NOPASSWD:/usr/bin/service nginx restart
EOF
chmod 0440 $NGINX_SUDOER

#install tengine service
NGINX_SERVICE_FILE=nginx.sh
NGINX_SERVICE=/etc/init.d/nginx
NGINX_SERVICE_URL=https://raw.github.com/JasonGiedymin/nginx-init-ubuntu/master/nginx

echo.info "Install the nginx service."
require $INSTALLER_DIR/$NGINX_SERVICE_FILE $NGINX_SERVICE_URL 

if [ -f $INSTALLER_DIR/$NGINX_SERVICE_FILE ]; then
	if [ ! -f $NGINX_SERVICE ]; then
	    cp $INSTALLER_DIR/$NGINX_SERVICE_FILE $NGINX_SERVICE
		chmod +x $NGINX_SERVICE
	fi
	echo.warning "  Check the nginx status."
	service nginx status
	echo.warning "  Set the nginx autostart at the system bootup && shutdown."
    update-rc.d -f nginx defaults
fi
