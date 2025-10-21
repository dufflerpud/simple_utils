#!/usr/local/bin/perl -w
########################################################################
#@HDR@	$Id$
#@HDR@		Copyright 2024 by
#@HDR@		Christopher Caldwell/Brightsands
#@HDR@		P.O. Box 401, Bailey Island, ME 04003
#@HDR@		All Rights Reserved
#@HDR@
#@HDR@	This software comprises unpublished confidential information
#@HDR@	of Brightsands and may not be used, copied or made available
#@HDR@	to anyone, except in accordance with the license under which
#@HDR@	it is furnished.
########################################################################
#	Create a unique name for a file based on % notation in the
#	supplied name.
#
#	2024-04-20 - c.m.caldwell@alumni.unh.edu - Created
########################################################################

use strict;

use lib "/usr/local/lib/perl";
use cpi_vars;
use cpi_file qw( fatal cleanup );
use cpi_arguments qw( parse_arguments );

my @DIGITS = ( '0'..'9', 'A'..'Z', 'a'..'z' );

our %ONLY_ONE_DEFAULTS =
    (
    "input"	=>	"/dev/stdin",
    "output"	=>	"/dev/stdout",
    "radix"	=>	scalar(@DIGITS),
    "digits"	=>	0,
    "verbosity"	=>	""
    );

# Put variables here.

our @problems;
our %ARGS;
our @files;
our $exit_stat = 0;

#########################################################################
#	Setup arguments if CGI.						#
#########################################################################
sub CGI_arguments
    {
    &CGIreceive();
    }

#########################################################################
#	Print usage message and die.					#
#########################################################################
sub usage
    {
    &fatal( @_, "",
	"Usage:  $cpi_vars::PROG <possible arguments> {<file printf format>}","",
	"where <possible arguments> are:",
	"    -r <radix to print in> (2 to 62, default to 62)",
	"    -d <number digits to print>"
	);
    }

#########################################################################
#	Find the next unused file.					#
#########################################################################
sub do_one_file
    {
    my( $fmt ) = @_;

    if( $fmt =~ /%(\d*)([dxoba])/ )
        {
	my $ndigs = $1;
	my $radix = $2;
	$ndigs = 1 if( ! $ndigs );
	$fmt =~ s/%${1}${radix}/%0${ndigs}s/;
	#$fmt =~ s/%0*([123456789]\d*)([dxoba])/%0${1}s/;
	$ARGS{radix} = { d=>10, x=>16, o=>8, b=>2, 'a'=>scalar(@DIGITS) } -> { $radix };
	}
    elsif( $fmt =~ /%\d+/ )
        {
	$fmt =~ s/%0*([123456789]\d*)/%0${1}s/;
	}
    else
        {
	$fmt = "$fmt.%04s";
	$ARGS{radix} = 10;
	}
    my $ind = 0;
    my $fn;
    while ( -e ( $fn = sprintf($fmt,&one_id($ind++)) ) ) {};
    return $fn;
    }

#########################################################################
#	Your basic "convert to an arbitrary base"			#
#########################################################################
sub one_id
    {
    my( $id ) = @_;
    my $digits = $ARGS{digits};
    my @res;
    while( $digits-- > 0 || $id )
        {
	push( @res, $DIGITS[ $id % $ARGS{radix} ] );
	$id = int( $id / $ARGS{radix} );
	#last if( $id == 0 );
	}
    return join("",reverse @res);
    }

#########################################################################
#	Main								#
#########################################################################

if( 0 && $ENV{SCRIPT_NAME} )
    { &CGI_arguments(); }
else
    { &parse_arguments(); }

#print join("\n\t","$cpi_vars::PROG args:",map{"$_:\t$ARGS{$_}"} sort keys %ARGS), "\n";

if( ! @files )
    { print &one_id( time()*1000000+$$), "\n"; }
else
    {
    foreach my $fnbase ( @files )
        { print &do_one_file($fnbase), "\n"; }
    }

&cleanup( 0 );
