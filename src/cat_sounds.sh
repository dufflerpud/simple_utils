#!/bin/sh

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
