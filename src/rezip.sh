#!/bin/sh

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
