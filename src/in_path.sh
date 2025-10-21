#!/bin/sh

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
