#!/bin/sh -x

#########################################################################
#	toodg		A script to translate something to an		#
#			OpenOffice drawing.				#
#									#
#			This started out only handling pdf files but	#
#			now it tries to be smarter.			#
#########################################################################

TMPDIR=/var/tmp/toodg.$$
REF=/home/chris/lib/template.odg
#ZIP=/home/chris/bin/oozip
ZIP=oozip		# Hope it's in the path
#ZIPARGS="-rq9"

while [ "$#" -gt 0 ] ; do
    case "$1" in
    	*.pdf)	filebase=`echo "$1" | sed -e 's/\.pdf$//'`		;;
	*)	filebase="$1"						;;
    esac
    shift
done

rm -rf $TMPDIR $TMPDIR.odg
mkdir -p $TMPDIR/Pictures
(cd $TMPDIR; unzip -q $REF -x)
rm $TMPDIR/Pictures/*.jpg

if [ -e $filebase.pdf ] ; then
    pdftoppm $filebase.pdf $TMPDIR/Pictures/file
elif [ -d $filebase ] ; then
    for fn in $filebase/* ; do
        /usr/local/bin/nene $fn $TMPDIR/Pictures/file-`basename $fn`.ppm
    done
elif [ -f $filebase ] ; then
    /usr/local/bin/nene $filebase $TMPDIR/Pictures/file-`basename $fn`.ppm
fi

(
cd $TMPDIR/Pictures
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
for f in *.ppm ; do
    b=`basename $f .ppm`
    pnmtojpeg < $b.ppm > $b.jpg
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
rm -f *.ppm
sed -e 's/^	//' <<'EOF'
	</office:drawing>
	</office:body>
	</office:document-content>
EOF
) | tr -d '\012' > $TMPDIR/content.xml

# I really wish we could use the FC6 "zip" utility, but it produces zip
# files that openoffice just doesn't like.  Consequently, I've grabbed
# somebody's perl program to create zip files, but it takes arguments
# differently.
#(cd $TMPDIR; $ZIP $ZIPARGS $TMPDIR.odg * */*)
(cd $TMPDIR/..; $ZIP $ZIPARGS `basename $TMPDIR` `basename $TMPDIR`.odg)

mv $TMPDIR.odg $filebase.odg
#rm -rf $TMPDIR
