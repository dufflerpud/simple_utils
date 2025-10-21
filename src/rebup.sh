#!/bin/sh

FILEBASE="$1"
EXT=bz2

#########################################################################
#	Echo what a command would do and then do it.			#
#########################################################################
echodo()
    {
    echo "+ $*"
    $*
    }

#########################################################################
#	Print an error message and die.					#
#########################################################################
fatal()
    {
    echo "$1"
    exit 1
    }

[ -z "$FILEBASE" ] && fatal "Usage:  $0 filename"

#########################################################################
#	Get rid of redundant backups.					#
#########################################################################
check_against_name=
for checking_name in $FILEBASE.[0-9][0-9][0-9][0-9].$EXT; do
    if [ -z "$check_against_name" ] ; then
        check_against_name="$checking_name"
    elif cmp -s "$check_against_name" "$checking_name" ; then
        echodo rm $checking_name
    else
        check_against_name="$checking_name"
    fi
done

#########################################################################
#	Now rename things so they are sequential.			#
#########################################################################
ind=0
for checking_name in $FILEBASE.[0-9][0-9][0-9][0-9].$EXT; do
    computed_name="$FILEBASE.`echo $ind | awk '{printf(\"%04d\",$0);}'`.$EXT"
    ind=`expr $ind + 1`
    if [ "$computed_name" != "$checking_name" ] ; then
        echodo mv "$checking_name" "$computed_name"
    fi
done
