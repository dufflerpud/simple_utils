#!/usr/bin/perl -w
#
#indx#	int_to_text.pl - Convert integer to text
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
#hist#	2026-05-27 - Christopher.M.Caldwell0@gmail.com - Created
########################################################################
#doc#	Convert integer to text (123 = one hundred twenty three)
########################################################################
#	numbers.pl
#
#	A program to convert digits to the english way of saying the
#	number.
#
#	2024-04-19 - c.m.caldwell@alumni.unh.edu - Created
########################################################################

use strict;

use lib "/usr/local/lib/perl";

use cpi_file qw( cleanup );

my @digs = (
    "zero", "one", "two", "three", "four", "five", "six", "seven", "eight",
    "nine", "ten",  "eleven", "twelve", "thirteen", "fourteen", "fifteen",
    "sixteen", "seventeen", "eighteen", "nineteen" );

my @tens = (
    "zero", "ten", "twenty", "thirty", "forty", "fifty", "sixty",
    "seventy", "eighty", "ninety" );

my @groupnames = ( "thousand", "million", "billion", "trillion",
    "quadrillion", "quintillion", "sextillion", "septillion", "octillion",
    "nonillion", "decillion", "undecillion", "duodecillion", "tredecillion",
    "quattuordecillion", "quindecillion", "sexdecillion", "septendecillion",
    "octodecillion", "novemdecillion", "vigintillion" );

my $str = "";
my $exit_status = 0;

########################################################################
########################################################################
sub group
    {
    my( $orignum, $name ) = @_;
    my $num = $orignum;
    my $dig;

    $str .= ",\n   " if( $str && $orignum );

    $str .= ($str?" ":"")."$digs[$dig] hundred" if( $dig = int($num / 100) );

    if( $num %= 100 )
	{
	if( $num < 20 )
	    { $str .= ($str?" ":"").$digs[$num]; }
	else
	    {
	    if( $dig = int( $num / 10 ) )
		{
		if( $num %= 10 )
		    { $str .= ($str?" ":"").$tens[$dig]."-".$digs[$num]; }
		else
		    { $str .= ($str?" ":"").$tens[$dig]; }
		}
	    elsif( $num )
	        { $str .= ($str?" ":"").$digs[$num]; }
	    }
	}
    $str .= " $name" if( $orignum && $name );
    }

########################################################################
#	Main
########################################################################
my $num = $ARGV[0];

my $fract = "";

$num =~ s/,//;
if( $num =~ /^(\d+)\.(\d+)$/ )
    {
    $num = $1;
    $fract = $2;
    }
 
my @grouptext = ();
my @groupnamelist = ();
my $groupind = 0;
push( @groupnamelist, "" );
foreach $_ ( split(/(\d\d\d)/,join("",reverse(split(//,$num)))) )
    {
    if( /\d/ )
        {
	push(@grouptext, join("",reverse(split(//))));
	push(@groupnamelist, $groupnames[ $groupind++ % scalar(@groupnames) ]);
	}
    }

pop( @groupnamelist );
while( my $grouptext = pop(@grouptext) )
    {
    &group( $grouptext, pop(@groupnamelist) );
    }

if( $fract ne "" )
    {
    $str .= "\n    " if( $str );
    $str .= "point";
    my $ind = 0;
    foreach $_ ( split(/(\d)/,$fract) )
	{
        if( /\d/ )
	    {
	    $str .= ( ($ind++ % 3 == 0) ? "\n    " : " " );
	    $str .= $digs[$_];
	    }
	}
    }

$str = "zero" if( ! $str );

print $str, "\n";

&cleanup( $exit_status );
