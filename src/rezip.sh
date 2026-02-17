#!/bin/sh
#
#indx#	rezip - Change .gz files to .bz2 files
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
#doc#	rezip - Change .gz files to .bz2 files
########################################################################

FILES="$*"
PROG=`basename $0`

usage()
    {
    cat <<CEOF
$*

Usage:  $PROG fn
CEOF
    exit 1
    }

process()
    {
    src="$1"
    dst=`echo $src | sed -e 's/gz$/bz2/'`
    if [ ! -r "$src" ] ; then
	echo "Skipping $src to $dst, $src does not exist."
    elif [ -e "$dst" ] ; then
	echo "Skipping $src to $dst, $dst already exists."
    else
	echo "+ gunzip < $src | bzip2 -9 > $dst"
	if gunzip < $src | bzip2 -9 > $dst ; then
	    rm $src
	else
	    echo "$dst got corrupted."
	fi
    fi
    }

for filename in $FILES ; do
    case "$filename" in
	*gz)	process $filename $destname
		;;
	*)	if [ -f "$filename.gz" ] ; then
		    process "$filename.gz"
		elif [ -f "$filename.tgz" ] ; then
		    process "$filename.tgz"
		else
		    echo "Ignoring $filename."
		fi
		;;
    esac
done
