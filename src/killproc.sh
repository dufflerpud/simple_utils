#!/bin/sh

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
