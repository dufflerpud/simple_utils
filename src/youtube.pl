#!/usr/bin/perl -w
#
#indx#	youtube.pl - Convenient interface yt-dlp to download youtube videos
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
#doc#	youtube.pl - Convenient interface yt-dlp to download youtube videos
#doc#	In particular, maintain a list of files (youtube.list) in CWD
#doc#	with media and where it came from.
########################################################################

use strict;

use lib "/usr/local/lib/perl";
use cpi_file qw( fatal read_file write_file echodo );
use cpi_cgi qw( CGIreceive );
use cpi_arguments qw( parse_arguments );
use cpi_vars;
use cpi_filename qw( text_to_filename just_ext_of );
use cpi_inlist qw( inlist );

# Put constants here

my $PROG = ( $_=$0, s+.*/++, $_ );
my $TMP = "/var/tmp/$PROG.$$";
#my $YTDLP = "/usr/local/bin/youtube-dl";
my $YTDLP = "/bin/yt-dlp -4";
our %ONLY_ONE_DEFAULTS =
    (
    "album"		=>	"youtube.list",
    "d"			=>	"$YTDLP -q",
    "title"		=>	"$YTDLP --get-title",
    "u"			=>	"$YTDLP -g",
    "converter"		=>	"/usr/local/bin/nene",
    "maximum"		=>	"",
    "mplayer"		=>	"/bin/mplayer -really-quiet",
    "trim"		=>	"/home/chris/bin/trim",
    "ffmpegargs"	=>	"",
    "output"		=>	"",
    "input"		=>	"",
    "begin"		=>	0,
    "end"		=>	0,
    "verbosity"		=>	0
    );

# Put variables here.

our @problems;
our %ARGS;
our @files;
our $exit_stat = 0;

# Put interesting subroutines here

#=======================================================================#
#	New code not from prototype.pl					#
#		Should at least include:				#
#			parse_arguments()				#
#			CGI_arguments()					#
#			usage()						#
#=======================================================================#

#########################################################################
#	Setup arguments if CGI.						#
#########################################################################
sub CGI_arguments
    {
    &CGIreceive();
    }

#########################################################################
#	Print usage message and die.					#
#########################################################################
sub usage
    {
    &fatal( @_, "",
	"Usage:  $PROG <possible arguments>","",
	"where <possible arguments> is:",
	"\t-album <album file> (youtube.list)",
	"\t-d ($YTDLP -q)",
	"\t-title ($YTDLP --get-title)",
	"\t-u ($YTDLP -g)",
	"\t-converter (/usr/local/bin/nene)",
	"\t-maximum <maximum number to download>",
	"\t-mplayer <media player> (/bin/mplayer -really-quiet)",
	"\t-trim <trim program> (/home/chris/bin/trim)",
	"\t-ffmpegargs <args to hand to ffmpeg>",
	"\t-output <output file>",
	"\t-input <input URL>",
	"\t-begin <time to start encoding>",
	"\t-end <time to stop encoding>",
	"\t-verbosity <how much debug output to write>"
	);
    }

#########################################################################
#	Grab the file off youtube and convert to desired output file.	#
#########################################################################
sub youtube_grab
    {
    my( $infile, $outfile ) = @_;

    my $url = ($infile=~/:/ ? "" : "https://youtube.com/watch?v=") . $infile;
    if( $outfile eq "" )
	{
	&echodo("$ARGS{mplayer} '$url'");
	}
    elsif( grep( $_ eq $outfile, "audio", "video" ) )
	{
	print "+ $ARGS{u} '$url'\n" if( $ARGS{verbosity} );
	open( INF, "$ARGS{u} '$url' |" ) || &fatal("Cannot run $ARGS{u}:  $!");
	my @lines = <INF>;
	close( INF );
	my $newurl = $lines[ ( $outfile eq "video" ? 0 : 1 ) ];
	chomp( $newurl );
	my $cmd = $ARGS{mplayer}
	    . ( $outfile eq "video" ? "" : " -vc null -vo null" )
	    . ( $outfile eq "audio" ? "" : " -ac null -ao null" );
	print "+ $cmd '$newurl'" if( $ARGS{verbosity} );
	&echodo("$cmd '$newurl'");
	}
    else
	{
	my ( $dir, $fl, $ext );
	if( $outfile =~ m:^(.*)/([^/]*)\.([a-zA-Z0-9]+): )
	    { ( $dir, $fl, $ext ) = ( $1, $2, $3 ); }
	elsif( $outfile =~ m:^([^/]*)\.([a-zA-Z0-9]+): )
	    { ( $dir, $fl, $ext ) = ( ".", $1, $2 ); }
	elsif( $outfile =~ m:^(.*)\/([^/]+)$: )
	    { ( $dir, $fl, $ext ) = ( $1, $2, "mov" ); }
	else
	    { ( $dir, $fl, $ext ) = ( ".", $outfile, "mov" ); }
	#print "dir=[$dir] fl=[$fl] ext=[$ext]\n" if( $ARGS{verbosity} );
	if( $fl eq "" )
	    {
	    print "+ $ARGS{t} '$url'\n" if( $ARGS{verbosity} );
	    open( INF, "$ARGS{t} '$url' |" ) || &fatal("Cannot run $ARGS{t}:  $!");
	    $fl = <INF>;
	    close( INF );
	    chomp( $fl );
	    $fl =~ s/[^A-Za-z0-9\.\-]+/_/g;
	    $fl =~ s/_*-_*/-/g;
	    $fl = $1 if( $fl =~ /^_*(.+?)_*$/ );
	    $outfile = ( $dir eq "." ? "$fl.$ext" : "$dir/$fl.$ext" );
	    }
	print "Retrieving $outfile ...\n" if( $ARGS{verbosity} );
	&echodo("$ARGS{d} '$url' -o $TMP");
	my $current_file = &read_file("ls $TMP.* 2>/dev/null |");
	chomp( $current_file );
	&fatal("No file retrieved.") if( $current_file !~ /\.(.*?)$/ );
	my $current_ext = $1;
	my $new_file = $outfile;
	if( $ARGS{ffmpegargs} )
	    {
	    $new_file = "$TMP.an.$ext";
	    &echodo("ffmpeg -loglevel error -i $current_file $ARGS{ffmpegargs} $new_file");
	    $current_file = $new_file;
	    }
	if( $ARGS{begin} || $ARGS{end} )
	    {
	    $new_file = "$TMP.trimmed.$ext";
	    &echodo( "$ARGS{trim} -i '$current_file' -o '$new_file"
		. ( $ARGS{begin} ? " -b $ARGS{begin}" : "" )
		. ( $ARGS{end} ? " -e $ARGS{end}" : "" ) );
	    $current_file = $new_file;
	    }
	if( $current_file eq $outfile )
	    { }		# Will never happen
	elsif( $current_file =~ /.*\.(.*?)$/ && $1 eq $ext )
	    { &echodo("mv '$current_file' '$outfile'"); }
	else
	    { &echodo("$ARGS{converter} -v$ARGS{verbosity} '$current_file' '$outfile'"); }
	}
    }

#########################################################################
#	Get a bunch of different files from youtube.			#
#########################################################################
sub do_album
    {
    my $counter = 0;
    foreach my $line ( split(/\n/,&read_file($ARGS{album})) )
	{
	my( $ytcode, @name_pieces ) = split(/\s/,$line);
	my $filename = &text_to_filename( join("_",@name_pieces) );
	$filename = "$ARGS{output}/$filename" if( $ARGS{output} );
	$filename.=".mp3"
	    if( ! &inlist( &just_ext_of($filename),"mp3","mov") );
	if( ! -s $filename )
	    {
	    if( $ARGS{maximum} eq "" )
	        { &youtube_grab( $ytcode, $filename ); }
	    elsif( $ARGS{maximum} == $counter )
		{ print "To do:\n$line\n"; }
	    elsif( $counter > $ARGS{maximum} )
		{ print $line, "\n"; }
	    else
	        { &youtube_grab( $ytcode, $filename ); }
	    $counter++;
	    }
	}
    }

#########################################################################
#	Main								#
#########################################################################

if( $ENV{SCRIPT_NAME} )
    { &CGI_arguments(); }
else
    {
    %ARGS = &parse_arguments
        ({
	non_switches	=> \@files,
	switches	=> \%ONLY_ONE_DEFAULTS
	});
    }

$cpi_vars::VERBOSITY = $ARGS{verbosity};

push( @files, $ARGS{input} ) if( $ARGS{input} );

if( @files )
    { grep( &youtube_grab($_,$ARGS{output}), @files ); }
else
    { &do_album(); }

exit($exit_stat);
