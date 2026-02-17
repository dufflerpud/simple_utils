#!/bin/sh
#
#indx#	epr - Obsolete script for printing using Ghostscript and ftp
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
#doc#	epr - Obsolete script for printing using Ghostscript and ftp
########################################################################

TMP=/tmp/epr.$$
PRINTHOST=jetdirect_0
dtype="stcolor"
cols=1

exec > $TMP.log 2>&1
echo "Args:  $*"
ls -lR /var/spool/lp
set -x

while [ $# -gt 0 ] ; do
    case "$1" in
        -)		filenames="$filenames $1"		;;
	-k*)		fbase=`echo $1 | sed 's/-kcf/df/'`	;;
	-d*)		spooldir=`echo $1 | sed 's/-d//'`	;;
	-[0-9]*)	cols=`echo $1 | sed -e 's/-//'`		;;
	#-b*)		dtype=uniprint				;;
	#-c*)		dtype=stcolor				;;
	-*)		args="$args $1"				;;
	*)		filenames="$filenames $1"		;;
    esac
    shift
done

if [ -n "$fbase" ] ; then
    filenames="$spooldir/$fbase"
elif [ -z "$filenames" ] ; then
    filenames="-"
fi

for fname in $filenames ; do
    if [ "$fname" = "-" ] ; then
        fname=$TMP.infile
	cat - > $fname
    fi
    ftype=`file $fname | sed -e 's/^[^:]*: *//'`
    case "$ftype" in
        Post*)	gsin=$fname
		;;
        *)
		enscript --columns=$cols $fname -p $TMP.ps > /dev/null
		gsin=$TMP.ps
		;;
    esac
    gs -q -sDEVICE=$dtype -sOutputFile=$TMP.epson $gsin -dBATCH </dev/null

    ftp -n $PRINTHOST <<FTPEOF
user epr epr
binary
put $TMP.epson raw
FTPEOF
done

exec rm -f $TMP.*
