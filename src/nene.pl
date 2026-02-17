#!/usr/bin/perl -w
#
#indx#	nene - Copy data from any ext to any ext (converting as required)
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
#doc#	nene - Copy data from any ext to any ext (converting as required)
#doc#	More complex than you might think.  For instance, if you nene a
#doc#	.txt file to a .mp3 file, you'll get the words in the .txt file
#doc#	in spoken English.  If you nene from a movie to a sound file,
#doc#	you'll just get the sound track.  Smarter than your average bear
#doc#	but frequently wrong.
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
use cpi_file qw(read_file write_file fatal cleanup tempfile);
use cpi_arguments qw(parse_arguments);
use cpi_mime qw( read_mime_types );
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
&usage("You must specify at least a destination file.") if( ! @files );
my( $dest_file ) = pop( @files );
$cpi_vars::VERBOSITY if(0);
$cpi_vars::VERBOSITY = $ARGS{verbosity};
if( ! @files )
    {
    my $unknown_stdin = &tempfile(".unknown");
    &write_file( $unknown_stdin, &read_file("/dev/stdin") );
    my $mime_type = &read_file("file --mime '$unknown_stdin' |");
    $mime_type = $1 if( $mime_type =~ /.*: ([^;]+); .*/ );
    &fatal("Cannot determine mime type from stdin.") if( ! $mime_type );
    &read_mime_types();
    &fatal("Cannot determine extension from mime type [$mime_type].")
        if( ! $cpi_vars::MIME_TYPE_TO_EXTS{$mime_type} );
    my $ext = (sort keys %{$cpi_vars::MIME_TYPE_TO_EXTS{$mime_type}})[0];
    @files[0] = &tempfile(".$ext");
    rename( $unknown_stdin, $files[0] )
        || &fatal("Cannot rename $unknown_stdin to $files[0]:  $!");
    }
&generate_rules( $dest_file, @files );
&convert_file( $dest_file );
#&convert_file( $dest_file, @files );
&cleanup($exit_stat||0);
