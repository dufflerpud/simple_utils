#!/bin/sh -x

PROG=`basename $0`
TMP=/tmp/$PROG		# or /tmp/$PROG.$$
TBLAR_ARGS=-topbottom
GS_ARGS="-q -dBATCH -dNOPAUSE"
REF=/home/chris/lib/template.odg
ZIP=/home/chris/bin/oozip
CVT=/usr/local/bin/nene

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
    echo "+ $*"
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
	    *.ps)		pstopdf < $src > $TMP.pdf
	    			pdftoppm $TMP.pdf $dname
	    			ppmstojpegs $TMP.i/Pictures
				;;
	    *.pdf)		pdftoppm $src $dname
	    			ppmstojpegs $TMP.i/Pictures
				;;
	    *.pnm)		pnmtojpeg < $src > $dname.jpg		;;
	    *.jpg|*.jpeg)	cp $src $dname.jpg			;;
	    *.gif)		giftopnm <$src | pnmtojpeg >$dname.jpg	;;
	    *.tiff)		tifftopnm <$src | pnmtojpeg >$dname.jpg	;;
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
    mv $TMP.i.odg $outfile
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
	    *~pnm)		$CVT $src -.pnm | pamcut $PAMCUT_ARGS	;;
	    *.ps~ps|*.pdf~ps)	$CVT $src -.ps				;;
	    *.ps~pdf|*.pdf~pdf)	$CVT $src -.pdf				;;
	    *~ps)		$CVT $src -.pnm | pamcut $PAMCUT_ARGS | \
	    			    pnmtops $PNMTOPS_ARGS
				;;
	    *~pdf)		$CVT $src -.pnm | pamcut $PAMCUT_ARGS | \
	    			    pnmtops $PNMTOPS_ARGS > $TMP.ps
				ps2pdf $TMP.ps -
				;;
	esac > $dname
	converted_files="$converted_files $dname"
    done

    case $outfile in
        *.ps)			gs $GS_ARGS -sDEVICE=pswrite \
				    -sOutputFile=$outfile $converted_files
				    ;;
#	*.pdf)			gs $GS_ARGS -sDEVICE=pdfwrite \
#				    -sOutputFile=$outfile $converted_files
#				    ;;
	*.pdf)			pdfunite $converted_files $outfile
				    ;;
	*.odg)			gs $GS_ARGS -sDEVICE=pdfwrite \
				    -sOutputFile=$TMP.pdf $converted_files
				pdfodg $TMP
				mv $TMP.odg $outfile
				    ;;
	*)			pnmcat $TBLAR_ARGS $converted_files | \
				    $CVT -.pnm $outfile
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
