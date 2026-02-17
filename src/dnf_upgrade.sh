#!/bin/sh
#
#indx#	dnf_upgrade - Upgrade to next version of Fedora
#@HDR@	$Id$
#@HDR@
#@HDR@	Copyright (c) 2026 Christopher Caldwell (Christopher.M.Caldwell0@gmail.com)
#@HDR@
#@HDR@	Permission is hereby granted, free of charge, to any person
#@HDR@	obtaining a copy of this software and associated documentation
#@HDR@	files (the "Software"), to deal in the Software without
#@HDR@	restriction, including without limitation the rights to use,
#@HDR@	copy, modify, merge, publish, distribute, sublicense, and/or
#@HDR@	sell copies of the Software, and to permit persons to whom
#@HDR@	the Software is furnished to do so, subject to the following
#@HDR@	conditions:
#@HDR@	
#@HDR@	The above copyright notice and this permission notice shall be
#@HDR@	included in all copies or substantial portions of the Software.
#@HDR@	
#@HDR@	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY
#@HDR@	KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
#@HDR@	WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE
#@HDR@	AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
#@HDR@	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
#@HDR@	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#@HDR@	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#@HDR@	OTHER DEALINGS IN THE SOFTWARE.
#
#hist#	2026-02-09 - Christopher.M.Caldwell0@gmail.com - Created
########################################################################
#doc#	dnf_upgrade - Upgrade to next version of Fedora
########################################################################

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
