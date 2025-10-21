#!/bin/sh

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
