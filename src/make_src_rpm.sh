#!/bin/sh

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
