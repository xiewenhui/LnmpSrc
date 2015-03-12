unset IFS
unset LD_PRELOAD
unset LD_LIBRARY_PATH

PATH='/usr/sbin:/sbin:/usr/bin:/bin'
LNMP_ROOT=`dirname "${0}"`
LNMP_ROOT=`cd "${LNMP_ROOT}/.." && pwd`
PATH="${LNMP_ROOT}/bin:${PATH}"

LD_LIBRARY_PATH="${LNMP_ROOT}/lib"
export LD_LIBRARY_PATH
export PATH
umask 0022

