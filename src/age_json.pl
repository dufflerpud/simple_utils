#!/usr/bin/perl -w
#
#indx#	age_json.pl - Get rid of newer json to run on older hardware
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
#hist#	2026-04-13 - Christopher.M.Caldwell0@gmail.com - Created
########################################################################
#doc#	age_json.pl - Get rid of newer json to run on older hardware
########################################################################

use strict;

use lib "/usr/local/lib/perl";

use cpi_file qw( fatal read_file write_file cleanup );
use cpi_arguments qw( parse_arguments );
use cpi_compress_integer qw( compress_integer );
use cpi_cgi qw( older_json );

our %ARGS;
our $exit_stat = 0;

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
#	Main								#
#########################################################################

%ARGS = &parse_arguments( {
    switches=>
	{
	input_file	=> "/dev/stdin",
	output_file	=> "/dev/stdout",
	}
    } );

&write_file(
    $ARGS{output_file},
    &older_json(
	&read_file( $ARGS{input_file} ) ) );

&cleanup( $exit_stat );
