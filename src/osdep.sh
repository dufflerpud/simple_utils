#!/bin/sh

func="$1"
case "$func" in
    install)	shift;	TODO="$*"		;;
    update)					;;
    *)		echo "Unknown function [$func]"	;;
esac

ecsudo()
    {
    echo "+ $OSV_SUDO $*"
    $OSV_SUDO $*
    }

exstat=0

for posdir in /usr/local/etc /boot/system/config/non-packaged/etc ; do
    if [ -f $posdir/osv_vars.sh ] ; then
        . $posdir/osv_vars.sh
    fi
done

case "$func" in

    update)
	if [ -z "$TODO" ] ; then
	    [ -z "$OSV_SYNC" ]		|| yes '' | $OSV_SYNC
	    [ -z "$OSV_UPDATE" ]	|| yes '' | $OSV_UPDATE
	    [ -z "$OSV_UPGRADE" ]	|| yes '' | $OSV_UPGRADE
	fi
	;;

    install)
	for p in $TODO ; do
	    $OSV_INSTALL $p || exstat=$?
	done
	if [ -n "$OSV_PATH_UPDATE" ] ; then
	    $OSV_PATH_UPDATE || exstat=$?
	fi
	;;
esac

exit $exstat
