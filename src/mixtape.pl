#! /usr/bin/perl -w
#
#indx#	mixtape - Create collections, or play randomly from collection
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
#doc#	mixtape - Create music collections, or play randomly from collection
#doc#	or simply play random music from a specified directory.
########################################################################

use strict;

use lib "/usr/local/lib/perl";
use cpi_file qw( read_file read_lines echodo fatal first_in_path );
use cpi_media qw( player );
use cpi_reorder qw( reorder );
use cpi_arguments qw( parse_arguments );
use cpi_vars;

my %ONLY_ONE_DEFAULTS =
    (
    "directory"		=>	"$ENV{HOME}/Music/.",
    "URL"		=>	"http://fs0.brightsands.com:8081/~chris/Music",
    "output_file"	=>	"",
    "mode"		=>	[	"continuous_play",
					"verify",
					"regenerate",
					"list",
					"cat",
					"browser"		],
    "list"		=>	{ alias=>[ "-mode", "list" ] },
    "verify"		=>	{ alias=>[ "-mode", "verify" ] },
    "cgi"		=>	{ alias=>[ "-mode", "cgi" ] },
    "cat"		=>	{ alias=>[ "-mode", "cat" ] },
    "player"		=>	"",
    "verbosity"		=>	0,
    "amplitude"		=>	100
    );

# Put variables here.

our @problems;
my %ARGS;

our $exit_stat = 0;
my @descs_todo;

$| = 1;

#########################################################################
#	Get a list of files adhering to the supplied criteria.		#
#########################################################################
sub find_list
    {
    my $cmd = "find $ARGS{directory} $_[0] ! -name 'all.mp3' -print";
    open( INF, "$cmd |" ) || &fatal("Cannot open $cmd pipe:  $!");
    chomp( my @files = <INF> );
    close( INF );
    grep( s+/./+/+g, @files );
    return @files;
    }

#########################################################################
#	Generate a hash of search string lists.				#
#########################################################################
my %search_strings;
sub create_search_strings
    {
    foreach my $fn ( &find_list("-name '*.desc'") )
	{
	$fn =~ m+.*/(.*?)\.desc$+;
	my $file_type = $1;
	my @desc = &read_lines( $fn );
	push( @{$search_strings{$file_type}}, @desc );
	}
    }

#########################################################################
#	Create a hash of file lists by type.				#
#########################################################################
my %fnlist;
sub create_fnlist
    {
    @{$fnlist{all}} = &find_list("-name '*.mp3'");

    foreach my $type_string ( keys %search_strings )
	{
	#print "Defining fnlist{$type_string}...\n";
	foreach my $str ( @{$search_strings{$type_string}} )
	    {
	    my @generated = grep( m=$str=, @{$fnlist{all}} );
	    if( @generated )
	        { push( @{$fnlist{$type_string}}, @generated ); }
	    else
	        {
		print STDERR "\"$str\" in $type_string matches nothing.\n";
		$exit_stat ||= 1;
		}
	    }
	}
    }

#########################################################################
#	Generate song list from list of descriptions.			#
#########################################################################
sub generate_song_list
    {
    my( @descs_todo ) = @_;
    # Create a hash containing all songs to play.
    # Use hash to make sure we only have one occurance
    # of a song even if it appears on multiple lists.
    my %song_hash;
    foreach my $desc ( @descs_todo )
	{
	if( $ARGS{verbosity} )
	    { print join("\n\t","Songs from $desc:",@{$fnlist{$desc}}),"\n"; }
	else
	    { print "Generating songs for $desc...\n"; }
	grep( $song_hash{$_}=1, @{$fnlist{$desc}} );
	}
    return keys %song_hash;
    }

#########################################################################
#	Just print out a randomized song list.				#
#########################################################################
sub cmd_list
    {
    print join("\n",&reorder( @_ ),"");
    }

#########################################################################
#	Create single mp3 from a randomized song list.			#
#########################################################################
sub cat_list
    {
    my( $outfile, @song_list ) = @_;
    &echodo( "cat_sounds -o '"
        . join("' '",$outfile,&reorder(@song_list))
	. "'" );
    }

##########################################################################
##	Output songs to browser.					#
##########################################################################
#sub old_cgi_list
#    {
#    my( @song_list ) = @_;
#    print "Content-type:  audio/mp3\n\n",
#	grep( &read_file($_), &reorder(@song_list) );
#    }

#########################################################################
#	Output songs to browser.					#
#########################################################################
sub cgi_list
    {
    my( @song_list ) = @_;
    #print "Content-type:  text/html\n\n";
    my @urls = 
	map { "#EXTINF:-1\n$ARGS{URL}/$_" }
	&reorder(@song_list);
    #print join("<br>","URLS:",@urls);
    print join("\n",
        "Content-type:  audio/x-mpegurl\n\n#EXTM3U",
	@urls),
	"\n";
    }

#########################################################################
#	Continually play from a randomize song list.			#
#########################################################################
sub continually_play_list
    {
    my( @song_list ) = @_;

    while( 1 )
	{
	foreach my $song ( &reorder( @song_list ) )
	    {
	    $song =~ s+^\./++;
	    print "[$song]\n";
	    &player(
		{
		amplitude	=> $ARGS{amplitude},
		player		=> $ARGS{player}
		}, $song );
	    }
	}
    }

#########################################################################
#	Print a usage message and die.					#
#########################################################################
sub usage
    {
    &fatal( @_, "",
	"Usage:  $cpi_vars::PROG {<arg>} <description>",
	"where <arg> is one of:",
	"	-mode <mode>",
	"	-amplitude <audio level> (0-100)",
	"	-output_file <file>.mp3",
	"	-verbosity <verbosity_level> (0 or 1)",
	"	-player mplayer | paplay",
	"where <mode> is one of:",
	"	list (also -list)",
	"	verify (also -verify)",
	"	cgi (also -cgi)",
	"	cat (also -cat, implied with -output_file)",
	"where <description> is one of:",
		( map{"\t$_"} sort keys %search_strings )
	);
    }

#########################################################################
#	Setup arguments if CGI.						#
#########################################################################
sub CGI_arguments
    {
    &CGIreceive();
    @descs_todo = ( $cpi_vars::FORM{desc} || "all" );
    $ARGS{mode} = "browser";
    }

#########################################################################
#	Actually come up with songs per song description.		#
#########################################################################
sub spin_some_songs
    {
    my @song_list;
    @descs_todo = ("all") if( ! @descs_todo );

    #chdir( $ARGS{directory} ) || &fatal("Cannot chdir($ARGS{directory}:  $!");
    #
    &create_search_strings();

    &usage( "No description specified." ) if( ! @descs_todo );

    srand();
    &create_fnlist();

    if( $ARGS{mode} eq "verify" )
        { exit($exit_stat); }
    elsif( $ARGS{mode} eq "regenerate" )
        {
	foreach my $descext ( @descs_todo )
	    {
	    my $descname = ( $descext =~ /^(.*)\.desc$/ ? $1 : $descext );
	    if( ! ( @song_list = &generate_song_list( $descname ) ) )
	        { print STDERR "No files match $descname.\n"; }
	    else
		{ &cat_list( "$descname.mp3", @song_list ); }
	    }
	}
    else
	{
	my @song_list = &generate_song_list( @descs_todo );
	&usage( "No files match specifications." ) if( ! @song_list );
	if( $ARGS{mode} eq "verify" )
	    { &verify_list( @song_list ); }
	elsif( $ARGS{mode} eq "list" )
	    { &cmd_list( @song_list ); }
	elsif( $ARGS{mode} eq "cat" )
	    { &cat_list( $ARGS{output_file}, @song_list ); }
	elsif( $ARGS{mode} eq "browser" )
	    { &cgi_list( @song_list ); }
	else
	    { &continually_play_list( @song_list ); }
	}
    }

#########################################################################
#	Main								#
#########################################################################

if( $ENV{SCRIPT_NAME} )
    { &CGI_arguments(); }
else
    {
    %ARGS = &parse_arguments({
	switches	=> \%ONLY_ONE_DEFAULTS,
	non_switches	=> \@descs_todo
	});
    }

0 if( $cpi_vars::VERBOSITY );
$cpi_vars::VERBOSITY = $ARGS{verbosity};

&spin_some_songs();

exit( $exit_stat );
