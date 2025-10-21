#!/bin/sh

PROG=`basename $0`
TMP=/tmp/$PROG		# or /tmp/$PROG.$$

#########################################################################
#	Print usage message and exit.					#
#########################################################################
usage()
    {
    echo "$*" | tr '~' '\012'
    echo "Usage:  $PROG [<release>]"
    exit 1
    }

#########################################################################
#	Print command and then execute it.				#
#########################################################################
echodo()
    {
    echo "+ $*"
    eval "$@"
    }

#########################################################################
#	Main								#
#########################################################################

id | grep -q '^uid=0' || exec sudo $0 "$*"

# Parse arguments

OLDREL=`awk '{print $3}' /etc/fedora-release`
NXTREL=`expr $OLDREL + 1`

doreboot=false
while [ "$#" -gt 0 ] ; do
    case "$1" in
	[0-9]*)	[ -z "$REL" ] || PROBLEMS="${PROBLEMS}Multiple releases specified.~"
		REL=$1
		;;
	-r)	doreboot=true					;;
	*)	PROBLEMS="${PROBLEMS}Unknown argument [$1].~"	;;
    esac
    shift
done
REL=${REL:-$NXTREL}

[ -n "$PROBLEMS" ] && usage "$PROBLEMS"

echodo dnf -y update
echodo dnf upgrade --refresh
echodo dnf install dnf-plugin-system-upgrade
echodo dnf -y system-upgrade download --releasever=$REL

$doreboot && echodo dnf system-upgrade reboot
