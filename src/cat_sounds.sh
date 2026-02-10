#!/bin/sh
#
#indx#	cat_sounds.sh - Obsoleted by cat_media - Only for sounds
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
#doc#	cat_sounds.sh - Obsoleted by cat_media - Only for sounds
########################################################################

PROG=`basename $0`
FFMPEG_ARGS="-ab 128k -ar 44100 -ac 2"
LOGLEVEL="-loglevel error"
TMP=/tmp/$PROG.$$
TMP=/tmp/$PROG

echodo()
    {
    echo "+ $*"
    $*
    }

UNSAFE=false
while [ "$#" -gt 0 ] ; do
    case "$1" in
	-u)	UNSAFE=true			;;
        -o)	OUTFILE="$2"; shift		;;
	*)	FLIST="$FLIST $1"		;;
    esac
    shift
done

rm -rf $TMP
mkdir -p $TMP
n=10000
for fn in $FLIST ; do
    ifile="$TMP/$n.mp3"
    if $UNSAFE ; then
        case "$fn" in
	    /*)		echodo ln -s $fn $ifile		;;
	    *)		echodo ln -s `pwd`/$fn $ifile	;;
	esac
    else
	echodo ffmpeg $LOGLEVEL -y -i $fn $FFMPEG_ARGS $ifile
    fi
    ifiles="$ifiles $ifile"
    echo "file '$ifile'" >> $TMP/list
    n=`expr $n + 1`
done

echodo ffmpeg $LOGLEVEL -y -safe 0 -f concat -i $TMP/list -c copy $OUTFILE

rm -rf $TMP
