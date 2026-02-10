#!/bin/sh
#
#indx#	cat_movies.sh - Obsoleted by cat_media - Only for movies
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
#doc#	cat_movies.sh - Obsoleted by cat_media - Only for movies
########################################################################

PROG=`basename $0`
TF=/tmp/$PROG.$$
TF=$PROG

echodo()
    {
    echo "+ $*"
    eval "$*"
    }

while [ "$#" -gt 0 ] ; do
    case "$1" in
	-o)	outfile=$2;		shift	;;
	*)	flist="$flist $1"		;;
    esac
    shift
done

if [ -z "$flist" -o -z "$outfile" ] ; then
    echo "Usage:  $PROG -o outfile infile infile infile"
    exit 1
fi

echodo "cat $flist > $TF.avi"
echodo "mencoder -really-quiet -quiet -oac copy -ovc copy -o $outfile -forceidx $TF.avi"
echodo "exec rm $TF.avi"
