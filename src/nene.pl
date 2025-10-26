#!/usr/bin/perl -w
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
use cpi_file qw(fatal);
use cpi_arguments qw(parse_arguments);
use cpi_vars;

no warnings 'recursion';

# Put constants here

my $PROG = ( $_ = $0, s+.*/++, s/\.[^\.]*$//, $_ );
my $TMP = "/tmp/$PROG.$$";

our %ONLY_ONE_DEFAULTS =
    (
    "verbosity"	=> 0
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
	"Usage:  $PROG <possible arguments> <src1> <src2> ... <dest>","",
	"where <possible arguments> are:",
	"    -v1 or -v0  Turn verbosity on or off",
	"",
	"Convert one file type to another.  Some files require multiple",
	"source files to create the destination file, but most are 1-to-1.",
	"Note:  You may not necessarily agree with how it does it.",
	"Turn verbosity on to see what it is doing."
	);
    }

#########################################################################
#	Output debugging information if $ARGS{v} high enough		#
#########################################################################
sub debug
    {
    my( $flag, @rest ) = @_;
    print @rest if( $flag <= $ARGS{v} );
    }

#########################################################################
#	Main								#
#########################################################################

if( 0 && $ENV{SCRIPT_NAME} )
    { &CGI_arguments(); }
else
    {
    &cpi_arguments::parse_arguments();
#    %ARGS = &cpi_arguments::parse_arguments(
#	{
#	switches=>{"v"=>0},
#	non_switches=>\@files
#	} );
    }

#@files = @{ $ARGS{non_switches} };
my( $dest_file ) = pop( @files );
$cpi_vars::VERBOSITY if(0);
$cpi_vars::VERBOSITY = $ARGS{verbosity};
&generate_rules( $dest_file, @files );
&convert_file( $dest_file );
#&convert_file( $dest_file, @files );
exit(0);

exit($exit_stat||0);
