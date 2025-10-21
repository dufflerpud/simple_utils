#!/bin/sh

charg="$1"
case "$charg" in
    *-*)	util=chmod					;;
    *+*)	util=chmod					;;
    [0-7]*)	util=chmod					;;
    *:*)	util=chown					;;
    [a-z]*)	util=chown					;;
esac

shift

if [ "$#" -le 0 ] ; then
    set -x
    find . -print | xargs $util $charg
else
    set -x
    find "$@" -print | xargs $util $charg
fi
