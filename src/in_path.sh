#!/bin/sh
#indx#	in_path.sh - Script version of 'which' command.
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
#doc#	in_path.sh - Script version of 'which' command.
########################################################################

# This is called by programs to see if the utilities required are
# installed.  If the utilities are all found and should all run,
# no message is printed and an exit 0 status is returned.

VERBOSE=false
while [ "$#" -gt 0 ] ; do
    case "$1" in
        -v)	VERBOSE=true					;;
	*)	FILES="$FILES $1"				;;
    esac
    shift
done

PATH_DIRS=`echo $PATH | tr : " "`
exstat=0
for executable in $FILES ; do
    fqfn=
    for path_dir in $PATH_DIRS ; do
	pfqfn="$path_dir/$executable"
        [ ! -d "$pfqfn" -a -x "$pfqfn" ] && fqfn="$pfqfn"
    done
    if [ -z "$fqfn" ] ; then
        echo "$executable not found in $PATH_DIRS." >&2
	exstat=1
    else
        $VERBOSE && echo $fqfn
	if ldd "$fqfn" | grep -s 'not found' ; then
	    exstat=1
	    echo "$fqfn will not run due to:" >&2
	    ldd $fqfn | grep 'not found' >&2
	fi
    fi
done

exit $exstat
