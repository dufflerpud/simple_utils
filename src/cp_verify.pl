#!/usr/bin/perl -w
#
#indx#	cp_verify - Create a script to run to check an installation
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
#doc#	cp_verify - Create a script to run to check an installation
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
	"<possible arguments> are:",
	"    -u1 or -u0  Include -u checks in list of checks",
	"    -g1 or -g0  include -g checks in list of checks",
	"    -m1 or -m0  Include -m checks in list of checks",
	"    -c1 or -c0  Include -c checks in list of checks",
	"",
	"Create a script of commands to verify the correctness of an",
	"installation."
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
#	Output command to confirm a file is correct.			#
#	Will recurse with directories.					#
#########################################################################
sub do_one_file
    {
    my( $filename, $relativename ) = @_;
    my @cmds;
    if( my($dev,$ino,$mode,$nlink,$uid,$gid,$dev2,$size) = lstat($filename) )
        {
	my $checksum = "."x32;
	$checksum = &hashof( &read_file( $filename ) )
	    if( -f _ && $ARGS{checksum} );
	my @cmd = ( "/usr/local/bin/verifile" );
	push( @cmd, sprintf("-m%07o",$mode) )		if( $ARGS{mode} );
	push( @cmd, sprintf("-u%-6d",$uid) )		if( $ARGS{uid} );
	push( @cmd, sprintf("-g%-6d",$gid) )		if( $ARGS{gid} );
	push( @cmd, sprintf("-c %s",$checksum) )	if( $ARGS{checksum} );
	my $run_perl = 0;
	if( $ARGS{perl} && -f $filename )
	    {
	    my @lines = &read_lines( "file '$filename' |" );
	    $run_perl = 1 if( $lines[0] =~ /Perl script text/ );
	    }
	push( @cmd, "-p$run_perl" );
	push( @cmd, &quotes($relativename) );
	push( @cmd, '|| error_count=`expr $error_count + 1`' );
	push( @cmds, join(" ",@cmd) );
	if( ! -l $filename && -d $filename )
	    {
	    foreach $_ ( &files_in( $filename ) )
	        {
		push( @cmds, &do_one_file("$filename/$_","$relativename/$_") );
		}
	    }
	}
    return @cmds;
    }

#########################################################################
#	Create a list of commands to verify an installation.		#
#########################################################################
sub generate_list
    {
    my @cmds = ( "error_count=0" );
    push( @cmds, &do_one_file( &find_www_top(), "WWWTOP" ) );
    foreach my $file_to_check ( @DIRS )
        {
	push( @cmds, &do_one_file( $file_to_check, $file_to_check ) );
	}
    push( @cmds, 'INFO:  verify error count = $error_count.' );
    print STDOUT map{"$_\n"} @cmds;
    }

#########################################################################
#	Main								#
#########################################################################

if( 0 && $ENV{SCRIPT_NAME} )
    { &CGI_arguments(); }
else
    {
    &parse_arguments();
    &usage("Do not specify any files.") if(@files);
    $cpi_vars::VERBOSITY if(0);
    $cpi_vars::VERBOSITY = $ARGS{verbosity};
    &generate_list();
    }
&cleanup($exit_stat||0);
