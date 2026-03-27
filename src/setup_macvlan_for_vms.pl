#!/bin/sh
#
#indx#	setup_macvlan_for_vms.pl - Fix vmhost's local devices to handle vms
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
#hist#	2026-03-27 - Christopher.M.Caldwell0@gmail.com - Created
########################################################################
#doc#	setup_macvlan_for_vms.pl - Fix vmhost's local devices to handle vms.
#doc#	Run this on your Virtual Machine host (vmhost0?), probably just after
#doc#	booting but before you've started anything networkish.
#doc#	This will allow vm guests to talk to the vm host through IP (as
#doc#	well as the QEMU infrastructure).  Result survives reboots.
#doc#	Kept around if we need to (re)install the vmhost OS.
#doc#	See:
#doc#	    https://superuser.com/questions/349253/guest-and-host-cannot-see-each-other-using-linux-kvm-and-macvtap
########################################################################


# These are very specific to the Caldwell network.
NETSIZE=16
NETWORK=10.1.0.0/$NETSIZE
GW=10.1.0.1
DOMAIN=Brightsands.COM

PROG=`basename $0 .sh`
HOST=`hostname`
LOCALDEV=`ifconfig -a | grep flags=4163 | head -1 | sed -e 's/:.*//'`
ORIGINAL="Wired connection 1"
MAC=`ifconfig $LOCALDEV | awk '/ether/ {print $2}'`
IP=`grep "[ 	]$HOST " /etc/hosts | awk '{print $1}'`

#########################################################################
#	Print a usage message and die.					#
#########################################################################
usage()
    {
    (
    echo "$*" | tr '~' '\n'
    echo ""
    echo "Usage:  $PROG <vm_name>"
    ) >&2
    exit 1
    }

#########################################################################
#	Print what we're about to do and do it.				#
#########################################################################
echodo()
    {
    echo "+ $*"
    "$@"
    }

#########################################################################
#	Main								#
#########################################################################

PROBLEMS=
[ -n "$HOST" ]		|| PROBLEMS="$PROBLEMS~No virtual machine specified."
[ -n "$IP" ]		|| PROBLEMS="$PROBLEMS~No IP address found."
[ -n "$MAC" ]		|| PROBLEMS="$PROBLEMS~No MAC address found."
[ -n "$LOCALDEV" ]	|| PROBLEMS="$PROBLEMS~No local device found."

[ -n "$PROBLEMS" ] && usage $PROBLEMS

echodo nmcli con del "$ORIGINAL"
echodo nmcli con del host-macvlan
echodo nmcli connection add \
    con-name host-macvlan \
    type macvlan \
    mode bridge  \
    ifname macX  \
    dev $LOCALDEV \
    mac $MAC \
    ip4 $IP/$NETSIZE \
    gw4 $GW \
    ipv4.dns $GW,8.8.8.8 \
    ipv4.dns-search $DOMAIN
