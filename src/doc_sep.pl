#!/usr/bin/perl -w
#
#indx#	doc_sep.pl - Filter out all but the specified headers for documentation
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
#doc#	doc_sep.pl - Filter out all but the specified headers for documentation.
#doc#	Can also be used to remove documentation to leave just source
########################################################################

use strict;

use lib "/usr/local/lib/perl";

use cpi_file qw( fatal read_file write_lines cleanup );
use cpi_arguments qw( parse_arguments );
use cpi_cgi qw( older_json );

our %ARGS;
our $exit_stat = 0;
our @files;

#########################################################################
#	Print an error, usage message and die.				#
#########################################################################
sub usage
    {
    &fatal( @_,
	"Usage:  $cpi_vars::PROG -i <input file> -o <output_file>"
	);
    }

#########################################################################
#	Sift through file keeping only the documentation lines or	#
#	removing those lines.						#
#########################################################################
sub filter
    {
    my( $str ) = @_;
    my @lines;
    foreach my $ln ( split(/\n/ms,$str) )
	{
	if( $ln =~ /^$ARGS{filter}(.*)/ )
	    {
	    push( @lines, $1 ) if( $ARGS{mode} eq "for" );
	    }
	else
	    {
	    push( @lines, $ln ) if( $ARGS{mode} eq "against" );
	    }
	}
    return @lines;
    }

#########################################################################
#	Main								#
#########################################################################

%ARGS = &parse_arguments( {
    switches=>
	{
	input_file	=> "/dev/stdin",
	output_file	=> "/dev/stdout",
	filter		=> "#doc#",
	mode		=> [ "for", "against" ]
	},
    non_switches=>\@files
    } );

my @lines;
if( ! @files )
    { push( @lines, &filter( &read_file( $ARGS{input_file} ) ) ); }
else
    {
    foreach my $fname ( @files )
        { push( @lines, &filter( &read_file( $fname ) ) ); }
    }

&write_lines( $ARGS{output_file}, @lines );

&cleanup( $exit_stat );
