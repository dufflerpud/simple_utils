#!/bin/sh
#indx#	killproc.sh - Kill all processes matching supplied argument
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
#doc#	killproc.sh - Kill all processes matching supplied argument
########################################################################

LOOK4="sendmail"
SIG="-TERM"
TMP=/tmp/kp.$$

while [ "$#" -gt 0 ] ; do
    case "$1" in
	-y*|-Y*)	ANSWER=y				;;
        -*)		SIG=$1					;;
	*)		LOOK4=$1				;;
    esac
    shift
done

while : ; do
    ps -efww | grep -v grep | grep -v killproc | grep $LOOK4 > $TMP
    if [ ! -s $TMP ] ; then
	echo "No processes match '$LOOK4'."
        break
    fi
    cat $TMP
    pids=`awk '{print $2}' $TMP`
    if [ -n "$ANSWER" ] ; then
        answer=$ANSWER
	echo "kill $SIG" $pids
    else
        echo -n "kill $SIG" $pids "? "
        read answer
    fi
        
    case $answer in
        y*|Y*)	kill $SIG $pids; sleep 3				;;
	n*|N*)	break							;;
	*)	echo "Don't understand '$answer'.  Try 'y' or 'n'."	;;
    esac
done

exec rm -f $TMP
