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
