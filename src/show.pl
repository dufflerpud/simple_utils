#!/usr/bin/perl -w
#
#indx#	show - Play specified media on local display/speakers
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
#doc#	show - Play specified media on local display/speakers
########################################################################

use strict;

use lib "/usr/local/lib/perl";

use cpi_file qw( echodo read_file write_file fatal );
use cpi_media qw( player media_info );
use cpi_cgi qw( CGIreceive CGIheader );
use cpi_arguments qw( parse_arguments );
use cpi_vars;

# Put constants here

my $TMP = "/tmp/$cpi_vars::PROG.$$";
my $OCT_DIR = "/usr/local/projects/octagon";
my $CURRENT_SCREENS = "$OCT_DIR/state/screens";

our %ONLY_ONE_DEFAULTS =
    (
    "rate"	=>	1.0,	# Rate for movie playback
    "screen"	=>	"",	# Which screen
    "fullscreen"=>	"",	# Use full screen or not
    "fs"	=>	"",	# Specify which full screen
    "yesno"	=>	"",	# Filename to put answer in
    "geometry"	=>	"",	# Where to put image box
    "bleft"	=>	2580,	# Left of box
    "bright"	=>	"",	# Right of box
    "btop"	=>	2100,	# Top of box
    "bbottom"	=>	"",	# Bottom of box
    "bwidth"	=>	"",	# Width of box
    "bheight"	=>	"",	# Height of box
    "urls"	=>	"$OCT_DIR/cfg/urls.pl",
    "macros"	=>	"$OCT_DIR/cfg/urlmacros.pl",
    "title"	=>	"",	# Title
    "at"	=>	0,	# Do not announce the title
    #"ao"	=>	"pulse",# or null	(mpv Audio Output driver)
    "ao"	=>	"",# or null	(mpv Audio Output driver)
    "vo"	=>	"",	# or null	(mpv Video Output driver)
    "loop"	=>	1,	# 0 means loop forever
    "verbosity"	=>	0	# 0=off
    );

my @CLIP_SELECTIONS=("XA_PRIMARY","XA_SECONDARY","XA_CLIPBOARD","c");
my $CVT="/usr/local/bin/nene";
my $MPV="mpv --really-quiet";
my $YOUTUBEDL="youtube-dl";

# Put variables here.

our @problems;
our %ARGS;
our @files;
our $exit_stat = 0;
my %screen;

# Put interesting subroutines here

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
	"Usage:  $cpi_vars::PROG <possible arguments>","",
	"    where <possible arguments> are",
	"	-geometry rxc		Where to put image",
	"	-rate n.n.		Rate for movie playback",
	"	-screen <screen>	Which screen",
	"	-fullscreen 1 or 0	Use full screen or not",
	"	-fs <screen>		Specify which full screen",
	"	-yesno <filename>	Filename to put answer in",
	"	-bleft <n>		Left of box",
	"	-bright <n>		Right of box",
	"	-btop <n>		Top of box",
	"	-bbottom <n>		Bottom of box",
	"	-bheight <n>		Height of image",
	"	-bwidth <n>		Width of image",
	"	-urls <filename>	File containing URLs (perl)",
	"	-macros <filename>	File containing macros (perl)",
	"	-title <title>		Title",
	"	-at <n>			Do not announce the title",
	"	-ao <driver>		mpv Audio Output driver",
	"	-vo <driver>		mpv Video Output driver",
	"	-loop <n>		0 means loop forever",
	"	<filenames to show or display>"
	);
    }

#########################################################################
#	Look for processes matching description and kill them!		#
#	Tries to be nice at first (TERM), but if not ... KILL!		#
#########################################################################
sub kill_matching
    {
    my( $searchfor ) = @_;
    my $sig = "TERM";
    my $count;
    while(1)
	{
	$count = 0;
	open( INF, "ps -efww |" ) || &fatal("Cannot run ps:  $!");
	while( $_ = <INF> )
	    {
	    chomp( $_ );
	    next if( ! /$searchfor/ );
	    my( $user, $pid, $ppid ) =  split(/\s+/);
	    print "kill -$sig ${pid}:  $_\n";
	    kill $sig => ${pid};
	    $count++;
	    }
	close( INF );
	last if( $count == 0 );
	$sig = "KILL";
	print "Checking again in 1 second...\n";
	sleep(1);
	}
    }

#########################################################################
#	Try to kill off anything else running on a screen before	#
#	attaching to it for our purposes.				#
#########################################################################
sub acquire_screen
    {
    my( $thing ) = @_;
    if( $ARGS{screen} )
	{
	if( ! $thing )
	    {
	    print "Releasing screen $ARGS{screen}.\n";
	    unlink( "$CURRENT_SCREENS/$ARGS{screen}" );
	    }
	else
	    {
	    print "Acquiring screen $ARGS{screen} for $thing.\n";
	    &kill_matching( "fs-screen=$screen{MPV} " );
	    &write_file( "$CURRENT_SCREENS/$ARGS{screen}", $thing );
	    }
	}
    }

#########################################################################
#	Execute a command and trap standard out.			#
#########################################################################
sub command_result
    {
    my( $cmd ) = join(" ",@_);
    print "+ $cmd\n" if( $cpi_vars::VERBOSITY );
    open( CR, "$cmd |" ) || &fatal("Cannot run ${cmd}:  $!");
    my $ret = <CR>;
    close( CR );
    chomp( $ret );
    return $ret;
    }

#########################################################################
#	We we asked for full screen, we need parameters to obtain.	#
#########################################################################
sub set_screen_logic
    {
    if( $ARGS{screen} =~ /^[0-9][hml]$/ )
        {}
    elsif( $ARGS{screen} =~ /^m[pv]*(\d+)$/ )
        { $ARGS{screen} = &command_result("screens -MPV=$1 -show=Name"); }
    elsif( $ARGS{screen} =~ /^(X.+)$/ )
        { $ARGS{screen} = &command_result("screens -Port=$1 -show=Name"); }
    else
	{ push(@problems,"Illegal screen definition:  $ARGS{screen}"); }

    &usage( @problems ) if( @problems );

    open( INF, "screens -Name=$ARGS{screen} |" )
	|| &fatal("Cannot run screens -Name=$ARGS{screen}:  $!");
    chomp($_=<INF>);	my @fieldnames	= split(/\s+/);
    chomp($_=<INF>);	my @values	= split(/\s+/);
    close( INF );
    #print "fn:  ", join(' : ',@fieldnames), "\n";
    #print "values  ", join(' : ',@values), "\n";

    # Name Host Port MPV Dimensions Location Geometry URL
    my $last_field = pop(@fieldnames);
    grep( $screen{$_}=shift(@values), @fieldnames );
    $screen{$last_field} = join(" ",@values);
    #print join("\n\t","Screen",map{"$_:\t$screen{$_}"} sort keys %screen), "\n";

    $screen{mpvarg} = " -fs-screen=$screen{MPV}";
    $screen{geometry} = " -geometry $screen{Geometry}";
    $screen{display} =
	( $ARGS{fullscreen}
	? " -geometry $screen{Geometry} -extent $screen{Dimensions}"
	: " -geometry $screen{Location}" );
    }

#########################################################################
#	Set all clip buffers to what we need.				#
#########################################################################
sub setclip()
    {
    my( $clip ) = @_;
    foreach my $clipbuf ( @CLIP_SELECTIONS )
	{
	open( SC, "| xclip -selection $clipbuf" )
	    || &fatal("Cannot run xclip:  $!");
	print SC $clip ;
	close( SC );
    	}
    }

#########################################################################
#########################################################################
sub display_cmd
    {
    my( $filename ) = @_;
    #print "display=", $screen{display} || "UNDEF", "\n";
    my $modifier = "";
    if( $ARGS{geometry} )
	{ $modifier = " -geometry $ARGS{geometry}"; }
    elsif( $ARGS{screen} && $ARGS{fullscreen} )
	{ $modifier = $screen{display}; }
    else
	{
	my $mediap = &media_info( $filename );
	$modifier = " -geometry ";
	$modifier .= "$mediap->{width}x$mediap->{height}"
	    if( $mediap->{width} && $mediap->{height} );
	$modifier .=
	    ( $screen{Location}
	    ? $screen{Location}
	    : "+$ARGS{bleft}+$ARGS{btop}" );
	$modifier .= " -resize $mediap->{width}x$mediap->{height}"
	    if( $mediap->{width} && $mediap->{height} );
	}
    &echodo( "display$modifier '$filename'");
    }

#########################################################################
#	Figure out which utility to best display a file based on	#
#	extension and then display it.					#
#########################################################################
my %URLS;
sub display_one()
    {
    my( $unmapped_filename ) = @_;
    &acquire_screen( $unmapped_filename );
    my $filename = $unmapped_filename;

    if( $filename =~ /^@(.*)/ )
	{
	my $macroname = $1;
	if( ! %URLS )
	    {
	    eval( &read_file($ARGS{"-macros"}) );
	    eval( "%URLS=".&read_file($ARGS{"-urls"}).";" );
	    foreach my $urlkey ( keys %URLS )
		{
		$URLS{$2} = $URLS{$urlkey}
		    if( $urlkey =~ /(.*):\s+(.*?)$/ );
		}
	    }
	if( ! $macroname )
	    { $filename = $URLS{$screen{URL}}; }
	else
	    { $filename = $URLS{$macroname}; }
	}

    if( $ARGS{at} )
	{
	my @text;
	push( @text, "Displaying" );
	if( $ARGS{at} ne "1" )
	    { push( @text, $ARGS{at} ); }
	elsif( $ARGS{title} )
	    { push( @text, $ARGS{title} ); }
	elsif( $unmapped_filename =~ /^@(.*)$/ )
	    { push( @text, $1 ); }
	elsif( $unmapped_filename =~ /([^\/]+)\.[a-z]+$/ )
	    { push( @text, $1 ); }
	else
	    { push( @text, $unmapped_filename ); }
	push( @text, " on panel $1 ", {h=>"top",m=>"mid-level",l=>"bottom"}->{$2}, " screen" )
	    if( $ARGS{screen} =~ /^(\d+)([hml])$/ );
	&echodo("announce -start '".join(" ",@text,".")."'");
	}

    my %args;
    foreach my $fld ( keys %ARGS )
        {
	if( $fld =~ /^b(.*)/ )
	    { $args{$1} = $ARGS{$fld}; }
	else
	    { $args{$fld} = $ARGS{$fld}; }
	}
    &player( \%args, $filename );
    &acquire_screen();
    }

#########################################################################
#	Do all the files.						#
#########################################################################
sub process_files
    {
    foreach my $filename ( @_ )
	{
	if( $filename =~ /^@(.*)/ )
	    {
	    if( ! %URLS )
		{
		eval( "%URLS=".&read_file($ARGS{"-urls"}).";" );
		foreach my $urlkey ( keys %URLS )
		    {
		    $URLS{$2} = $URLS{$urlkey}
		        if( $urlkey =~ /(.*):\s+(.*?)$/ );
		    }
		}
	    }
	&display_one( $filename );
	if( $ARGS{yesno} )
	    {
	    my $lsoutput = `ls -ld "$filename"`;
	    chomp( $lsoutput );
	    while( 1 )
		{
		print "$lsoutput?  ";
		return if( !defined($_ = <STDIN>) );
		chomp( $_ );
		if( /^n/i )
		    { last; }
		elsif( /^y/i )
		    {
		    open( OUT, ">> $ARGS{yesno}" )
			|| &fatal("Cannot append to $ARGS{yesno}:  $!");
		    print OUT $filename, "\n";
		    close( OUT );
		    last;
		    }
		else
		    { print "You must answer 'y' or 'n'.\n"; }
		}
	    }
	}
    }

#########################################################################
#	Main								#
#########################################################################

if( $ENV{SCRIPT_NAME} )
    { &CGI_arguments(); }
else
    { &parse_arguments(); }

$ARGS{screen}=$ARGS{fullscreen}=$ARGS{fs} if( $ARGS{fs} );
$cpi_vars::VERBOSITY = $ARGS{verbosity};

#print join("\n\t","Args:",map{"$_:\t$ARGS{$_}"} sort keys %ARGS), "\n";

&set_screen_logic() if( $ARGS{screen} );

&process_files( @files );
system("rm -rf $TMP.*");

exit($exit_stat);
