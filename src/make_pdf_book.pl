#!/usr/bin/perl -w
#
#indx#	make_pdf_book.pl - Take a bunch of pages (images) and make a pdf book out of it
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
#hist#	2026-03-03 - Christopher.M.Caldwell0@gmail.com - Created
########################################################################
#doc#	make_pdf_book.pl - Take a bunch of pages (images) and make a pdf book out of it
#doc#	Creates a table of contents based on filenames.
########################################################################

use strict;
use lib "/usr/local/lib/perl";
use cpi_file qw( echodo fatal read_file write_file cleanup );
use cpi_arguments qw( parse_arguments );
use cpi_filename qw( filename_to_text );
use cpi_vars;

# Put constants here

my $TMP = "/tmp/$cpi_vars::PROG.$$";
$TMP = "/tmp/$cpi_vars::PROG";
our %ONLY_ONE_DEFAULTS =
    (
    "o"	=>	"print.pdf",
    "t"	=>	"",
    "s"	=>	"",
    "i"	=>	"",
    );

my $CVT = "/usr/local/bin/nene";

# Put variables here.

our @problems;
our %ARGS;
our @files;

#########################################################################
#	Print usage message and die.					#
#########################################################################
sub usage
    {
    &fatal( @_, "",
	"Usage:  $cpi_vars::PROG <possible arguments>","",
	"where <possible arguments> are:",
	"    -o <output file>",
	"    -t <title>",
	"    -s <subtitle>",
	"    <filename>",
	"    <filename>:<file title>"
	);
    }

#########################################################################
#	Generate pdf file with contents and page numbers.		#
#########################################################################
sub generate_paging
    {
    my( @flist ) = @_;
    my $contfn = "$TMP/contents.pdf";
    open( OUT, "| wkhtmltopdf -q - $contfn" )
	|| die("Cannot write ${contfn}:  $!");
    print OUT
	"<html><head></head><body><center>\n",
	( $ARGS{t} ? "<h1>".$ARGS{t}."</h1>\n" : "" ),
	( $ARGS{s} ? "<h2>".$ARGS{s}."</h2>\n" : "" ),
	"<table width=90%>\n",
	( $ARGS{i} ? "<tr><td colspan=2>".&read_file($ARGS{i})."</td></tr>\n" : "" ),
	( "<tr><th colspan=2><h3>Contents</h3></th></tr>\n" ),
	( map { (
	    "<tr><th align=left>",$_->{t},"</th>",
	    "<td align=right>",$_->{firstpage},"</td></tr>\n"
	    ) } @flist ),
	"</table>\n";

    my $p = 2;
    foreach my $f ( @flist )
	{
	print OUT ( map { (
	    "<table width=90% style='page-break-before:always'>",
	    "<tr><th align=left>",
	    $ARGS{t},
	    "</th><th align=center>",
	    $f->{t},
	    "</th><td align=right>",
	    $p++,
	    "</td></tr></table>\n"
	    ) } (1..$f->{pages}) );
	}
    print OUT "</center></body></html>";
    close( OUT );
    return $contfn;
    }

#########################################################################
#	Return pointer to a blank page.					#
#########################################################################
sub generate_blank
    {
    my $blank = "$TMP/blank.pdf";
    open( OUT, "| wkhtmltopdf -q - $blank" )
	|| die("Cannot write ${blank}:  $!");
    print OUT "<h1>&nbsp;</h1>\n";
    close( OUT );
    return $blank;
    }

#########################################################################
#	Concatinate a blank page and all of the user's files.		#
#	Blank will be replaced by the contents.				#
#########################################################################
sub generate_base
    {
    my( $blank, @flist ) = @_;
    my $outfile = "$TMP/base.pdf";

    echodo(
        "pdfunite", 
	$blank,
	( map { $_->{pdfname} } @flist ),
	$outfile );

    return $outfile;
    }

#########################################################################
#	Slightly different than filename_to_text
#########################################################################
sub filename_to_title
    {
    my( $fname ) = @_;
    $fname =~ s/^[^\w]*//;
    return join(':  ',(map { &filename_to_text($_) } split(/\//,$fname) ) );
    }

#########################################################################
#	Get pdf files.							#
#########################################################################
sub get_pdf_files
    {
    my( @files ) = @_;
    my @ret;

    my $lastpage = 2;
    my $ind = 0;
    foreach my $fname ( @files )
	{
	my $fl = { name => $fname };
	if( $fname =~ /^(.*?):(.*)/ )
	    {
	    $fl->{name} = $1;
	    $fl->{t} = $2;
	    }
	elsif( $fname=~/^(.*)(\.[a-zA-Z0-9]+)$/ )
	    { $fl->{t} = &filename_to_title($1); }
	else
	    { $fl->{t} = &filename_to_title($fname); }
	if( $fl->{name} !~ /\.([A-Za-z0-9]+)$/ )
	    { die $fl->{name} . " is not a reasonable filename.\n"; }
	elsif( ! -r $fl->{name} )
	    {
	    print STDERR "$fl->{name} is missing.\n";
	    $fl->{pdfname} = "$TMP/in.$ind.pdf";
	    $ind++;
	    &write_file( "| $CVT -.html $fl->{pdfname}", <<EOF );
<html><head></head><body>
<br>&nbsp;<br>&nbsp;<br>&nbsp;<br>&nbsp;<br>&nbsp;<br>&nbsp;<br>
<center><table width=90% style='border: 1px solid black;'><tr>
<th height=200px>
$fl->{name} will go here when available.
</th></tr></table></center>
</body></html>
EOF
	    }
	elsif( $1 eq "pdf" )
	    { $fl->{pdfname} = $fl->{name}; }
	else
	    {
	    $fl->{pdfname} = "$TMP/in.$ind.pdf";
	    $ind++;
	    &echodo( $CVT,$fl->{name},$fl->{pdfname} );
	    }

	if( !open(INF,"pdfinfo '".$fl->{pdfname}."' |") )
	    { die( "Cannot pdfinfo " . $fl->{pdfname} . ": $!" ); }
	else
	    {
	    my $pages;
	    while( $_ = <INF> )
		{
		$pages = $1 if( /^Pages:\s*(\d+)/ );
		}
	    close( INF );
	    $fl->{pages} = $pages;
	    $fl->{firstpage} = $lastpage;
	    $lastpage += $pages;
	    }
	push( @ret, $fl );
	}
    return @ret;
    }

#########################################################################
#	Main								#
#########################################################################

&parse_arguments();

system("rm -rf $TMP");
mkdir $TMP;

if( $ARGS{t} eq "" && $ARGS{o} =~ /^(.*?):(.*)$/ )
    { $ARGS{o}=$1; $ARGS{t}=$2; }

if( @files = &get_pdf_files( @files ) )
    {
    my $contents_file = &generate_paging( @files );
    my $base_file = &generate_base( &generate_blank(), @files );

    echodo("qpdf $base_file --overlay $contents_file -- $ARGS{o}");
    }
system("rm -rf $TMP");

&cleanup(0);
