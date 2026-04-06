#!/usr/bin/perl -w
#
#indx#	screens - Obtain info about connected monitors
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
#doc#	screens - Obtain info about connected monitors.
#doc#	Interfaces with X via xrandr.
########################################################################

use strict;
use lib "/usr/local/lib/perl";

use cpi_file qw( read_file write_file fatal files_in );
use cpi_arguments qw( parse_arguments );
use cpi_vars;
use cpi_inlist qw( abbrev );

use Data::Dumper;

# Put constants here

my $TMP = "/tmp/$cpi_vars::PROG.$$";

my @FIELDS = ("Name","Host","Port","MPV","Dimensions","Location","Geometry","URL");

my $BASE_DIR = $ENV{SCRIPT_FILENAME};
if( $BASE_DIR )
    { $BASE_DIR =~ s/\.cgi$//; }
else
    { $BASE_DIR = "$cpi_vars::USRLOCAL/projects/octagon"; }

our %ONLY_ONE_DEFAULTS =
    (
    "slots"	=>	"$BASE_DIR/cfg/slots.pl",	# File containing slot defs
    "xrandr"	=>	"$BASE_DIR/cfg/xrandr",		# Directory containing xrandr dumps
    "show"	=>	"",				# Show everything
    "verbosity"	=>	0
    );

my %FIELD;
#grep( $FIELD{$_}{constraint}	= lc(substr($_,0,1)),	@FIELDS );
#grep( $FIELD{$_}{show}		= uc(substr($_,0,1)),	@FIELDS );
#grep( $FIELD{$_}{constraint}	= lc($_),	@FIELDS );
#grep( $FIELD{$_}{show}		= uc($_),	@FIELDS );
grep( $FIELD{$_}{width}		= length($_),		@FIELDS );

#grep( $ONLY_ONE_DEFAULTS{$FIELD{$_}{constraint}}="", @FIELDS );
grep( $ONLY_ONE_DEFAULTS{lc($_)}="", @FIELDS );

# Put variables here.

our @problems;
our %ARGS;
our @print_fields;
our $exit_stat = 0;

#########################################################################
#	Print usage message and die.					#
#########################################################################
sub usage
    {
    &fatal( @_, "",
	"Usage:  $cpi_vars::PROG <possible arguments>","",
	"where <possible arguments> is:",
	"    -slots <perl file containing slot defs>",
	"    -xrandr <directory containing xrandr dumps>"
	);
    }

#########################################################################
#	Return a useful string if argument happens to not be defined.	#
#########################################################################
sub undf
    {
    return ( defined($_[0]) ? $_[0] : defined($_[1]) ? $_[1] : "UNDEF" );
    }

#########################################################################
#	Print out all the screens (with dimensions) we know about.	#
#########################################################################
sub print_table
    {
    my %screen_dims;
    my %SLOTS;
    my %URLS;
    #my @print_fields = grep( $ARGS{$FIELD{$_}{show}}, @FIELDS );
    if( $ARGS{show} )
	{ @print_fields = split(/,/,$ARGS{show}); }
    elsif( ! @print_fields )
	{ @print_fields = @FIELDS; }
    foreach my $fld ( @print_fields )
	{
	if( my $match = abbrev( $fld, @FIELDS ) )
	    { $fld = $match; }
	else
	    { push( @problems, "'$fld' is not a field.\n" ); }
	}
    &usage(@problems) if( @problems );

    foreach my $fn ( &files_in( $ARGS{xrandr} ) )
	{
	my $host_name = $fn;
	foreach $_ ( split(/\n/,&read_file($ARGS{xrandr}."/$fn")) )
	    {
	    if( #VGA-1 connected 1280x1024+1295+1024 (rest)
		/^([^\s]+) connected (\d+)x(\d+)\+(\d+)\+(\d+)\s+(.*)$/i
	    ||  /^([^\s]+) connected primary (\d+)x(\d+)\+(\d+)\+(\d+)\s+(.*)$/i
		)
		{
		my $screen_name = $1;
		$screen_dims{$host_name}{$screen_name}{width}	=$2 - 2;
		$screen_dims{$host_name}{$screen_name}{height}	=$3 - 2;
		$screen_dims{$host_name}{$screen_name}{left}	=$4 + 1;
		$screen_dims{$host_name}{$screen_name}{top}	=$5 + 1;
		$screen_dims{$host_name}{$screen_name}{rest}	=$6;
		}
	    }
	}

    eval( "%SLOTS=".&read_file($ARGS{slots}).";" );

    my @toprints;
    foreach my $slot_name ( sort keys %SLOTS )
	{
	my ($host,$port,$mpvscreen) = split(/:/,$SLOTS{$slot_name}{screen});
	my %val =
	    (	Name=>$slot_name,
		Host=>$host,
		Port=>$port,
		MPV=>$mpvscreen,
		Dimensions=>sprintf( "%sx%s",
		    map {&undf( $screen_dims{$host}{$port}{$_})}
			"width", "height" ),
		Location=>sprintf( "+%s+%s",
		    map {&undf( $screen_dims{$host}{$port}{$_})}
			"left", "top" ),
		Geometry=>sprintf( "%sx%s+%s+%s",
		    map {&undf( $screen_dims{$host}{$port}{$_})}
			"width", "height", "left", "top" ),
		URL=>&undf($SLOTS{$slot_name}{start_with})
	    );
	grep( $val{$_}="UNDEF", grep( $val{$_} =~ /UNDEF/, @FIELDS ) );
	#next if( grep( $ARGS{$FIELD{$_}{constraint}} && ($ARGS{$FIELD{$_}{constraint}} ne $val{$_}), @FIELDS ) );
	next if( grep( $ARGS{lc($_)} && (lc($ARGS{lc($_)}) ne lc($val{$_})), @FIELDS ) );
#	if( @files )
#	    {
#	    my $found = 0;
#	    foreach my $fl ( @files )
#		{
#		if( grep( $val{$_} eq $fl, @FIELDS ) )
#		    {
#		    $found = 1;
#		    last;
#		    }
#		}
#	    next if( ! $found );
#	    }
	grep( $FIELD{$_}{width}=length($val{$_}), grep( length($val{$_}) > $FIELD{$_}{width}, @FIELDS ) );
	push( @toprints, \%val );
	}

    $FIELD{ $print_fields[$#print_fields] }{width} = 0;
    print STDOUT ( map{sprintf("%*s",-($FIELD{$_}{width}+1),$_)} @print_fields ), "\n"
        if( scalar(@print_fields) > 1 );
    foreach my $toprint ( @toprints )
	{
	print STDOUT ( map{sprintf("%*s",-($FIELD{$_}{width}+1),$toprint->{$_})} @print_fields ), "\n";
	}
    }

#########################################################################
#	Main								#
#########################################################################

if( $ENV{SCRIPT_NAME} )
    { &CGI_arguments(); }
else
    {
    %ARGS = &parse_arguments(
        {
	switches	=>\%ONLY_ONE_DEFAULTS,
	non_switches	=>\@print_fields
	});
    }

#print join("\n\t","Args:",map{"$_:\t$ARGS{$_}"} sort keys %ARGS), "\n";

&print_table( );

exit($exit_stat);
