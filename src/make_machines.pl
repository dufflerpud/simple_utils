#!/usr/bin/perl -w
#
#indx#	make_machines.pl - Create hosts, ethers, and named cfg files from /etc/machines
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
#hist#	2026-03-19 - Christopher.M.Caldwell0@gmail.com - Created
########################################################################
#doc#	make_machines.pl - Create hosts, ethers, and named cfg files from /etc/machines
########################################################################

use strict;

use lib "/usr/local/lib/perl";
use cpi_file qw( fatal read_lines write_lines files_in echodo );
use cpi_template qw( template );
use cpi_time qw( time_string );
use cpi_arguments qw( parse_arguments );
use cpi_vars;

my $LC_DOMAIN	= lc( $cpi_vars::DOMAIN );
my $MACHINES	= "/etc/machines";
my $REDIRADDR	= "127.0.0.1";
#my $SERIAL	= &time_string("%04d%02d%02d%02d%02d");
my $SERIAL	= `date +%y%m%d%H%M`;   chomp( $SERIAL );
my $NAMED_PID	= "/var/run/named/named.pid";

our $exstat	= 0;
our @problems;

my @newlist;

#########################################################################
#	Print a usage message and die.					#
#########################################################################
sub usage
    {
    &fatal(@_,"","Usage:  $cpi_vars::PROG");
    }

#########################################################################
#	Read the machines file into a list of hashes.			#
#########################################################################
sub read_machine_entries
    {
    my( $filename ) = @_;
    my @entries;
    foreach my $line ( &read_lines( $filename ) )
	{
	$line =~ s/_/-/g;
	my( $ip, $ether, $primary, @aliases ) = split(/\s+/,$line);
	my $p = {};
	foreach my $tok ( split(/\s+/,$line) )
	    {
	    if( $tok =~ /^\w\w:\w\w:\w\w:\w\w:\w\w:\w\w$/ )
	        { $p->{MAC} = $tok; }
	    elsif( $tok =~ /^\d+\.\d+\.\d+\.\d+$/ )
	        { $p->{IPv4} = $tok; }
	    elsif( $tok =~ /:/ )
	        { $p->{IPv6} = $tok; }
	    elsif( ! $p->{Primary} )
	        { $p->{Primary} = $tok; }
	    else
	        {
		$p->{Aliases} ||= [];
	        push( @{$p->{Aliases}}, $tok );
	        }
	    }
	push( @entries, $p );
	}
    return @entries;
    }

#########################################################################
#	Return a standard header (with correct comment header)		#
#########################################################################
sub write_open
    {
    my( $fn, $comment ) = @_;
    print "Creating $fn.new\n";
    push( @newlist, $fn );
    return (
	"${comment}Do not modify this file.",
	"${comment}Modify $MACHINES and then run $cpi_vars::PROG.",
	${comment} );
    }

#########################################################################
#	Return a standard named config file header.			#
#########################################################################
sub top_domain
    {
    my( $fn ) = @_;
    return (
	&write_open( $fn, "; " ),
        &template( "$fn.template", "%SERIAL%", $SERIAL )
	);
    }

#########################################################################
#	Main								#
#########################################################################

my %ARGS = &parse_arguments({
    switches=>
	{
	input_file	=> $MACHINES,
	output_file	=> $MACHINES.&time_string(".%04d-%02d-%02d-%02d:%-02d"),
	hosts_file	=> "/etc/hosts",
	ethers_file	=> "/etc/ethers",
	named_files	=> "/var/named",
	redirects	=> "/etc/host_redirects",
	fields		=> "IPv4,IPv6,MAC,Primary,Aliases",
	verbosity	=> 0
	}
    });

$cpi_vars::VERBOSITY	= $ARGS{verbosity};

my @entries		= &read_machine_entries( $ARGS{input_file} );

my @ethers		= &write_open( $ARGS{ethers_file}, "#" );
my @hosts		= &write_open( $ARGS{hosts_file}, "#" );
my @pretty		= &write_open( $ARGS{output_file}, "#" );
my @nameds		= &top_domain( "$ARGS{named_files}/$LC_DOMAIN" );

my %widths;
foreach my $e ( @entries )
    {
    foreach my $f ( keys %{$e} )
	{
	$widths{$f} ||= length($f);
	my $s = (ref($e->{f}) eq "ARRAY" ? join(" ",@{$e->{$f}}) : $e->{$f} );
	my $l = length($s);
	$widths{$f} = $l if( $l > $widths{$f} );
	}
    }

my @FIELDS = split(/,/,$ARGS{fields});
my $field_line;
my $fldnum = 0;
foreach my $f ( @FIELDS )
    {
    if( $widths{$f} )
        {
	my $txt = ( $fldnum++==0 ? "#$f" : $f );
	$field_line .= sprintf("%-$widths{$f}s ",$txt);
	}
    }
$field_line =~ s/\s*$//;

push( @pretty, $field_line );

my $name;
foreach my $e ( @entries )
    {
    my $field_line = "";
    foreach my $f ( @FIELDS )
        {
	my $s = "";
	$s = ( ref($e->{$f}) eq "ARRAY" ? join(" ",@{$e->{$f}}) : $e->{$f} )
	    if( $e->{$f} );
	$field_line .= sprintf("%-$widths{$f}s ",$s);
	}
    $field_line =~ s/\s*$//;
    push( @pretty, $field_line );
    if( ($name=$e->{Primary}) && ($name =~ /\w/) )
	{
	my $val = $e->{MAC};
	push( @ethers, "$val\t$name" ) if( $val && $val =~ /:/ );

	foreach $val ( $e->{IPv4}, $e->{IPv6} )
	    {
	    if( $val && $val =~ /\w/ )
	        {
		push( @hosts, $val. "\t".
		    join(" ",
			map { $_, "$_.$LC_DOMAIN" } ( $name, @{$e->{Aliases}} ) ) );

		my $rectype = ( $val =~ /:/ ? "AAAA" : "A" );
		push( @nameds, "$name\t$rectype\t$val",
		    ( map { "$_\tCNAME\t$name" } @{$e->{Aliases}} ) );
		}
	    }
	}
    }

push( @hosts, "", "# Redirect common advertising servers to nowhere." );
foreach my $line ( &read_lines($ARGS{redirects}) )
    {
    my( @names ) = split(/\s+/,$line);
    push( @hosts, $REDIRADDR. "\t". join(" ",@names) ) if( @names );
    }
&write_lines( "$ARGS{ethers_file}.new", @ethers );
&write_lines( "$ARGS{hosts_file}.new", @hosts );
&write_lines( "$ARGS{named_files}/$LC_DOMAIN.new", @nameds );
&write_lines( "$ARGS{output_file}.new", @pretty );

# For now, we are ignoring ipv6 PTR records.
foreach my $revfile ( &files_in( $ARGS{named_files} ) )
    {
    if( $revfile =~ /^([\d\.]+)\.template/ )
	{
	my $rev = $1;
	my @ptrs = ( &top_domain( "$ARGS{named_files}/$rev" ) );
	foreach my $e ( @entries )
	    {
	    if( $e->{Primary} && $e->{IPv4} && ($e->{IPv4} =~ /^$rev\.([\d\.]+)/) )
		{
		push( @ptrs, join(".",reverse( split(/\./,$1))) .
		    "\tPTR\t" . $e->{Primary} . ".$LC_DOMAIN." );
		}
	    }
	&write_lines( "$ARGS{named_files}/$rev.new", @ptrs );
	}
    }

if( $exstat == 0 )
    {
    foreach my $fn ( @newlist )
	{
	chmod( 0644, "$fn.new" ) || die("Cannot chmod 644 $fn.new:  $!");
	rename( "$fn.new", $fn ) || die("Cannot rename $fn.new to $fn  $!");
	}
    if ( ! -r $NAMED_PID )
	{ print STDERR "No $NAMED_PID so cannot update named.\n"; }
    else
        { &echodo("kill -HUP `cat $NAMED_PID`"); }
    }

exit( $exstat );
