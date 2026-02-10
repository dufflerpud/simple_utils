#!/bin/sh
#
#indx#	cat_images.sh - Obsoleted by cat_media - only for images
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
#doc#	cat_images.sh - Obsoleted by cat_media - only for images
########################################################################

PROG=`basename $0`
TMP=/tmp/$PROG		# or /tmp/$PROG.$$
TBLAR_ARGS=-topbottom
GS_ARGS="-q -dBATCH -dNOPAUSE"
REF=/home/chris/lib/template.odg
ZIP=/home/chris/bin/oozip
CVT=/usr/local/bin/nene
VERBOSITY=0

#PAMCUT_ARGS="-pad --height=3300"
#GS_ARGS="$GS_ARGS -sPAPERSIZE=a3"
#PNMTOPS_ARGS="-noturn -imagewidth 8.5"

#PAMCUT_ARGS="-pad --height=4200"
#GS_ARGS="$GS_ARGS -sPAPERSIZE=a4"
#PNMTOPS_ARGS="-noturn"

#########################################################################
#	Print usage message and exit.					#
#########################################################################
usage()
    {
    echo "$*" | tr '~' '\012'
    echo "Usage:  $PROG {-s <gsarg>} [-tb|-lr] file1 file2 file3 ... -o outfile"
    exit 1
    }

#########################################################################
#	Print command and then execute it.				#
#########################################################################
echodo()
    {
    [ "$VERBOSITY" != 0 ] && echo "+ $*" 1>&2
    eval "$@"
    }

#########################################################################
#	Convert all PPM files in named directory to jpegs.		#
#########################################################################
ppmstojpegs()
    {
    (
    cd $1
    for f in *.ppm ; do
        pnmtojpeg < $f > `basename $f .ppm`.jpg
    done
    rm -f *.ppm
    )
    }

#########################################################################
#########################################################################
odg_files()
    {
    (cd $TMP.i; unzip -o -q $REF -x; rm Pictures/*.jpg)

    index=1000
    for src in $flist ; do
	dname="$TMP.i/Pictures/file$index"
	echo "Working on [$src]"
	case "$src" in
	    *.ps)		echodo "pstopdf < $src > $TMP.pdf"
	    			echodo "pdftoppm $TMP.pdf $dname"
	    			echodo "ppmstojpegs $TMP.i/Pictures"
				;;
	    *.pdf)		echodo "pdftoppm $src $dname"
	    			echodo "ppmstojpegs $TMP.i/Pictures"
				;;
	    *.pnm)		echodo "pnmtojpeg < $src > $dname.jpg"		;;
	    *.jpg|*.jpeg)	echodo "cp $src $dname.jpg"			;;
	    *.gif)		echodo "giftopnm <$src | pnmtojpeg >$dname.jpg"	;;
	    *.tiff)		echodo "tifftopnm <$src | pnmtojpeg >$dname.jpg";;
	esac
	index=`expr $index + 1`
    done

    (
    cd $TMP.i/Pictures
    sed -e 's/^	//' <<'EOF'
	<?xml version="1.0" encoding="UTF-8"?>

	<office:document-content xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0" xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0" xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0" xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0" xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:meta="urn:oasis:names:tc:opendocument:xmlns:meta:1.0" xmlns:number="urn:oasis:names:tc:opendocument:xmlns:datastyle:1.0" xmlns:presentation="urn:oasis:names:tc:opendocument:xmlns:presentation:1.0" xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0" xmlns:chart="urn:oasis:names:tc:opendocument:xmlns:chart:1.0" xmlns:dr3d="urn:oasis:names:tc:opendocument:xmlns:dr3d:1.0" xmlns:math="http://www.w3.org/1998/Math/MathML" xmlns:form="urn:oasis:names:tc:opendocument:xmlns:form:1.0" xmlns:script="urn:oasis:names:tc:opendocument:xmlns:script:1.0" xmlns:ooo="http://openoffice.org/2004/office" xmlns:ooow="http://openoffice.org/2004/writer" xmlns:oooc="http://openoffice.org/2004/calc" xmlns:dom="http://www.w3.org/2001/xml-events" xmlns:xforms="http://www.w3.org/2002/xforms" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:smil="urn:oasis:names:tc:opendocument:xmlns:smil-compatible:1.0" xmlns:anim="urn:oasis:names:tc:opendocument:xmlns:animation:1.0" office:version="1.0">
	<office:scripts/>
	<office:automatic-styles>
	<style:style style:name="dp1" style:family="drawing-page"/>
	<style:style style:name="gr1" style:family="graphic" style:parent-style-name="standard">
	<style:graphic-properties draw:stroke="none" draw:fill="none" draw:textarea-horizontal-align="center" draw:textarea-vertical-align="middle" draw:color-mode="standard" draw:luminance="0%" draw:contrast="0%" draw:gamma="100%" draw:red="0%" draw:green="0%" draw:blue="0%" fo:clip="rect(0cm 0cm 0cm 0cm)" draw:image-opacity="100%" style:mirror="none"/>
	</style:style>
	<style:style style:name="P1" style:family="paragraph">
	<style:paragraph-properties fo:text-align="center"/>
	</style:style>
	</office:automatic-styles>
	<office:body>
	<office:drawing>
EOF
    for f in *.jpg ; do
	b=`basename $f .jpg`
	sed -e 's/^	//' -e "s+PAGEIND+$b+g" <<'EOF'
	<draw:page draw:name="PAGEIND" draw:style-name="dp1" draw:master-page-name="Default">
	<draw:frame draw:style-name="gr1" draw:text-style-name="P1" draw:layer="layout" svg:width="21.589cm" svg:height="26.843cm" svg:x="0.082cm" svg:y="0.647cm">
	<draw:image xlink:href="Pictures/PAGEIND.jpg" xlink:type="simple" xlink:show="embed" xlink:actuate="onLoad">
	<text:p/>
	</draw:image>
	</draw:frame>
	</draw:page>
EOF
    done
    sed -e 's/^	//' <<'EOF'
	</office:drawing>
	</office:body>
	</office:document-content>
EOF
    ) | tr -d '\012' > $TMP.i/content.xml

    #(cd $TMP.i; $ZIP $ZIPARGS $TMP.i.odg * */*)
    (cd $TMP.i/..; $ZIP $ZIPARGS `basename $TMP.i` `basename $TMP.i`.odg)
    echodo mv $TMP.i.odg $outfile
    }

#########################################################################
#	Convert files in flist to common type and concatinate them into	#
#	outfile.							#
#########################################################################
images()
    {
    index=1000
    case $outfile in
	*.pdf)			cattext=pdf				;;
        *.pdf|*.ps|*.odg)	cattext=ps				;;
	*)			cattext=pnm				;;
    esac
    for src in $flist ; do
	dname=$TMP.i/$index.$cattext
        echo "Converting $src to $dname" >&2
	index=`expr $index + 1`
	case "$src~$cattext" in	# Stdout will end up with $cattext file
	    *~pnm)		echodo "$CVT -v$VERBOSITY $src -.pnm | pamcut $PAMCUT_ARGS"	;;
	    *.ps~ps|*.pdf~ps)	echodo "$CVT -v$VERBOSITY $src -.ps"				;;
	    *.ps~pdf|*.pdf~pdf)	echodo "$CVT -v$VERBOSITY $src -.pdf"				;;
	    *~ps)		echodo "$CVT -v$VERBOSITY $src -.pnm | pamcut $PAMCUT_ARGS | pnmtops $PNMTOPS_ARGS"
				;;
	    *~pdf)		echodo "$CVT -v$VERBOSITY $src -.pnm | pamcut $PAMCUT_ARGS | pnmtops $PNMTOPS_ARGS > $TMP.ps"
				echodo ps2pdf $TMP.ps -
				;;
	esac > $dname
	converted_files="$converted_files $dname"
    done

    case $outfile in
        *.ps)			echodo gs $GS_ARGS -sDEVICE=pswrite \
				    -sOutputFile=$outfile $converted_files
				    ;;
#	*.pdf)			echodo gs $GS_ARGS -sDEVICE=pdfwrite \
#				    -sOutputFile=$outfile $converted_files
#				    ;;
	*.pdf)			echodo pdfunite $converted_files $outfile
				    ;;
	*.odg)			echodo gs $GS_ARGS -sDEVICE=pdfwrite \
				    -sOutputFile=$TMP.pdf $converted_files
				echodo pdfodg $TMP
				mv $TMP.odg $outfile
				    ;;
	*)			pnmcat $TBLAR_ARGS $converted_files | \
				    $CVT -v$VERBOSITY -.pnm $outfile
				    ;;
    esac
    }

#########################################################################
#	Main								#
#########################################################################

# Parse arguments
while [ "$#" -gt 0 ] ; do
    case "$1" in
	-s*)		GS_ARGS="$GS_ARGS $1"		;;
	-topbottom|-tb)	TBLAR_ARGS=-topbottom		;;
	-leftright|-lr)	TBLAR_ARGS=-leftright		;;
	-o)		outfile=$2; shift		;;
	-v*)		VERBOSITY=1			;;
	-*)		PAMCUT_ARGS="$PAMCUT_ARGS $1"	;;
	*)		flist="$flist $1"		;;
    esac
    shift
done

[ -z "$flist" ] && PROBLEMS="${PROBLEMS}No file list specified.~"
[ -z "$outfile" ] && PROBLEMS="${PROBLEMS}No output file specified.~"

[ -n "$PROBLEMS" ] && usage "$PROBLEMS"

mkdir -p $TMP.i

case "$outfile" in
    #*.odg)		odg_files	;;
    *)			images		;;
esac

#exec rm -rf $TMP.*
