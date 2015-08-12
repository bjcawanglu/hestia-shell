#! /bin/bash

###
# Install the php-fpm 
# Author: rmfish@163.com
# Date: 20150811
# Version: 1
###

USER=`whoami`
BASH_NAME=$(basename $BASH_SOURCE)

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


echo -e "\033[32m Install the required libs. \033[0m"
echo -e "\033[32m Update source. \033[0m"
#apt-get -qq update
#for packages in gcc g++ make wget libpcre3 libpcre3-dev libpcrecpp0 openssl libcurl4-openssl-dev;
for packages in gcc g++ make wget libmcrypt-dev;
do 
	echo -e "\033[32m Install $packages. \033[0m"
	apt-get install -qq -y  $packages --force-yes;
	#apt-get -fy -qq instaddll;
	#apt-get -y -qq autoremove;
done
#apt-get -y -q install gcc g++ make wget libpcre3 libpcre3-dev libpcrecpp0 openssl libcurl4-openssl-dev

INSTALLER_DIR=/opt/installer

#install iconv  iconv有bug，需要使用patch过的，具体是在./srclib/stdio.h:1010  注释掉 _GL_WARN_ON_USE (gets, "gets is a security hole - use fgets instead");
ICONV_SO=libiconv.so
ICONV_NAME=libiconv
ICONV_VERSION=1.14
ICONV_FILE=${ICONV_NAME}-${ICONV_VERSION}
ICONV_TGZ=${ICONV_FILE}.tar.gz
ICONV_URL=http://ftp.gnu.org/pub/gnu/libiconv/${ICONV_TGZ}
ICONV_PREFIX_DIR=/usr/local

echo -e "\033[32m Install the libiconv \033[0m"
if [ ! -L $ICONV_PREFIX_DIR/lib/$ICONV_SO ]; then
	if [ ! -d ${INSTALLER_DIR}/${ICONV_FILE} ]; then
		if [ ! -f ${INSTALLER_DIR}/${ICONV_FILE} ]; then
			echo -e "\033[33m Download libiconv from ${ICONV_URL}: \033[0m"
			wget ${ICONV_URL} -O $INSTALLER_DIR/${ICONV_TGZ}
		fi
		tar zxf $INSTALLER_DIR/$ICONV_TGZ -C $INSTALLER_DIR
	fi	
	
	cd $INSTALLER_DIR/$ICONV_FILE

	echo -e "\033[33m Install ${INCONV_NAME}[${ICONV_VERSION}]: \033[0m"
	./configure --prefix=$ICONV_PREFIX_DIR

	echo -e '\033[31m libiconv stdio.h bugfix. \033[0m'
	# bugfix
	sed -i 's/^_GL_WARN_ON_USE (gets, "gets is a security hole - use fgets instead")/\/\/&/' $INSTALLER_DIR/$ICONV_FILE/srclib/stdio.h	

	echo -e "\033[32m  make libiconv \033[0m"
	if [ $CPU_NUM -gt 1 ];then
		make -j$CPU_NUM
	else
		make
	fi

	echo -e "\033[32m make installlibiconv \033[0m"
	make install
else
	echo -e "\033[33m  The libiconv has installed on ${ICONV_PREFIX_DIR}/lib/${ICONV_SO} \033[0m"
fi


PHP_PREFIX_DIR=/usr/local/php
PHP_NAME=php
PHP_VERSION=5.5.17
PHP_FILE=${PHP_NAME}-${PHP_VERSION}
PHP_TGZ=${PHP_FILE}.tar.gz
PHP_URL=http://cn2.php.net/distributions/${PHP_TGZ}

echo -e "\033[32m Install php-fpm \033[0m"
if [ ! -d $PHP_PREFIX_DIR ]; then
	if [ ! -d ${INSTALLER_DIR}/${PHP_FILE} ]; then
		if [ ! -f ${INSTALLER_DIR}/${PHP_TGZ} ]; then
			echo -e "\033[33m Download ${PHP_TGZ} from ${PHP_URL}: \033[0m"
			wget ${PHP_URL} -O $INSTALLER_DIR/${PHP_TGZ}
		fi
		tar zxf $INSTALLER_DIR/$PHP_TGZ -C $INSTALLER_DIR
	fi	
	
	cd $INSTALLER_DIR/$PHP_FILE

	echo -e "\033[33m Install ${PHP_NAME}[${PHP_VERSION}]: \033[0m"
	
	./configure --prefix=${PHP_PREFIX_DIR} \
	--with-config-file-path=${PHP_PREFIX_DIR}/etc \
		--enable-fpm \
		--with-fpm-user=admin \
		--with-fpm-group=admin \
		--with-mysql=mysqlnd \
		--with-mysqli=mysqlnd \
		--with-pdo-mysql=mysqlnd \
		--enable-opcache \
		--enable-static \
		--enable-inline-optimization \
		--enable-sockets \
		--enable-wddx \
		--enable-zip \
		--enable-calendar \
		--enable-bcmath \
		--enable-soap \
		--with-zlib \
		--with-iconv \
		--with-gd \
		--with-xmlrpc \
		--enable-mbstring \
		--with-curl \
		--enable-ftp \
		--with-mcrypt  \
		--disable-ipv6 \
		--disable-debug \
		--with-openssl \
		--disable-maintainer-zts \
		--disable-fileinfo

		CPU_NUM=$(cat /proc/cpuinfo | grep processor | wc -l)

		echo -e "\033[31m make php \033[0m"

		if [ $CPU_NUM -gt 1 ]; then
			make ZEND_EXTRA_LIBS='-liconv' -j$CPU_NUM
		else
			make ZEND_EXTRA_LIBS='-liconv'
		fi

		make install
		
		cp $INSTALLER_DIR/$PHP_FILE/sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
		chmod +x /etc/init.d/php-fpm
else
	echo -e "\033[33m  The php has installed on ${PHP_PREFIX_DIR} \033[0m"
fi


$BASH_DIR/phpconfig.sh $PHP_PREFIX_DIR
