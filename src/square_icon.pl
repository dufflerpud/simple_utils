#!/usr/bin/perl -w
#
#indx#	square_icon - Create an icon suitable for iPhone based on supplied text
#@HDR@	$Id$
#@HDR@
#@HDR@	Copyright (c) 2024-2026 Christopher Caldwell (Christopher.M.Caldwell0@gmail.com)
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
#doc#	square_icon - Create an icon suitable for iPhone based on supplied text
########################################################################

#########################################################################
#	nene.pl (formerly cvt.pl, part of the Pandora project)		#
#		2024-04-18	c.m.caldwell@alumni.unh.edu		#
#									#
#	Script to convert many file types to many other file types.	#
#	Primarily used to prevent having to think about which file	#
#	conversion utility is used to do the conversion.		#
#									#
#	Exercises MakeFrom.pm, a bunch of perl callable routines to	#
#	do the same thing.						#
#########################################################################

use strict;

use lib "/usr/local/lib/perl";
use cpi_make_from qw(convert_file generate_rules);
use cpi_file qw(echodo autopsy fatal cleanup read_file tempfile);
use cpi_arguments qw(parse_arguments);
use cpi_filename qw(just_ext_of);
use cpi_vars;

no warnings 'recursion';

# Put constants here

my $TMP = "/tmp/$cpi_vars::PROG.$$";
my $NENE = "$cpi_vars::USRLOCAL/bin/nene";

our %ONLY_ONE_DEFAULTS =
    (
    "verbosity"		=> 0,
    "text"		=> "",
    "mode"		=> [ "tlbr", "bltr" ],
    "input_file"	=> "/dev/stdin",
    "output_file"	=> "",
    "nheight"		=> 57,
    "nwidth"		=> 57,
    "cheight"		=> 30,
    "cwidth"		=> 30
    );

# Put variables here.

our @problems;
our %ARGS;
our @files;
my $exit_stat;

$| = 1;

#########################################################################
#	Print usage message and die.					#
#########################################################################
sub usage
    {
    &fatal( @_, "",
	"Usage:  $cpi_vars::PROG <possible arguments>",
	"where <possible arguments> are:",
	"    -v1 or -v0  Turn verbosity on or off",
	"    -i <input file>",
	"    -o <output file>",
	"    -t 'some text' (replaces -i)"
	);
    }

#########################################################################
#	Main								#
#########################################################################

if( $ENV{SCRIPT_NAME} )
    { &CGI_arguments(); }
else
    {
    &cpi_arguments::parse_arguments();
    }

if( $ARGS{text} ne "" )
    {
    my @toprint = ( "<table border=1px",
	    " style='border-collapse:collapse;border-width:1px;border:solid;'>\n" );
    my $total_width = 0;
    my $total_height = 0;
    if( $ARGS{text} !~ /\s+/ )
        {
	my @characters = split(//,$ARGS{text});
	my $nchars = scalar(@characters);
	my $cheight = $ARGS{cheight};
	my $cwidth = $ARGS{cwidth};
	$total_height = $cheight * $nchars;
	$total_width = $cwidth * $nchars;
	#my $cheight = int( $ARGS{rheight} / $nchars );
	#my $cwidth = int( $ARGS{rwidth} / $nchars );
	for( my $row=0; $row<$nchars; $row++ )
	    {
	    push( @toprint, "<tr>" );
	    for( my $col=0; $col<$nchars; $col++ )
	        {
		push( @toprint, "<th width=${cwidth}px height=${cheight}px align=center valign=middle>" );
		if( $ARGS{mode} eq "tlbr" && $row==$col )
		    { push( @toprint, $characters[$row] ); }
		elsif( $ARGS{mode} eq "bltr" && ($row+$col)==($nchars-1))
		    { push( @toprint, $characters[$col] ); }
		else
		    { push( @toprint, "&nbsp;" ); }
		push( @toprint, "</th>" );
		}
	    push( @toprint, "</tr>\n" );
	    }
	}
    else
        {
	my @lines = split(/\s+/,$ARGS{text});
	my $width = 0;
	grep( length($_)>$width && ($width=length($_)), @lines );
	#my $cheight = int( $ARGS{rheight} / scalar(@lines) );
	#my $cwidth = int( $ARGS{rwidth} / $width );
	my $cheight = $ARGS{cheight};
	my $cwidth = $ARGS{cwidth};
	$total_height = $cheight * scalar(@lines);
	$total_width = $cwidth * $width;
	foreach my $line ( @lines )
	    {
	    push( @toprint, "<tr>" );
	    for( my $col=0; $col<$width; $col++ )
		{
		push( @toprint, "<th width=${cwidth}px height=${cheight}px align=center valign=middle>" );
	        if( $col < length($line) )
		    { push( @toprint, substr( $line, $col, 1 ) ); }
		else
		    { push( @toprint, "&nbsp;" ); }
		push( @toprint, "</th>" );
		}
	    push( @toprint, "</tr>\n" );
	    }
	}
    my $cmd = "wkhtmltoimage -q --width $total_width - $TMP.0.jpg"
    		."; $NENE $TMP.0.jpg $TMP.0.pnm";
    print STDERR "| $cmd\n" if( $ARGS{verbosity} );
    open( OUT, "| $cmd" ) || &autopsy("Cannot run wkhtmltoimage:  $!");
    print OUT @toprint;
    close( OUT );
    $ARGS{input_file} = "$TMP.0.pnm";
    }

if( &just_ext_of( $ARGS{input_file} ) ne "pnm" )
    {
    &echodo( "$NENE -v$ARGS{verbosity} $ARGS{input_file} $TMP.0.pnm" );
    $ARGS{input_file} = "$TMP.0.pnm";
    }

my $pnminfo = &read_file("pnmfile '$ARGS{input_file}' |");
chomp( $pnminfo );
&autopsy("Cannot determine size of $pnminfo") if($pnminfo !~ /(\d+) by (\d+)/);
my( $cutwidth, $cutheight ) = ( $1, $2 );

my $catmode;
if( $cutwidth > $cutheight )
    {
    $cutheight = int( ( $cutwidth - $cutheight ) / 2 );
    $catmode = "tb";
    }
elsif( $cutheight > $cutwidth )
    {
    $cutwidth = int( ( $cutheight - $cutwidth ) / 2 );
    $catmode = "lr";
    }
else
    {}	# Don't change them

if( $catmode && $cutwidth > 0 && $cutheight > 0 )
    {
    &echodo( "pamcut --width=1 --height=1 $ARGS{input_file}"
    .	"| pamscale --height=$cutheight --width=$cutwidth > $TMP.1.pnm" );
    &echodo( "pnmcat -$catmode $TMP.1.pnm $ARGS{input_file} $TMP.1.pnm > $TMP.2.pnm" );
    $ARGS{input_file} = "$TMP.2.pnm";
    }

&echodo( "pamscale --height=$ARGS{nheight} --width=$ARGS{nwidth} $ARGS{input_file} > $TMP.3.pnm" );
&echodo( "$NENE -v$ARGS{verbosity} $TMP.3.pnm $ARGS{output_file}" );
system("rm -f $TMP.*");
&cleanup(0);
