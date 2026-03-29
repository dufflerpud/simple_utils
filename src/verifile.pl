#!/usr/bin/perl -w
#
#indx#	verifile - Check attributes (and checksums) of a file
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
#doc#	verifile - Check attributes (and checksums) of a file
########################################################################

use strict;

use lib "/usr/local/lib/perl";
use cpi_file qw(read_file write_file fatal cleanup tempfile files_in
 read_lines );
use cpi_arguments qw(parse_arguments);
use cpi_english qw( list_items );
use cpi_hash qw( hashof );
use cpi_perl qw( quotes );
use cpi_vars;

# Put constants here

our %ONLY_ONE_DEFAULTS =
    (
    "mode"		=> "",
    "uid"		=> "",
    "gid"		=> "",
    "size"		=> "",
    "linkcheck"		=> "",
    "checksum"		=> "",
    "perl"		=> "",
    "verbosity"		=> 0
    );

my @DOCUMENT_ROOTS =
    (
    "/var/www/www",
    "/var/www/html",
    "/srv/http",
    "/srv/www/htdocs",
    "/boot/system/data/apache/htdocs",
    "/usr/local/www/apache24/data",
    "/var/apache2/2.4/htdocs"
    );

my @DIRS =
    (
    "/usr/local/projects",
    "/usr/local/bin",
    "/usr/local/lib"
    );

# Put variables here.

our @problems;
our %ARGS;
our @files;
our $exit_stat = 0;

$| = 1;

#########################################################################
#	Print usage message and die.					#
#########################################################################
sub usage
    {
    &fatal( @_, "",
	"Usage:  $cpi_vars::PROG <possible arguments> {<file>}",
	"where <file>s are specified, <possible arguments> are:",
	"    -v1 or -v0  Turn verbosity on or off",
	"    -p1 or -p0  Run with perl -c or not",
	"    -u <uid>",
	"    -g <gid>",
	"    -m <mode>",
	"    -c <checksum>",
	"    -l1 or -l0  Check if protections match with symlinks"
	);
    }

#########################################################################
#	Figure our where we're putting web files on this system.	#
#########################################################################
sub find_www_top
    {
    return $cpi_vars::WEBTOP
	if( defined($cpi_vars::WEBTOP) && -d $cpi_vars::WEBTOP );
    foreach my $docroot ( @DOCUMENT_ROOTS )
        {
	return $docroot.$cpi_vars::WEBOFFSET
	    if( -d $docroot.$cpi_vars::WEBOFFSET );
	}
    fatal("Cannot find $cpi_vars::WEBOFFSET in document roots.");
    }

#########################################################################
#	Go through file specified to make sure they have the correct	#
#	attributes.							#
#########################################################################
sub check_files
    {
    $ARGS{mode} = oct( $ARGS{mode} ) if( $ARGS{mode} );

    my $www_top;

    foreach my $fname ( @files )
        {
	if( $fname eq "WWWTOP" || $fname =~ m:^WWWTOP/: )
	    {
	    $www_top ||= &find_www_top();
	    $fname =~ s+^WWWTOP+$www_top+;
	    }
	if( my($dev,$ino,$mode,$nlink,$uid,$gid,$dev2,$size)=lstat($fname) )
	    {
	    my @mismatches;
	    if( $ARGS{mode} ne "" )
	        {
		if( ! -l _ || $ARGS{linkcheck} )
		    {
		    push( @mismatches,
			sprintf("mode (%07o vs %07o)", $mode, $ARGS{mode}) )
			if( $ARGS{mode} ne $mode );
		    }
		else
		    {	# Symlink protections only have meaning on BSD
		    push( @mismatches,
			sprintf("mode (%04o??? vs %07o)", $mode>>9, $ARGS{mode}) )
			if( ($ARGS{mode}>>9) ne ($mode>>9) );
		    }
		}
	    push( @mismatches,
		sprintf("owner (%07o vs %07o)", $uid, $ARGS{uid}) )
		if( $ARGS{uid} && $ARGS{uid} ne $uid );
	    push( @mismatches,
		sprintf("group (%07o vs %07o)", $gid, $ARGS{gid}) )
		if( $ARGS{gid} && $ARGS{gid} ne $gid );
	    push( @mismatches,
		sprintf("size (%d vs %d)", $gid, $ARGS{size}) )
		if( $ARGS{size} && $ARGS{size} ne $gid );
	    if( $ARGS{checksum} )
		{
		my $checksum =
			( -f _
			? &hashof( &read_file($fname) )
			: "."x32 );
		push( @mismatches,
		    sprintf("checksum (%s vs %s)", $checksum, $ARGS{checksum}) )
		    if( $ARGS{checksum} ne $checksum );
	        }
	    if( @mismatches )
	        { push( @problems,
		    ucfirst( &list_items( "mismatch", "and", @mismatches )
			. " in $fname." ) );
	    	}
	    if( $ARGS{perl} && -f $fname )
		{
		my $result =
		    &read_file(
			"perl -I/usr/local/lib/perl -c ".&quotes($fname)." 2>&1 |" );
		push( @problems, "perl failure for $fname" )
		    if( $result !~ /syntax OK/ );
		}
	    }
	else
	    { push( @problems, "$fname does not exist." ); }
	}
    if( @problems )
        {
	print STDERR map {"$_\n"} @problems;
	$exit_stat = 1;
	}
    }

#########################################################################
#	Main								#
#########################################################################

if( 0 && $ENV{SCRIPT_NAME} )
    { &CGI_arguments(); }
else
    {
    &parse_arguments();
    &usage("No file specified.") if( ! @files );
    $cpi_vars::VERBOSITY if(0);
    $cpi_vars::VERBOSITY = $ARGS{verbosity};
    &check_files();
    }
&cleanup($exit_stat||0);
