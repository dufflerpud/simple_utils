#!/usr/bin/perl -w

use strict;

use lib "/usr/local/lib/perl";

use cpi_file qw( fatal read_file write_file cleanup );
use cpi_arguments qw( parse_arguments );
use cpi_compress_integer qw( compress_integer );

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
#	Remove various things that are not legal in old javascript.	#
#########################################################################
sub age_json
    {
    my( $str ) = @_;

    $str =~ s/\bconst\b/var/gms;	# Old javascript doesn't know "const"

    my @out_strings;

    foreach my $pc ( split(/\b(for\s*\(.*?\)\s*{)/ms,$str) )
        {
	if( $pc !~ /for\s*\(\s*var\s+([\w_]+)\s+(of|in)\s+(.*?)\s*\)(\s*)\{/ms )
	    { push( @out_strings, $pc ); }
	else
	    {
	    my $varname = $1;
	    my $inof = $2;
	    my $arrayname = $3;
	    my $whitespace = $4;
	    my $instance = &compress_integer( $ctr++ );
	    push( @out_strings,
		"var ${arrayname}_keys${instance}=Object.keys($arrayname); for( var ${varname}_ojs${instance}=0; ${varname}_ojs${instance}<${arrayname}_keys${instance}.length; ${varname}_ojs${instance}++ )${whitespace}{ var $varname=",
		( $inof eq "in"
		? "${arrayname}_keys${instance}\[${varname}_ojs${instance}\];"
		: "${arrayname}\[${arrayname}_keys${instance}\[${varname}_ojs${instance}\]\];"
		) );
	    }
	}

    # Yeah, we could just return the array and let write_file put it back
    # together again.  I just prefer the idea of string-in => string-out.
    return join("",@out_strings);
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
    &age_json(
	&read_file( $ARGS{input_file} ) ) );

&cleanup( $exit_stat );
