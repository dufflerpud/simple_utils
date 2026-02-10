#!/bin/sh
#indx#	make_src_rpm.sh - Create an RPM file for installing specified source
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
#doc#	make_src_rpm.sh - Create an RPM file for installing specified source
########################################################################

PROG=`basename $0`

usage()
    {
    cat <<CEOF
$*

Usage:  $PROG file1.src.rpm file2.src.rpm ...
CEOF
    exit 1
    }


while [ "$#" -gt 0 ] ; do
    case "$1" in
        *.src.rpm)	FILES="$FILES $1"				;;
	*)		usage "Unknown argument:  $1"			;;
    esac
    shift
done

echodo()
    {
    echo "+ $*" >&2
    $*
    }

START_AT=`pwd`
for rpm in $FILES ; do
    topdir=$START_AT/`basename $rpm .src.rpm`
    echo "*** Building $topdir ..."
    echodo mkdir -p $topdir
    echodo rpm2cpio $rpm | (echodo cd $topdir; echodo cpio -idum)
    cd $topdir
    for tar_archive in *.tar.* ; do
        case "$tar_archive" in
	    *.bz2)	bunzip2 < $tar_archive			;;
	    *.xy)	xycat < $tar_archive			;;
	    *.xz)	xzcat < $tar_archive			;;
	    *.z)	gunzip < $tar_arvhive			;;
	    *.Z)	uncompress < $tar_archive		;;
	esac | tar xf -
	for middir in `ls */*akefile* | sed -e 's+/.*++' | sort -u` ; do
	    echodo cd $topdir/$middir
	    for patchfile in ../*.patch ; do
	        echodo patch -p1 < $patchfile
	    done
	    case "$middir" in
	        netpbm*)
		    (echo ""; echo ""; echo ""; echo "static"; yes "")\
			| echodo ./configure
		    ;;
		*)
		    ./configure --prefix=/usr
		    ;;
	    esac
	    echodo make -k
	done
    done
done
