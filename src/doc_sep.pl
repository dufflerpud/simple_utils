#!/usr/bin/perl -w
#
#indx#	doc_sep - Filter out all but the specified headers for documentation
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
#doc#	doc_sep - Filter out all but the specified headers for documentation.
#doc#	Can also be used to remove documentation to leave just source
########################################################################

use strict;

use lib "/usr/local/lib/perl";

use cpi_file qw( fatal read_file write_lines fqfiles_in cleanup );
use cpi_arguments qw( parse_arguments );
use cpi_filename qw( distill_filename glob_from );
use cpi_compress_integer qw( compress_integer );
use cpi_cgi qw( older_json );

our %ARGS;
our $exit_stat = 0;
our @files;

my $tag_ind = time() * 1000000 + $$;

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
#	Handle includes							#
#########################################################################
sub do_include
    {
    my( $curdir_spec, $filename_spec, $indexp, $docp ) = @_;
    my $tag;
    my $current_topic;
    #print STDERR "curdir=$curdir filename=$filename\n";
    foreach my $filename ( glob($filename_spec) )
	{
	my $curdir = $curdir_spec;
	if( $filename =~ m:^(\/.*?)([^/]*)$: )
	    { $curdir = $1; }
	else
	    {
	    $filename = "$curdir/$filename";
	    $curdir = $1 if( $filename =~ m:^(.*)/(.*?)$: );
	    }
	$filename = &distill_filename( $filename );
	if( -d $filename )
	    {
	    foreach my $filename_in_dir ( &fqfiles_in( $filename ) )
		{
		&do_include( $curdir, $filename_in_dir, $indexp, $docp );
		}
	    }
	elsif( -f $filename )
	    {
	    foreach my $line ( split(/\n/,&read_file($filename)) )
		{
		if( $line =~ /^[^\w]*indx#\s*\**([^\s]+)\**[:\-\s]*(.*?)$/ )
		    {
		    $tag = "dt_".&compress_integer( $tag_ind++ );
		    $current_topic = $1;
		    push( @{$indexp}, "<tr><th align=left><a href='#$tag'>$current_topic</a></th><td>$2</td></tr>" );
		    }
		elsif(  $line =~ /^[^\w]*doc#\s*(.*?)-\s*(.*?)$/ 
		 ||	    $line =~ /^[^\w]*doc#(\s*)(.*?)$/ )
		    {
		    push( @{$docp}, "\n## <a id='$tag'>$current_topic</a>" ) if( $current_topic );
		    undef $current_topic;
		    push( @{$docp}, $2 );
		    }
		if( $line =~ /^[^\w]*include#\s*(.*)$/ )
		    {
		    &do_include( $curdir, $1, $indexp, $docp );
		    }
		}
	    }
	else
	    { &fatal("${filename} has bogus type."); }
	}
    }

#########################################################################
#	Main								#
#########################################################################

%ARGS = &parse_arguments( {
    switches=>
	{
	#input_file	=> "/dev/stdin",
	input_file	=> "README.template",
	#output_file	=> "/dev/stdout",
	output_file	=> "README.md",
	},
    non_switches=>\@files
    } );

my @indices;
my @docs;
my $old_contents = &read_file( $ARGS{input_file} );
my $new_contents;
if( $old_contents !~ m:(.*<table[^>]*?src=")(.*?)("[^>]*?>)(.*?)(</table>.*<div id=docs>)(.*?)(</div>.*):ms )
    { &fatal("$ARGS{input_file} does not look like useful to doc_sep."); }
else
    {
    my( $preamble, $src, $postamble, $table, $prediv, $div, $postdiv ) = ( $1, $2, $3, $4, $5, $6, $7, $8 );
    &do_include( ".", $src, \@indices, \@docs );
    $table = join("\n",@indices);
    $div = join("\n","",@docs);
    my $new_contents = "$preamble$src$postamble$table$prediv$div$postdiv";
    if( $old_contents eq $new_contents )
	{ print STDERR "There is no change to $ARGS{input_file}.\n"; }
    else
	{ &write_lines( $ARGS{output_file}, $new_contents ); }
    &cleanup( $exit_stat );
    }
