#!/bin/sh

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
