#!/usr/bin/perl -w
#
#indx#	radix.pl - Find all radices where number has specified digits
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
#doc#	radix.pl - Find all radices where number has specified digits
#doc#	Radices from 2 to 62 checked.
########################################################################

use strict;

use lib "/usr/local/lib/perl";
use cpi_file qw( fatal cleanup );
use cpi_arguments qw( parse_arguments );

# Put constants here

our %ONLY_ONE_DEFAULTS =
    (
    "rinput"		=>	"",
    "routput"		=>	"",
    "input"		=>	"",
    "output"		=>	""
    );

my @DIGITS = ( 0..9, 'A'..'Z', 'a'..'z' );

# Put variables here.

our @problems;
our %ARGS;
our $exit_stat = 0;

#########################################################################
#	Print usage message and die.					#
#########################################################################
sub usage
    {
    &fatal( @_, "",
	"Usage:  $cpi_vars::PROG <possible arguments>","",
	"Print out all the integers that match the constraints given.",
	"",
	"where <possible arguments> are",
	"    -i	Input number",
	"    -ri	Radix of input",
	"    -o	Output number",
	"    -ro	Radix of output",
	"",
	"Where the radices can range from 2 to ".scalar(@DIGITS)." using".
	    " the following digits:",
	"\t".join("",@DIGITS),
	"",
	"For instance:",
	"$cpi_vars::PROG -i1010 -ri2 -o10",
	"\tConvert 10101 in binary to base 10.",
	"$cpi_vars::PROG -i10 -ri10 -o5",
	"\tShow me all of the bases that 10(10) would display as 5.",
	"$cpi_vars::PROG -o10",
	"\tShow all numbers in all bases that display as 10 in some base.",
	);
    }

#########################################################################
#	Convert number to a string of characters in specified radix.	#
#########################################################################
my %nradixcache;
sub ntoradix
    {
    my( $val, $radix ) = @_;
    my $cache_ind = join(",",$val,$radix);
    if( ! defined( $nradixcache{$cache_ind} ) )
	{
        my @res;
        do  {
	    push( @res, $DIGITS[ $val % $radix ] );
	    } while( int( $val /= $radix ) );
	$nradixcache{$cache_ind} = join("",reverse @res);
	}
    return $nradixcache{$cache_ind};
    }

#########################################################################
#	Convert a string of characters in specified radix to a number.	#
#########################################################################
my $digits = join("",@DIGITS);
sub nfromradix
    {
    my( $str, $radix ) = @_;
    my $cache_ind = join(".",$str,$radix);
    if( ! defined( $nradixcache{$cache_ind} ) )
	{
	my $res = 0;
	foreach my $dig ( split(//,$str) )
	    {
	    my $ind = index($digits,$dig,0);
	    return undef if( !defined($ind) || $ind < 0 || $ind >= $radix );
	    $res = $res*$radix + $ind;
	    }
	return $nradixcache{$cache_ind} = $res;
	}
    return $nradixcache{$cache_ind};
    }

#########################################################################
#	Figure out what radix for b will yield a in specified radix.	#
#########################################################################
sub find_radix
    {
    my( $a, $aradix, $b ) = @_;
    my $n = &nfromradix( $a, $aradix );
    my $bradix = 1;
    while( ++$bradix <= $#DIGITS )
	{
	my $try = &nfromradix($b,$bradix);
	return $bradix if( defined($try) && $try == $n );
	}
    &fatal("Cannot find the radix.");
    }

#########################################################################
#########################################################################
sub print_match
    {
    my( $iv, $iradix, $op, $ov, $oradix ) = @_;
    print &ntoradix($iv,$iradix),"($iradix) $op ", &ntoradix($ov,$oradix), "($oradix)\n";
    }

#########################################################################
#	Figure out what we know and what we are missing.		#
#########################################################################
sub interactive_logic
    {
    my @try_radices = ( 2 .. scalar(@DIGITS) );

    my %totry;
    foreach my $aind ( "rinput", "routput" )
	{
	@{$totry{$aind}} = ( $ARGS{$aind} ? ($ARGS{$aind}) : @try_radices );
	}

    foreach my $iradix ( @{$totry{rinput}} )
	{
	#print "top of i:  $iradix\n";
	#print "top of {i}:  $ARGS{input}.\n";
	my $iv = undef;
	next if( $ARGS{input} ne "" && !defined( $iv = &nfromradix($ARGS{input},$iradix) ) );
	#print "iradix=$iradix iv=",(defined($iv)?$iv:"U"),"\n";

	foreach my $oradix ( @{$totry{routput}} )
	    {
	    #print "top of o:  $oradix\n";
	    my $ov = undef;
	    next if( $ARGS{output} ne "" && !defined( $ov = &nfromradix($ARGS{output},$oradix) ) );
	    #print "oradix=$oradix ov=",(defined($ov)?$ov:"U"),"\n";

	    if( defined($iv) )
	    	{
		if( ! defined($ov) )
		    { &print_match( $iv, $iradix, '=', $iv, $oradix ); }
		elsif( $iv == $ov )
		    { &print_match( $iv, $iradix, '=', $iv, $oradix ); }
		else
		    {
		    # &print_match( $iv, $iradix, '!=', $iv, $oradix );
		    }
		}
	    else
	    	{
		if( defined($ov) )
		    { &print_match( $ov, $iradix, '=', $ov, $oradix ); }
		}
	    }
	}
    }

#########################################################################
#	Main								#
#########################################################################

if( $ENV{SCRIPT_NAME} )
    { &CGI_arguments(); }
else
    { &parse_arguments(); }

push( @problems, "-i or -o must be specified.")
    if( ! $ARGS{input} && ! $ARGS{output} );

&usage(@problems) if( @problems );

&interactive_logic();

#print "$ARGS{input}($ARGS{rinput}) = $ARGS{output}($ARGS{routput})\n";

cleanup($exit_stat);
