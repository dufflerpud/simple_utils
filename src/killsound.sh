#!/bin/sh

TMP=/tmp/killsound.$$

echodo()
    {
    echo "+ $*"
    $*
    }

signal=TERM
while : ; do
    lsof 2>/dev/null | awk '/\/dev\/snd/ || /\/dev\/dsp/ { print $0; }' > $TMP
    if [ -s $TMP ] ; then
	cat $TMP
	echodo kill -$signal `awk '{print $2}' $TMP | sort -u`
	signal=9
	sleep 1
    else
        break
    fi
done

[ $signal == "TERM" ] && echo "No processes found."

exec rm $TMP
