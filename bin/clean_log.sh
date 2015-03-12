#!/bin/sh
CURRENT_DIR=`readlink -f $0`
CURRENT_DIR=`dirname ${CURRENT_DIR}`
cd ${CURRENT_DIR}/../
CURRENT_DIR=`pwd`

LOG_PATH=${CURRENT_DIR}/log
MAX_DAYS=3
CLEAN_DAYS=30

BCK_PATH=bck

MV=echo
MKDIR=echo
RM=echo
if [ "$1" == "clean" ]; then
    MV=mv
    MKDIR=mkdir
    RM=rm
fi

[ -e ${LOG_PATH} ] || exit 0

cd ${LOG_PATH} || exit 1

for i in `find -mtime +${MAX_DAYS} |fgrep -v "${BCK_PATH}"`; do
    if [ -f $i ]; then
        ${MKDIR} -p ${BCK_PATH}/`dirname $i`
        if [ -e "${BCK_PATH}/${i}" ]; then
            ${MV} "${BCK_PATH}/${i}" "${BCK_PATH}/${i}.`date +%Y%m%d%H`"
        fi
        ${MV} -f "$i" "${BCK_PATH}/${i}"
    fi
done

find "${BCK_PATH}" -mtime +${CLEAN_DAYS} -exec rm -rf {} \;

for i in `find "${LOG_PATH}" -type d`; do
    if [ `ls -A "$i" | wc -l` = 0 ]; then
        ${RM} -rf "$i"
    fi
done

#sh ${CURRENT_DIR}/opbin/bkupLogToRemote.sh
exit $?
