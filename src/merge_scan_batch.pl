#!/usr/local/bin/perl -w
#
#indx#	merge_scan_batch - Collect multiple pages into a single document
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
#doc#	merge_scan_batch - Collect multiple pages into a single document
#doc#	Generally takes a bunch of .pnm files to create a .pdf files, but
#doc#	input can be any single-page-images.  Smart enough to order PDF
#doc#	pages based on images scanned from two sided documents.
########################################################################

use strict;

use lib "/usr/local/lib/perl";

use cpi_vars;
use cpi_arguments qw( parse_arguments );
use cpi_file qw( fatal fqfiles_in cleanup echodo write_file );
use cpi_filename qw( just_ext_of );
use cpi_sortable qw( numeric_sort );

our %ARGS;
our @problems;

my $CVT		= "/usr/local/bin/nene";
my $PAMCUT_EXT	= "pnm";
#my $end_ext	= "jpg";
my $exit_stat	= 0;

#########################################################################
#	Print usage message and die.					#
#########################################################################
sub usage
    {
    &fatal( @_, "Usage:  $cpi_vars::PROG -o <output_file> <side 1 directory> <side 2 directory>" );
    }

#########################################################################
#	Main								#
#########################################################################

my @files;
%ARGS = &parse_arguments( {
    non_switches		=>	\@files,
    switches=>
	{
	"output_file"		=>	"",
	"pamcut_arguments"	=>	"",
	"flip"			=>	1,
	"verbosity"		=>	0
	}
    } );

if( ! $ARGS{output_file} )
    { push(@problems,"-output_file not specified"); }
elsif( -e $ARGS{output_file} )
    { push(@problems,"$ARGS{output_file} already exists."); }

&usage(@problems) if(@problems);

$cpi_vars::VERBOSITY = $ARGS{verbosity};

my @new_files;
my $srcfile;
my $end_ext = &just_ext_of( $ARGS{output_file} );
while( defined( $srcfile = shift(@files) ) )
    {
    if( -d $srcfile )
	{ @files = ( &numeric_sort(&fqfiles_in($srcfile)), @files ); }
    else
	{ push( @new_files, $srcfile ); }
    }
@files = @new_files;
@new_files = ();

my $tmpdir;
my @cmds;
my $ind = 0;
while( @files )
    {
    if( ! $ARGS{flip} || $ind % 2 == 0 )
	{ $srcfile = shift(@files); }
    else
	{ $srcfile = pop(@files); }

    my $srcext = &just_ext_of($srcfile);
    $srcfile = "'$srcfile'";
    if( $srcext eq $end_ext && ! $ARGS{pamcut_arguments} )
	{ push(@new_files,$srcfile); }
    else
	{
	if( ! $tmpdir )
	    {
	    $tmpdir = $tmpdir="/tmp/$cpi_vars::PROG.$$";
	    push( @cmds, "rm -rf '$tmpdir'; mkdir -p '$tmpdir'" );
	    }
	push(@new_files,"'$tmpdir/$ind.$end_ext'");
	if( ! $ARGS{pamcut_arguments} )
	    { push(@cmds, "$CVT -v=$ARGS{verbosity} $srcfile $new_files[-1]" ); }
	elsif( $srcext eq $PAMCUT_EXT )
	    {
	    if( $PAMCUT_EXT eq $end_ext )
	        { push(@cmds,"pamcut $ARGS{pamcut_arguments} $srcfile > $new_files[-1]"); }
	    else
	        { push(@cmds,"pamcut $ARGS{pamcut_arguments} $srcfile"
		    . " | $CVT -v=$ARGS{verbosity} -.$PAMCUT_EXT $new_files[-1]" ); }
	    }
	else
	    {
	    if( $PAMCUT_EXT eq $end_ext )
	        { push(@cmds,"$CVT -v=$ARGS{verbosity} $srcfile -.$PAMCUT_EXT"
		    . " | pamcut $ARGS{pamcut_arguments} - > $new_files[-1]"); }
	    else
	        { push(@cmds,"$CVT -v=$ARGS{verbosity} $srcfile -.$PAMCUT_EXT"
		    . " | pamcut $ARGS{pamcut_arguments} - "
		    . " | $CVT -v=$ARGS{verbosity} -.$PAMCUT_EXT $new_files[-1]" ); }
	    }
	}
    $ind++;
    }
@files = @new_files;

push( @cmds, join(" ","cat_media -v=$ARGS{verbosity}",@files,"-o '$ARGS{output_file}'") );
push( @cmds, "rm -rf '$tmpdir'" ) if( $tmpdir );

&usage(@problems) if( @problems );

#&write_file( "/tmp/merge.cmds", join("\n",@cmds,"") );
&echodo( join("; ",@cmds) );
print $_, "\n" foreach @cmds;

&cleanup( $exit_stat );
