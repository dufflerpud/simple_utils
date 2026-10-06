#!/usr/bin/perl -w
#
#indx#	cd_rip.pl - Rip tracks off a CD
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
#hist#	2026-10-05 - Christopher.M.Caldwell0@gmail.com - Created
########################################################################
#doc#	Rip tracks off a CD
########################################################################

use strict;
use lib "/usr/local/lib/perl";

use cpi_file qw( fatal read_file write_file cleanup );
use cpi_arguments qw( parse_arguments );
use cpi_filename qw( text_to_filename );

# Put constants here

my $DEST_TYPE = "mp3";
my $CVT = "/usr/local/bin/nene";
our %ONLY_ONE_DEFAULTS =
    (
    "d"	=>	"/dev/cdrom",
    "i" =>	""
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
    &fatal( @_, "",
	"Usage:  $cpi_vars::PROG <possible arguments>","",
	"where <possible arguments> is:",
	"    -d <cdrom_device>",
	"    -i <file_with_track_tifles"
	);
    }

#########################################################################
#########################################################################
sub fix0s
    {
    return sprintf("%02d",$_[0]);
    }

#########################################################################
#	Read one track into the named file.  Looks for the next		#
#	available track number.						#
#########################################################################
sub read_track
    {
    my( $track_name ) = @_;
    my $track_ind = -1;
    my $track_ind_pretty;
    my @matching_files;
    do  {
	$track_ind_pretty = sprintf("%02d",++$track_ind);
	@matching_files = glob("$track_ind_pretty.*");
	} while ( @matching_files > 0 );
    my $basename = $track_ind_pretty . "." . &text_to_filename($track_name);
    my $dest_audio = $basename . "." . $DEST_TYPE;
    my $dest_inf = $basename . ".inf";
    if( &echodo( "cdda2wav -D $ARGS{d} -x -c 2 -s -t $track_ind" ) )
        {
	&echodo( "$CVT audio.wav $dest_audio" );
	&echodo( "mv audio.inf $dest_inf" );
	return $dest_audio;
	}
    return "";
    }

#########################################################################
#	Rip all the track on the CD.					#
#########################################################################
sub all_tracks
    {
    my $album = &read_file("/bin/pwd|");
    $album =~ s/_/ /g;
    my @lines = ( "<center><table>","<tr><th colspan=2>$album</th></tr>");
    my @titles;
    if( ! $ARGS{i} )
	{ @titles = map {sprintf("%02d",$_)} ( 1 .. 99 ); }
    else
	{
	open( INF, $ARGS{i} ) || &fatal("Cannot open ${ARGS{i}}:  $!");
	my @titles = <INF>;
	close( INF );
	chomp( @titles );
	}
    foreach my $title ( @titles )
	{
	my $filename = &read_track( $title );
	last if( ! $filename );
	push( @lines, "<tr><th>${title}:</th>",
	    "<td><a href=$filename>$filename</a></td></tr>" );
	}
    push( @lines, "</table></center>" );
    &write_file( "index.html", join("\n",@lines,"") );
    }

#########################################################################
#	Main								#
#########################################################################

if( $ENV{SCRIPT_NAME} )
    { &CGI_arguments(); }
else
    { &parse_arguments(); }

print join("\n\t","Args:",map{"$_:\t$ARGS{$_}"} sort keys %ARGS), "\n";

&all_tracks();

&cleanup($exit_stat);
