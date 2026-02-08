#!/usr/bin/perl -w

use strict;

use lib "/usr/local/lib/perl";

use cpi_file qw( fatal read_file write_file cleanup );
use cpi_arguments qw( parse_arguments );
use cpi_compress_integer qw( compress_integer );
use cpi_cgi qw( older_json );

our %ARGS;
our $exit_stat = 0;
my $ctr = 0;

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
