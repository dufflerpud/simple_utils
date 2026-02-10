#!/bin/sh
#
#indx#	rebup.sh - Rename backup files to consistant names
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
#doc#	rebup.sh - Rename backup files to consistant names
########################################################################

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
