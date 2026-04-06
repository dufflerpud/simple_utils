#!/usr/bin/perl -w
#
#indx#	sanifile - Fix filenames to be UNIX friendly and convert to standard types
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
#doc#	sanifile - Fix filenames to be UNIX friendly and convert to standard types
#doc#	<li>For instance, the standard movie is quicktime .mov.</li>
#doc#	<li>The standard for a still pic is .jpeg.</li>
#doc#	<li>The standard for still audio is .mp3, etc.</li>
#doc#	Convenient to apply to directories to quickly make sense of them.
########################################################################

use strict;

#use Data::Dumper;

use lib "/usr/local/lib/perl";

use cpi_filename qw( text_to_filename );
use cpi_file qw( echodo fatal );
use cpi_arguments qw( parse_arguments );
use cpi_mime qw( read_mime_types );
use cpi_vars;

# Put constants here

my $TMP = "/tmp/$cpi_vars::PROG.$$";
my $MIME_TYPES = "/etc/mime.types";
my $CVT = "$cpi_vars::USRLOCAL/bin/nene";

my %BASE_TYPE_TO_EXT =
    (
    "image"		=> "jpg",
    "video"		=> "mov",
    "movie"		=> "mov",
    "audio"		=> "mp3",
    "text"		=> "txt",
    "gif"		=> "gif"
    );

# Put variables here.

our @problems;
our %ARGS;
our @files;
our $exit_stat = 0;

# Put interesting subroutines here

#########################################################################
#	Print usage message and die.					#
#########################################################################
sub usage
    {
    my @maps=map{"\t$_\tto $BASE_TYPE_TO_EXT{$_}"} sort keys %BASE_TYPE_TO_EXT;
    &fatal( @_, "",
	"Usage:  $cpi_vars::PROG { <arg> } <file1> <file2> <file3> ...",
	"    Where <arg> is one of:",
	"\t-debug <debug level>",
	"\t-mode yes|no|question",
	"\t-yes                  (equivelent to -mode yes)",
	"\t-no                   (equivalent to -mode no)",
	"\t-question             (equivalent to -mode question)",
	"",
	"Sanitize all file names and convert all files of type:",
	@maps
	);
    }

#########################################################################
#	Echo what we would or are going to do.				#
#	Then do it or not depending on if -n was set.			#
#########################################################################
sub echondo
    {
    my( $cmd ) = join(" ",@_);
    if( $ARGS{mode} eq "no" )
	{
	print STDERR "Would have:  $cmd\n";
	return 0;
	}
    if( $ARGS{mode} eq "question" )
	{
	while (1)
	    {
	    print STDERR "Execute \"$cmd\"?  ";
	    my $ans = <STDIN>;
	    exit(1)	if( ! defined( $ans ) );
	    chomp($ans);
	    return 0	if( $ans =~ /^\s*n/i );
	    last	if( $ans =~ /^\s*y/i );
	    print STDERR "You must answer 'y' or 'n'.\n" if( $ans ne "" );
	    }
	}
    &echodo( $cmd );
    }

#########################################################################
#	Change filename to something more sane, convert file type if	#
#	appropriate.							#
#########################################################################
sub process_files
    {
    my @chmod_list = ();
    my @rm_list = ();

    foreach my $ofn ( @files )
	{
	# Create a saner name based on the old filename
	my $nfn = &text_to_filename($ofn);

	my $old_mime_type;		# Assume we don't know type of file
	my $new_mime_type;		# (Not set)
	my $base_type;
	if( $nfn =~ m:(.*)\.(.*?)$: )	# Does it have an extension?
	    {
	    my($base,$ext) = ($1,$2);	# Yes!  Look extension up in table
	    $ext =~ tr/A-Z/a-z/;
	    if( ($old_mime_type = $cpi_vars::EXT_TO_MIME_TYPE{$ext})
	     && ($base_type = $cpi_vars::MIME_TYPE_TO_BASE_TYPE{$old_mime_type})
	     && ($ext = $BASE_TYPE_TO_EXT{$base_type})
	     && ($new_mime_type = ($cpi_vars::EXT_TO_MIME_TYPE{$ext})||0) )
		{
		print STDERR join("\n\t",$ofn,
		    "base=$base",
		    "old_mime_type=$old_mime_type",
		    "base_type=$base_type",
		    "ext=$ext",
		    "new_mime_type=$new_mime_type"), "\n"
		    if( $ARGS{debug} >= 1 );
		$nfn = "$base.$ext";
		}
	    }
	
	if( $ofn eq $nfn )
	    {
	    print STDERR "${ofn}:  Nothing to do.\n" if( $ARGS{debug} >= 1 );
	    }
	elsif( -e $nfn )
	    { print STDERR "${ofn}:  Skipped ($nfn already exists).\n"; }
	elsif( !$new_mime_type || $new_mime_type eq $old_mime_type )
	    { &echondo( "mv \"$ofn\" \"$nfn\"" ); }
	else
	    {
	    echondo( "$CVT -v$ARGS{verbosity} \"$ofn\" \"$nfn\"" );
	    if( -s "$nfn" )	# If file size > 0
		{ push( @rm_list, $ofn ); }
	    else
		{
		print STDERR "${ofn}:  Could not create ${nfn}.\n"
		    if( $ARGS{mode} eq "yes" );
		push( @rm_list, $nfn ) if( -e "$nfn" );
		}
	    }

	push( @chmod_list, $nfn ) if( -e $nfn && ! -r $nfn );
	}

    &echondo( "chmod u+rw " . join(" ",(map{"'$_'"} @chmod_list)))
	if(@chmod_list);
    &echondo( "rm -f " . join(" ",(map{"'$_'"} @rm_list)))
	if(@rm_list);
    }

#########################################################################
#	Main								#
#########################################################################

if( $ENV{SCRIPT_NAME} )
    { &CGI_arguments(); }
else
    {
    %ARGS = &parse_arguments( {
	non_switches		=> \@files,
	min_non_switches	=> 1,
	switches=>
	    {
	    "debug"		=> 0,
	    "verbosity"		=> 1,
	    "mode"		=> [ "yes", "no", "question" ],
	    "yes"		=> { alias=>[ "-mode", "yes" ] },
	    "no"		=> { alias=>[ "-mode", "no" ] },
	    "question"		=> { alias=>[ "-mode", "question" ] },
	    } } );
    }

$cpi_vars::VERBOSITY = $ARGS{verbosity};

&read_mime_types();
&process_files();

exit($exit_stat);
